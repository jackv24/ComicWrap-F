import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as url from 'url';
import * as scraper from './comic-scraper';
import * as helper from './helper';
import urlExists = require('url-exist');
import {firestore} from 'firebase-admin';

admin.initializeApp();
const db = admin.firestore();

// Kicks off scraping comic by writing a skeleton doc
export const startComicScrape = functions.https
    .onCall(async (data, context) => {
      if (!context.auth) {
        throw new functions.https.HttpsError(
            'unauthenticated',
            'Authentication Required'
        );
      }

      if (!data) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'Required'
        );
      }

      // Automatically fixed up provided url if we can
      const inputUrl = helper.getValidUrl(data);

      const parsedUrl = url.parse(inputUrl);
      const hostName = parsedUrl.hostname;
      if (!hostName) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'Invalid URL'
        );
      }

      // Actually ping url and see if it exists
      if ((await urlExists(inputUrl)) == false) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'URL does not exist'
        );
      }

      // Reference to document of comic (existing or yet to be created below)
      const sharedComicRef = db.collection('comics').doc(hostName);

      // Add comic to calling user's library
      const userDocRef = db.collection('users').doc(context.auth.uid);
      const userComicRef = userDocRef.collection('comics').doc(hostName);
      userComicRef.create({
        // For easy access, even though doc names are the same
        sharedDoc: sharedComicRef,
        lastReadTime: firestore.Timestamp.now(),
      });

      // Don't do anything more if document exists, just return the name
      if ((await sharedComicRef.get()).exists) return hostName;

      // Create basic document so it exists for client to subscribe to,
      // triggered event onCreate should handle filling out data
      await sharedComicRef.create({
        name: hostName,
        scrapeUrl: inputUrl,
      });

      // Return the name of the new document while import is being triggered
      return hostName;
    });

// Takes over importing the comic in the background after startComicScrape
export const continueComicImport = functions
    .runWith({
      timeoutSeconds: 540,
    }).firestore
    .document('comics/{comicId}')
    .onCreate(async (snapshot, context) => {
      const scrapeUrl = snapshot.get('scrapeUrl');
      const collection = snapshot.ref.collection('pages');

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
              const splitTitle = helper.separatePageTitle(pageTitle);
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
                const pageUrl =
                    helper.constructPageUrl(snapshot.id, page.docName);
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
          const splitTitle = helper.separatePageTitle(page.title);
          await snapshot.ref.set(
              {name: splitTitle.comicTitle},
              {merge: true},
          );
        }
      }

      return;
    });
