import * as admin from 'firebase-admin';
import express from 'express';
import * as metadata from 'gcp-metadata';
import {OAuth2Client} from 'google-auth-library';

import * as scraper from './comic-scraper';

// admin.initializeApp({
//   credential: admin.credential.applicationDefault()
// });

// const db = admin.firestore();
// const runningImports = new Map<string, Promise<void>>();

// TODO: Instead, respond directly to authorized endpoint calls
// Respond to all comic doc changes
// db.collection('comics').onSnapshot((snapshot) => {
//   snapshot.docChanges().forEach((value, index, array) => {
//     const doc = value.doc;
//     const shouldImport = value.doc.get('shouldImport');
//     const isImporting = value.doc.get('isImporting');
    
//     // Don't do anything if import is not queued, or is already running
//     if (!shouldImport || isImporting) return;

//     // In case isImporting is false despite an import promise running
//     if (runningImports.has(doc.ref.path)) return;

//     // Create import promise
//     const promise = importComic(doc)
//       .catch(async (reason) => {
//         const e = String(reason);
//         console.log(`Error importing ${doc.id}: ${e}`);

//         // Write error to database for later inspection
//         await doc.ref.update({
//           'importError': e
//         });
//       })
//       .finally(async () => {
//         // Mark importing as finished
//         await doc.ref.update({
//           'shouldImport': false,
//           'isImporting': false
//         });

//         // Remove from running map now that it's finished
//         runningImports.delete(doc.ref.path);
//       });

//     runningImports.set(doc.ref.path, promise);
//   });
// });

// async function importComic(snapshot: FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData>) {
//   const scrapeUrl = snapshot.get('scrapeUrl');
//   const collection = snapshot.ref.collection('pages');

//   // Mark comic as importing so we don't run multiple at once
//   await snapshot.ref.update({
//     'isImporting': true,
//     // Clear previous error to avoid confusion
//     'importError': ''
//   })

//   // TODO: Replace index with scrape time?
//   let pageCount = 0;

//   let foundComicName = false;
//   let coverImageUrl: string | null = null;
//   let foundGoodCover = false;

//   // Scrape pages, saving as we go
//   await scraper.scrapeComicPages(
//       scrapeUrl, async (page) => {
//         let pageTitle = page.text;

//         if (page.wasCrawled) {
//           // Crawled page titles would contain the comic name also
//           const splitTitle = separatePageTitle(pageTitle);
//           pageTitle = splitTitle.pageTitle;

//           // Set comic name if it hasn't been set already
//           if (!foundComicName && splitTitle.comicTitle) {
//             foundComicName = true;
//             await snapshot.ref.set(
//                 {name: splitTitle.comicTitle},
//                 {merge: true},
//             );
//           }
//         }

//         // Completely stop searching for cover if we found a "good" one
//         if (!foundGoodCover) {
//           // Prefer images from pages more likely to contain a cover image
//           const lcPageTitle = pageTitle.toLowerCase();
//           const couldBeCover = lcPageTitle.includes('cover') ||
//               lcPageTitle.includes('title') ||
//               lcPageTitle.includes('promo');

//           // Try extract cover image from page (not every page)
//           if (!coverImageUrl || couldBeCover) {
//             const pageUrl = constructPageUrl(snapshot.id, page.docName);
//             const imageUrl = await scraper.findImageUrlForPage(pageUrl);
//             if (imageUrl) {
//               coverImageUrl = imageUrl;

//               // Can completely stop searching when we find a good candidate
//               if (couldBeCover) foundGoodCover = true;

//               console.log('Found cover image: ' + pageUrl);

//               // Update image immediately since crawling may take a while
//               await snapshot.ref.set(
//                   {coverImageUrl: coverImageUrl},
//                   {merge: true},
//               );
//             }
//           }
//         }

//         // Write document
//         await collection.doc(page.docName).create({
//           index: pageCount,
//           text: pageTitle,
//         });

//         pageCount++;

//         // Canceled comic importing by manually changing database field
//         const shouldContinue = (await snapshot.ref.get()).get('shouldImport');
//         if (!shouldContinue) {
//           console.log('Canceled importing at page: ' + page.docName);
//           return scraper.FoundPageResult.Cancel;
//         }

//         return scraper.FoundPageResult.Success;
//       });

//   // If name wasn't found, load a page and get name from there
//   if (!foundComicName) {
//     const page = await scraper.scrapePage(scrapeUrl);
//     if (page.title) {
//       const splitTitle = separatePageTitle(page.title);
//       await snapshot.ref.set(
//           {name: splitTitle.comicTitle},
//           {merge: true},
//       );
//     }
//   }

//   return;
// }

// function constructPageUrl(comicDocName: string, pageDocName: string) {
//   const pageSubUrl = pageDocName.replace(/ /g, '/');
//   return `https://${comicDocName}/${pageSubUrl}`;
// }

// function separatePageTitle(pageTitle: string) {
//   const split = pageTitle.split('-');
//   if (split.length < 2) {
//     return {
//       comicTitle: null,
//       pageTitle: pageTitle,
//     };
//   }

//   const remaining = split.slice(1);

//   return {
//     comicTitle: split[0].trim(),
//     pageTitle: remaining.join('-').trim(),
//   };
// }

const app = express();
const oAuth2Client = new OAuth2Client();

// Cache externall fetched information for future invocations
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

app.get('/', async (req, res) => {
  console.log('Received GET');

  const assertion = req.header('X-Goog-IAP-JWT-Assertion');
  let email: string = 'None';
  try {
    const info = await validateAssertation(assertion!);
    email = info!.email!;
  } catch (error) {
    console.log(error);
  }

  res.status(200).send(`Hello ${email}!`).end();
});

// Start the server
const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  console.log(`App listening on port ${PORT}`);
  console.log('Press Ctrl+C to quit.');
});
