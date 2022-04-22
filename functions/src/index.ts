import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as url from 'url';
import * as helper from './helper';
import {GoogleAuth} from 'google-auth-library';
import {UserRecord} from 'firebase-admin/lib/auth/user-record';
import {PromisePool} from '@supercharge/promise-pool';

admin.initializeApp();
const db = admin.firestore();

const iapUrl = 'https://comicwrap.uc.r.appspot.com/';
// eslint-disable-next-line max-len
const targetAudience = '259253169335-0hfak0b08mibpkugruu3f9tquakrun2g.apps.googleusercontent.com';
const googleAuth = new GoogleAuth();

// From: https://cloud.google.com/iap/docs/authentication-howto#iap_make_request-nodejs
async function appRequest(route: string) {
  let url = iapUrl;

  if (process.env.LOCAL_SERVICE) {
    url = 'http://localhost:8091';
  }

  functions.logger.debug(
      'request IAP',
      url,
      'with target audience',
      targetAudience
  );

  const client = await googleAuth.getIdTokenClient(targetAudience);

  // Remove trailing slash (route will have leading slash)
  if (url.endsWith('/')) {
    url = url.substring(0, url.length - 1);
  }

  // Make sure route has leading slash
  if (!route.startsWith('/')) {
    route = '/' + route;
  }

  const res = await client.request({url: url + route});
  functions.logger.debug(res.data);
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

        if (newestPageDoc != null) {
          await userComicRef.create({
            newFromPageId: newestPageDoc.id,
          });
        } else {
          // Comic exists but has no pages
          await userComicRef.create({});
        }

        // Doc already exists, do nothing more
        return hostName;
      } else {
        // Shared comic doesn't exist yet, so just add an empty user doc
        await userComicRef.create({});
      }

      // Create basic document so it exists for client to subscribe to,
      // triggered event onCreate should handle filling out data
      await sharedComicRef.create({
        // Only save the root URL for later reconstruction from page doc names
        scrapeUrl: `${parsedUrl.protocol}//${parsedUrl.hostname}/`,
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

type DocRef = admin.firestore.DocumentReference<admin.firestore.DocumentData>;

type DudComic = {
  ref: DocRef,
  isUnused: boolean,
}

// Delete comics that have no pages and are not in any user's library
export const deleteUnusedDudImports = functions.pubsub
    .schedule('every monday 05:00').onRun(async () => {
      const dudComicRefs: DudComic[] = [];

      // Iterate over all comics
      const comicDocs = (await db.collection('comics').get()).docs;
      for (const comicDoc of comicDocs) {
        const pages = (await comicDoc.ref.collection('pages').get()).docs;

        // Do nothing if comic has pages
        if (pages && pages.length > 0) continue;

        // Add to array for deletion later
        // (so we don't have to iterate over all users exponentially)
        dudComicRefs.push({
          ref: comicDoc.ref,
          isUnused: true,
        });
      }

      // Iterate over all users
      const userDocs = (await db.collection('users').get()).docs;
      for (const userDoc of userDocs) {
        const userComicDocs =
        (await userDoc.ref.collection('comics').get()).docs;

        // If comic is in user's library, mark in dud array
        for (const userComicDoc of userComicDocs) {
          dudComicRefs.forEach((dudComic, index, array) => {
            if (dudComic.ref.id === userComicDoc.id) {
              dudComic.isUnused = false;
              array[index] = dudComic;
            }
          });
        }
      }

      // Delete all dud comics that aren't in any user library
      for (const dudComic of dudComicRefs) {
        if (dudComic.isUnused) {
          functions.logger.log(
              'Deleting dud comic:',
              dudComic.ref.id,
              '(not in any user\'s library)'
          );
          await dudComic.ref.delete();
        }
      }
    });

export const createUserData = functions.auth.user().onCreate(async (user) => {
  const userDocRef = db.collection('users').doc(user.uid);
  const userDoc = await userDocRef.get();
  if (userDoc.exists) {
    return;
  }

  // Create some dummy data so user doc actually exists for querying
  // (can replace this with actual data later if need be)
  await userDocRef.create({
    dummyData: true,
  });
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

const auth = admin.auth();

// From: https://github.com/firebase/functions-samples/blob/main/delete-unused-accounts-cron/functions/index.js
export const deleteInactiveUsers = functions.pubsub
    .schedule('every monday 03:00').onRun(async () => {
      // Fetch all user details.
      const inactiveUsers = await getInactiveUsers([], undefined);

      // Use a pool so that we delete maximum 3 users in parallel.
      await PromisePool
          .withConcurrency(3)
          .for(inactiveUsers)
          .process(async (user, _index, _pool) => {
            await deleteInactiveUser(user);
          });

      functions.logger.log('User cleanup finished');
    });

async function getInactiveUsers(
    users: UserRecord[],
    nextPageToken: string | undefined
): Promise<UserRecord[]> {
  // Fetch 1000 users at a time (max allowed by Firebase Auth)
  const result = await auth.listUsers(1000, nextPageToken);

  // Find users that have not signed in in the last 90 days.
  const inactiveUsers = result.users.filter((user) => {
    const lastActiveTimeString = user.metadata.lastRefreshTime ||
          user.metadata.lastSignInTime;
    const lastActiveTime = Date.parse(lastActiveTimeString);
    return lastActiveTime < (Date.now() - 90 * 24 * 60 * 60 * 1000);
  });

  // Concat with list of previously found inactive users
  users = users.concat(inactiveUsers);

  // If there are more users to fetch we fetch them.
  if (result.pageToken) {
    return getInactiveUsers(users, result.pageToken);
  }

  return users;
}

async function deleteInactiveUser(userToDelete: UserRecord) {
  // Delete the inactive user.
  try {
    await auth.deleteUser(userToDelete.uid);
    functions.logger.log(
        'Deleted user account',
        userToDelete.uid,
        'because of inactivity'
    );
  } catch (error) {
    functions.logger.error(
        'Deletion of inactive user account',
        userToDelete.uid,
        'failed:',
        error
    );
  }
}
