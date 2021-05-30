import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as url from 'url';
import * as helper from './helper';
import urlExist = require('url-exist');
import {firestore} from 'firebase-admin';
import {GoogleAuth} from 'google-auth-library';

admin.initializeApp();
const db = admin.firestore();

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
      if ((await urlExist(inputUrl)) == false) {
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
        // Import job will be picked up by reading this field
        shouldImport: true,
      });

      // Return the name of the new document while import is being triggered
      return hostName;
    });

const iapUrl = 'https://comicwrap.uc.r.appspot.com/';
// eslint-disable-next-line max-len
const targetAudience = '259253169335-0hfak0b08mibpkugruu3f9tquakrun2g.apps.googleusercontent.com';
const auth = new GoogleAuth();

// From: https://cloud.google.com/iap/docs/authentication-howto#iap_make_request-nodejs
async function request() {
  console.info(`request IAP ${url} with target audience ${targetAudience}`);
  const client = await auth.getIdTokenClient(targetAudience);
  const res = await client.request({url: iapUrl});
  console.info(res.data);
  return res.data;
}

export const testAppEngine = functions.https.onRequest(
    async (req, resp) => {
      const data = await request();
      resp.status(200).send(`Proxied: ${data}`).end();
    });
