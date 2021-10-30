import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as url from 'url';
import * as helper from './helper';
import {GoogleAuth} from 'google-auth-library';

admin.initializeApp();
const db = admin.firestore();

const iapUrl = 'https://comicwrap.uc.r.appspot.com/';
// eslint-disable-next-line max-len
const targetAudience = '259253169335-0hfak0b08mibpkugruu3f9tquakrun2g.apps.googleusercontent.com';
const auth = new GoogleAuth();

// From: https://cloud.google.com/iap/docs/authentication-howto#iap_make_request-nodejs
async function appRequest(route: string) {
  let url = iapUrl;

  if (process.env.LOCAL_SERVICE) {
    url = 'http://localhost:8091';
  }

  console.info(`request IAP ${url} with target audience ${targetAudience}`);
  const client = await auth.getIdTokenClient(targetAudience);

  // Remove trailing slash (route will have leading slash)
  if (url.endsWith('/')) {
    url = url.substr(0, url.length - 1);
  }

  // Make sure route has leading slash
  if (!route.startsWith('/')) {
    route = '/' + route;
  }

  const res = await client.request({url: url + route});
  console.info(res.data);
  return res.data;
}

// Kicks off scraping comic by writing a skeleton doc
export const addUserComic = functions.https
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
      const inputUrl = helper.addMissingUrlProtocol(data);

      // Validate url
      if (!helper.isValidUrl(inputUrl)) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'Invalid URL'
        );
      }

      const parsedUrl = new url.URL(inputUrl);
      let hostName = parsedUrl.hostname;

      // Reference to document of comic (existing or yet to be created below)
      let sharedComicRef = db.collection('comics').doc(hostName);

      // If comic doesn't already exist, check alternate hostnames
      if (!(await sharedComicRef.get()).exists) {
        // Check with or without beginning 'www.'
        let altHostName;
        if (hostName.startsWith('www.')) {
          altHostName = hostName.substr(4);
        } else {
          altHostName = 'www.' + hostName;
        }

        // Use alternate hostname if it already exists
        if ((await db.collection('comics').doc(altHostName).get()).exists) {
          sharedComicRef = db.collection('comics').doc(altHostName);
          hostName = altHostName;
        }
      }

      // Add comic to calling user's library
      const userDocRef = db.collection('users').doc(context.auth.uid);
      const userComicRef = userDocRef.collection('comics').doc(hostName);

      const existingUserComicDoc = await userComicRef.get();

      // If user already has comic in library, do nothing
      if (existingUserComicDoc.exists) {
        return hostName;
      }

      if ((await sharedComicRef.get()).exists) {
        // Shared comic already exists, so record "new from" for user doc
        const newestPageQuerySnap = await sharedComicRef
            .collection('pages').orderBy('scrapeTime', 'desc').limit(1).get();
        const newestPageDocs = newestPageQuerySnap.docs;
        const newestPageDoc = newestPageDocs.length > 0 ?
            newestPageDocs[0] : null;

        await userComicRef.create({
          newFromPageId: newestPageDoc?.id,
        });

        // Doc already exists, do nothing more
        return hostName;
      } else {
        // Shared comic doesn't exist yet, so just add an empty user doc
        await userComicRef.create({});
      }

      // Create basic document so it exists for client to subscribe to,
      // triggered event onCreate should handle filling out data
      await sharedComicRef.create({
        scrapeUrl: inputUrl,
      });

      const result = appRequest('/startImport/' + hostName);

      // Return the name of the new document while import is being triggered
      return result;
    });

export const updateExistingComics = functions.pubsub
    .schedule('every 5 hours').onRun(async () => {
      const result = appRequest('/updateAll/');
      console.info(result);
    });

export const deleteUserData = functions.auth.user().onDelete(async (user) => {
  const userDocRef = db.collection('users').doc(user.uid);

  // Delete sub collection data first
  const userComicDocs = (await userDocRef.collection('comics').get()).docs;
  for (const userComicDoc of userComicDocs) {
    await userComicDoc.ref.delete();
  }

  // Delete user doc last
  await userDocRef.delete();
});
