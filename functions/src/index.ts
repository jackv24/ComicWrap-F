/* eslint-disable indent */
/* eslint-disable require-jsdoc */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as url from "url";
import * as scraper from "./comic-scraper";

admin.initializeApp();
const db = admin.firestore();

// Kicks off scraping comic by writing a skeleton doc
export const startComicScrape = functions.https
  .onCall(async (data, context) => {
    const parsedUrl = url.parse(data);
    // TODO: Error if parsedUrl falsey

    const hostName = parsedUrl.hostname;
    // TODO: Error if hostname falsey

    const existingComicDoc = await db.doc("comics/" + hostName).get();

    // TODO: Check valid
    // Don't do anything if document exists, just return the name
    if (existingComicDoc.exists) return hostName;

    // Create basic document so it exists for client to subscribe to,
    // triggered event onCreate should handle filling out data
    await db.doc("comics/" + hostName).create({
      name: hostName,
      // TODO: Make sure this is a valid URL
      scrapeUrl: data,
    });

    // Just return the name of the new document while import is being triggered
    return hostName;
  });

// Takes over importing the comic in the background after startComicScrape
export const continueComicImport = functions.firestore
  .document("comics/{comicId}")
  .onCreate(async (snapshot, context) => {
    const scrapeUrl = snapshot.get("scrapeUrl");
    const comicPages = await scraper.scrapeComicPages(scrapeUrl);

    // TODO: Error
    if (comicPages == null) return;

    const collection = snapshot.ref.collection("pages");

    for (let i = 0; i < comicPages.length; i++) {
      const page = comicPages[i];
      if (!page.link) continue;

      // Document name just in index for sorting purposes, we can insert pages
      // between later without touching other documents by doing 1..1.5..2, etc
      const docName = i.toString();

      // Write document
      await collection.doc(docName).create({
        text: page.text,
        link: page.link,
      });
    }

    return;
  });
