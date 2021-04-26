import * as admin from 'firebase-admin';
import * as scraper from './comic-scraper';

admin.initializeApp({
  credential: admin.credential.applicationDefault()
});

const db = admin.firestore();
const runningImports = new Map<string, Promise<void>>();

// Respond to all comic doc changes
db.collection('comics').onSnapshot((snapshot) => {
  snapshot.docChanges().forEach((value, index, array) => {
    const doc = value.doc;
    const shouldImport = value.doc.get('shouldImport');
    const isImporting = value.doc.get('isImporting');
    
    // Don't do anything if import is not queued, or is already running
    if (!shouldImport || isImporting) return;

    // In case isImporting is false despite an import promise running
    if (runningImports.has(doc.ref.path)) return;

    // Create import promise
    const promise = importComic(doc)
      .catch(async (reason) => {
        // Write error to database for later inspection
        await doc.ref.update({
          'importError': String(reason)
        });
      })
      .finally(async () => {
        // Mark importing as finished
        await doc.ref.update({
          'shouldImport': false,
          'isImporting': false
        });

        // Remove from running map now that it's finished
        runningImports.delete(doc.ref.path);
      });

    runningImports.set(doc.ref.path, promise);
  });
});

async function importComic(snapshot: FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData>) {
  const scrapeUrl = snapshot.get('scrapeUrl');
  const collection = snapshot.ref.collection('pages');

  // Mark comic as importing so we don't run multiple at once
  await snapshot.ref.update({
    'isImporting': true,
    // Clear previous error to avoid confusion
    'importError': ''
  })

  // TODO: Replace index with scrape time?
  let pageCount = 0;

  let foundComicName = false;
  let coverImageUrl: string | null = null;
  let foundGoodCover = false;

  // Scrape pages, saving as we go
  await scraper.scrapeComicPages(
      scrapeUrl, async (page) => {
        let pageTitle = page.text;

        if (page.wasCrawled) {
          // Crawled page titles would contain the comic name also
          const splitTitle = separatePageTitle(pageTitle);
          pageTitle = splitTitle.pageTitle;

          // Set comic name if it hasn't been set already
          if (!foundComicName && splitTitle.comicTitle) {
            foundComicName = true;
            await snapshot.ref.set(
                {name: splitTitle.comicTitle},
                {merge: true},
            );
          }
        }

        // Completely stop searching for cover if we found a "good" one
        if (!foundGoodCover) {
          // Prefer images from pages more likely to contain a cover image
          const lcPageTitle = pageTitle.toLowerCase();
          const couldBeCover = lcPageTitle.includes('cover') ||
              lcPageTitle.includes('title') ||
              lcPageTitle.includes('promo');

          // Try extract cover image from page (not every page)
          if (!coverImageUrl || couldBeCover) {
            const pageUrl = constructPageUrl(snapshot.id, page.docName);
            const imageUrl = await scraper.findImageUrlForPage(pageUrl);
            if (imageUrl) {
              coverImageUrl = imageUrl;

              // Can completely stop searching when we find a good candidate
              if (couldBeCover) foundGoodCover = true;

              console.log('Found cover image: ' + pageUrl);

              // Update image immediately since crawling may take a while
              await snapshot.ref.set(
                  {coverImageUrl: coverImageUrl},
                  {merge: true},
              );
            }
          }
        }

        // Write document
        await collection.doc(page.docName).create({
          index: pageCount,
          text: pageTitle,
        });

        pageCount++;
      });

  // If name wasn't found, load a page and get name from there
  if (!foundComicName) {
    const page = await scraper.scrapePage(scrapeUrl);
    if (page.title) {
      const splitTitle = separatePageTitle(page.title);
      await snapshot.ref.set(
          {name: splitTitle.comicTitle},
          {merge: true},
      );
    }
  }

  return;
}

function constructPageUrl(comicDocName: string, pageDocName: string) {
  const pageSubUrl = pageDocName.replace(/ /g, '/');
  return `https://${comicDocName}/${pageSubUrl}`;
}

function separatePageTitle(pageTitle: string) {
  const split = pageTitle.split('-');
  if (split.length < 2) {
    return {
      comicTitle: null,
      pageTitle: pageTitle,
    };
  }

  const remaining = split.slice(1);

  return {
    comicTitle: split[0].trim(),
    pageTitle: remaining.join('-').trim(),
  };
}
