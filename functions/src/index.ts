import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as url from 'url';
import * as scraper from './comic-scraper';

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

      const parsedUrl = url.parse(data);
      const hostName = parsedUrl.hostname;
      if (!hostName) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'Invalid Url'
        );
      }

      // Reference to document of comic (existing or yet to be created below)
      const comicDocRef = db.doc('comics/' + hostName);

      // Add comic to calling user's library
      const userDocRef = db.collection('users').doc(context.auth.uid);
      const userDoc = await userDocRef.get();
      const library =
        userDoc.get('library') as FirebaseFirestore.DocumentReference[] ?? [];
      library.push(comicDocRef);
      await userDocRef.set({library: library}, {merge: true});

      // Don't do anything more if document exists, just return the name
      if ((await comicDocRef.get()).exists) return hostName;

      // Create basic document so it exists for client to subscribe to,
      // triggered event onCreate should handle filling out data
      await comicDocRef.create({
        name: hostName,
        scrapeUrl: data,
      });

      // Return the name of the new document while import is being triggered
      return hostName;
    });

// Takes over importing the comic in the background after startComicScrape
export const continueComicImport = functions.firestore
    .document('comics/{comicId}')
    .onCreate(async (snapshot, context) => {
      const scrapeUrl = snapshot.get('scrapeUrl');
      const comicPages = await scraper.scrapeComicPages(scrapeUrl);

      // TODO: Error
      if (comicPages == null) return;

      const collection = snapshot.ref.collection('pages');

      for (let i = 0; i < comicPages.length; i++) {
        const page = comicPages[i];
        if (!page.link) continue;

        // Use page link as document name, since index could change
        // Replace invalid characters with rarely used alternatives
        const docName = page.link.replace('/', ' ');

        // Write document
        await collection.doc(docName).create({
          index: i,
          text: page.text,
        });
      }

      return;
    });
