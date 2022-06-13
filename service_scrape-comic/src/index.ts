import * as admin from 'firebase-admin';
import express from 'express';
import * as metadata from 'gcp-metadata';
import {OAuth2Client} from 'google-auth-library';
import * as url from 'url';

import * as scraper from './comic-scraper';
import * as helper from './helper';
import { Response } from 'express-serve-static-core';

if (process.env.LOCAL_SERVICE) {
  process.env.FIREBASE_AUTH_EMULATOR_HOST = 'localhost:9099';
  process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8090';
}

admin.initializeApp({
  credential: admin.credential.applicationDefault()
});

const db = admin.firestore();
const runningImports = new Map<string, Promise<void>>();

async function startComicImport(comicDocName: string) {
  const doc = await db.collection('comics').doc(comicDocName).get();
  if (!doc.exists) return 'doc-does-not-exist';

  const isImporting = doc.get('isImporting');
  if (isImporting) return 'already-importing';

  // In case isImporting is false despite an import promise running
  if (runningImports.has(doc.ref.path)) return 'promise-exists';

  // Create import promise
  const promise = importComic(doc)
    .catch(async (reason) => {
      const e = String(reason);
      console.log(`Error importing ${doc.id}: ${e}`);

      // Write error to database for later inspection
      await doc.ref.update({
        'importError': e
      });
    })
    .finally(async () => {
      // Mark importing as finished
      await doc.ref.update({
        'isImporting': false
      });

      // Remove from running map now that it's finished
      runningImports.delete(doc.ref.path);
    });

  runningImports.set(doc.ref.path, promise);

  return 'success';
}

async function importComic(snapshot: FirebaseFirestore.DocumentSnapshot<FirebaseFirestore.DocumentData>) {
  let scrapeUrl: string = snapshot.get('scrapeUrl');
  const collection = snapshot.ref.collection('pages');

  // Mark comic as importing so we don't run multiple at once
  await snapshot.ref.update({
    'isImporting': true,
    // Clear previous error to avoid confusion
    'importError': ''
  })

  let foundComicName = !!snapshot.get('name');
  let coverImageUrl: string | undefined = snapshot.get('coverImageUrl');

  // Assume if it already has a cover image that it's "good"
  let foundGoodCover = !!coverImageUrl;

  // Assume scrape URL is wrong, it'll be updated by the first scraped page
  let foundScrapeUrl = false;

  let lastPageQuery = await collection.orderBy('scrapeTime', 'desc').limit(1).get();
  let lastPage = lastPageQuery.docs.length > 0 ? lastPageQuery.docs[0] : null;

  let comicInfo: scraper.ComicInfo = {
    id: snapshot.id,
    scrapeUrl: scrapeUrl,
  };

  // Scrape pages, saving as we go
  await scraper.scrapeComicPages(
      comicInfo, lastPage?.id ?? null, async (page) => {
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

        // First scraped page should define the root URL that URLs are constructed from
        // (handles case where provided URL redirects to another root)
        if (!foundScrapeUrl && page.link) {
          console.log('Test page link for scrape URL: ' + page.link);
          const u = url.parse(page.link);
          const protocol = u.protocol;
          const host = u.host;
          const newScrapeUrl = protocol && host ? `${protocol}//${host}` : null;
          if (newScrapeUrl && newScrapeUrl != scrapeUrl) {
            console.log('Found new scrapeUrl: ' + newScrapeUrl);

            foundScrapeUrl = true;
            scrapeUrl = newScrapeUrl;
            comicInfo.scrapeUrl = newScrapeUrl;

            // Save new root URL for comic so in-site navigation works properly
            await snapshot.ref.set(
              {scrapeUrl: newScrapeUrl},
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
            const pageUrl = helper.constructPageUrl(snapshot.id, page.docName);
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
          scrapeTime: admin.firestore.Timestamp.now(),
          text: pageTitle,
        });

        // Canceled comic importing by manually changing database field
        const shouldContinue = (await snapshot.ref.get()).get('isImporting');
        if (!shouldContinue) {
          console.log('Canceled importing at page: ' + page.docName);
          return scraper.FoundPageResult.Cancel;
        }

        return scraper.FoundPageResult.Success;
      });

  // If name wasn't found, load a page and get name from there
  if (!foundComicName) {
    const page = await scraper.scrapePage(scrapeUrl, '');
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

const app = express();
const oAuth2Client = new OAuth2Client();

// Cache externally fetched information for future invocations
let aud: string;

async function audience() {
  if (!aud && (await metadata.isAvailable())) {
    let project_number = await metadata.project('numeric-project-id');
    let project_id = await metadata.project('project-id');

    aud = '/projects/' + project_number + '/apps/' + project_id;
  }

  return aud;
}


async function validateAssertation(assertion: string) {
  if (!assertion) return;

  const aud = await audience();

  const response = await oAuth2Client.getIapPublicKeys();
  const ticket = await oAuth2Client.verifySignedJwtWithCertsAsync(
    assertion,
    response.pubkeys,
    aud,
    ['https://cloud.google.com/iap']
  );

  const payload = ticket.getPayload();
  if (!payload) return;

  return {
    email: payload.email,
    sub: payload.sub
  };
}

async function getEmail(req: any) {
  const assertion = req.header('X-Goog-IAP-JWT-Assertion');
  let email: string | undefined;
  try {
    const info = await validateAssertation(assertion!);
    email = info!.email!;
  } catch (error) {
    console.log(error);
  }

  return email;
}

async function validateAuthenticated(req: any, res: Response<any, Record<string, any>, number>) {
  // Make sure we're properly authenticated
  if (!process.env.LOCAL_SERVICE) {
    const email = await getEmail(req);
    if (!email) {
      res.status(401).send();
      return false;
    }
  }

  return true;
}

app.get('/', async (req, res) => {
  const email = await getEmail(req);
  res.status(200).send(`Hello ${email}!`).end();
});

app.get('/startImport/:comicDocName', async (req, res) => {
  if (!validateAuthenticated(req, res)) return;

  const result = await startComicImport(req.params.comicDocName);
  res.status(200).send(result);
});

app.get('/updateAll/', async (req, res) => {
  if (!validateAuthenticated(req, res)) return;

  const comicsInfo = [];
  const comics = await db.collection('comics').get();

  // Kick off imports for all existing comics
  for (const comic of comics.docs) {
    comicsInfo.push({
      id: comic.id,
      result: await startComicImport(comic.id),
    });
  }

  // Return strcture describing import start results, for inspection
  res.status(200).send(comicsInfo);
});

// Start the server
const PORT = process.env.PORT || 8091;
app.listen(PORT, () => {
  console.log(`App listening on port ${PORT}`);
  console.log('Press Ctrl+C to quit.');
});
