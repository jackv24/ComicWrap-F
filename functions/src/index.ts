/* eslint-disable indent */
/* eslint-disable require-jsdoc */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import axios from "axios";
import * as cheerio from "cheerio";
import * as url from "url";

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
    const comicPages = await scrapeComicPages(scrapeUrl);

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


async function scrapeComicPages(pageUrl: string) {
  const firstPage = await axios.get(pageUrl);

  // Attempt to find page list
  const result = await getPagesFromArchive(firstPage.data);
  if (result.length > 0) return result;

  // Could not find page list in provided URL, try and find an
  // archive page which may have one
  const archivePageUrl = await getArchivePageUrl(firstPage.data);
  if (!archivePageUrl) return null;

  // Found an archive page, try find a page list again
  const archivePage = await axios.get(archivePageUrl);
  const retriedResult = await getPagesFromArchive(archivePage.data);
  return retriedResult;
}

async function getPagesFromArchive(archivePageHtml: string) {
  const $ = cheerio.load(archivePageHtml);
  const select = $("[name='comic'] > option");
  const optionsArray = select.toArray();
  const pages = optionsArray.map((element, index) => {
    const val = $(element);
    return {
      text: val.text(),
      link: val.attr("value"),
    };
  });

  return pages;
}

async function getArchivePageUrl(currentPageHtml: string) {
  const $ = cheerio.load(currentPageHtml);
  const archiveLinks = $(".archive > a").toArray().map((element, index) => {
    return $(element).attr("href");
  });

  if (archiveLinks.length > 0) return archiveLinks[0];

  return null;
}
