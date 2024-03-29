import axios from 'axios';
import * as cheerio from 'cheerio';
import * as url from 'url';

import * as helper from './helper';

type CheerioRoot = ReturnType<typeof cheerio.load>;

export type ReturnPage = {
  text: string,
  docName: string,
  wasCrawled: boolean,
  link: string | undefined,
}

type FoundPage = {
  text: string,
  link: string | undefined,
  wasCrawled: boolean,
}

export enum FoundPageResult {
  Success,
  Skipped,
  Cancel
}

export type ComicInfo = {
  id: string,
  scrapeUrl: string,
}

export async function scrapeComicPages(
    comicDoc: ComicInfo,
    lastPageId: string | null,
    onPageFound: (page: ReturnPage) => Promise<FoundPageResult>,
) {
  // Don't re-save previous pages before last page
  let startKeepingPages = lastPageId === null;

  await tryScrapeComicPages(comicDoc, lastPageId, async (foundPage) => {
    // Don't save pages without a link
    if (!foundPage.link) return FoundPageResult.Skipped;

    const parsedUrl = url.parse(foundPage.link);
    const pageNameSource = parsedUrl.pathname ?? foundPage.link;

    // Use page link as document name, since index could change
    // Replace slash characters with spaces
    const docName = pageNameSource.replace(/\//g, ' ').trim();

    if (!startKeepingPages) {
      // We've reached the last saved page, now we can start saving new pages
      if (docName === lastPageId) startKeepingPages = true;

      // Skip this page, we'll start saving from after this point
      return FoundPageResult.Skipped;      
    }

    console.log('Returning page: ' + docName);

    const returnPage = {
      text: foundPage.text,
      docName: docName,
      wasCrawled: foundPage.wasCrawled,
      link: foundPage.link,
    };

    // Save page
    return onPageFound(returnPage);
  });

  return;
}

async function tryScrapeComicPages(
    comicDoc: ComicInfo,
    lastPageId: string | null,
    onPageFound: (page: FoundPage) => Promise<FoundPageResult>
) {
  // Attempt the quick method first
  const pagesFromSimple = await scrapeComicPagesSimple(comicDoc.scrapeUrl);
  if (pagesFromSimple && pagesFromSimple.length > 0) {
    // All pages are found in one go so we'll just loop them
    for (const page of pagesFromSimple) {
      await onPageFound(page);
    }
    return;
  }

  // Quick method failed, try crawling (slow & expensive)
  let startUrl: string;
  if (lastPageId) {
    startUrl = helper.constructPageUrl(comicDoc.id, lastPageId);
  } else {
    startUrl = comicDoc.scrapeUrl;
  }

  const parsedStartUrl = url.parse(startUrl);
  const rootUrl = parsedStartUrl.protocol + '//' + parsedStartUrl.host;
  
  if (lastPageId) {
    await scrapeFromViaCrawling(rootUrl, startUrl, onPageFound);
  } else {
    await scrapeNewViaCrawling(rootUrl, startUrl, onPageFound);
  }

  return;
}

async function scrapeComicPagesSimple(pageUrl: string) {
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
  const select = $('[name="comic"] > option');
  const optionsArray = select.toArray();
  const pages = optionsArray.map((element, index) => {
    const val = $(element);
    return {
      text: val.text(),
      link: val.attr('value'),
      wasCrawled: false,
    };
  });

  return pages;
}

async function getArchivePageUrl(currentPageHtml: string) {
  const $ = cheerio.load(currentPageHtml);

  let archiveSearch = $('.archive > a');
  if (archiveSearch.length == 0) {
    archiveSearch = $('#archive');
  }

  const archiveLinks = archiveSearch.toArray().map((element, index) => {
    return $(element).attr('href');
  });

  if (archiveLinks.length > 0) return archiveLinks[0];

  return null;
}

async function scrapeNewViaCrawling(
  rootUrl: string,
  startPageUrl: string,
  onPageFound: (page: FoundPage) => Promise<FoundPageResult>
) {
  // Start from the first page so we can just go until we reach the end
  const startHtml = (await axios.get(startPageUrl)).data;
  const start$ = cheerio.load(startHtml);
  const firstNav = getLinkFromElements(start$, '[class*="first"], [class*="start"], [rel*="first"], [rel*="start"]');

  // Cancel if we couldn't find a link to the first page
  if (!firstNav) return null;

  await scrapeFromViaCrawling(rootUrl, firstNav, onPageFound);
}

async function scrapeFromViaCrawling(
    rootUrl: string,
    startPageUrl: string,
    onPageFound: (page: FoundPage) => Promise<FoundPageResult>
) {
  // Loop until there is no "next" page
  let currentPage = await scrapePage(rootUrl, startPageUrl);
  while (currentPage) {
    // We only need to keep some of the data
    const foundPage = {
      text: currentPage.title ?? currentPage.current,
      link: currentPage.current,
      wasCrawled: true,
    };

    // Save found page before moving onto next
    const result = await onPageFound(foundPage);

    // Cancel requested
    if (result == FoundPageResult.Cancel) break;

    // Cancel loop, we've reached the last page
    if (!currentPage.next || currentPage.next === currentPage.current) break;

    // Move onto next page
    currentPage = await scrapePage(rootUrl, currentPage.next);
  }

  return;
}

export async function scrapePage(rootUrl: string, pageUrl: string) {
  // If pageUrl is relative, add rootUrl at the start
  if (!pageUrl.startsWith('http') && !pageUrl.startsWith('https')) {
    pageUrl = rootUrl + pageUrl;
  }

  console.log('Scraping page: ' + pageUrl);

  const webPage = await axios.get(pageUrl);
  if (!webPage) console.log('ERROR: Get page failed!');

  const html = webPage.data;
  const $ = cheerio.load(html);

  const prevLink = getLinkFromElements($, '[class*="prev"], [rel*="prev"]');
  const nextLink = getLinkFromElements($, '[class*="next"], [rel*="next"]');
  const titles = $('title').toArray().map((element, index) => {
    return $(element).text();
  });

  return {
    title: titles.length > 0 ? titles[0] : null,
    previous: prevLink,
    next: nextLink,
    current: pageUrl,
  };
}

function getLinkFromElements($: CheerioRoot, selector: string) {
  const items: string[] = [];

  for (const element of $(selector).toArray()) {
    const elementRef = $(element);
    // Only elements with a link are valid
    const link = elementRef.attr('href');
    if (!link) continue;

    // Add to fallback array
    items.push(link);

    // Prefer linking to page, rather than chapter
    const text = elementRef.text() ?? elementRef.attr('title');
    if (!text) continue;
    const textLower = text.toLowerCase();
    if (textLower.includes('page')) return link;
  }

  return items.length > 0 ? items[0] : null;
}

export async function findImageUrlForPage(pageUrl: string) {
  const html = (await axios.get(pageUrl)).data;
  const $ = cheerio.load(html);

  // img with ID or class
  for (const element of $('img[id*="comic"], img[class*="comic"]').toArray()) {
    const src = $(element).attr('src');
    if (src) return src;
  }

  // img as a child (any level) of div with ID or class
  for (const element of $('[id*="comic"] img, [class*="comic"] img').toArray()) {
    const src = $(element).attr('src');
    if (src) return src;
  }

  return null;
}
