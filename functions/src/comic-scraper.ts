import axios from 'axios';
import * as cheerio from 'cheerio';
import * as url from 'url';

type CheerioRoot = ReturnType<typeof cheerio.load>;

type ReturnPage = {
  text: string,
  docName: string
}

export async function scrapeComicPages(pageUrl: string) {
  const pages = await tryScrapeComicPages(pageUrl);
  if (!pages) return null;

  return pages.map((value, index) => {
    if (!value.link) return null;

    const parsedUrl = url.parse(value.link);
    const pageNameSource = parsedUrl.pathname ?? value.link;

    // Use page link as document name, since index could change
    // Replace invalid characters with rarely used alternatives
    const docName = pageNameSource.replace('/', ' ');

    return {
      text: value.text,
      docName: docName,
    };
  }).filter((val): val is ReturnPage => !!val);
}

async function tryScrapeComicPages(pageUrl: string) {
  // Attempt the quick method first
  const pagesFromSimple = await scrapeComicPagesSimple(pageUrl);
  if (pagesFromSimple && pagesFromSimple.length > 0) {
    return pagesFromSimple;
  }

  // Quick method failed, try crawling (slow & expensive)
  const pagesFromCrawling = await scrapeViaCrawling(pageUrl);
  if (pagesFromCrawling && pagesFromCrawling.length > 0) {
    return pagesFromCrawling;
  }

  // Everything failed
  return null;
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

async function scrapeViaCrawling(startPageUrl: string) {
  // Start from the first page so we can just go until we reach the end
  const startHtml = (await axios.get(startPageUrl)).data;
  const start$ = cheerio.load(startHtml);
  const firstNavs = getLinksFromElements(start$, '[class*="first"]');

  // Cancel if we couldn't find a link to the first page
  if (!firstNavs || firstNavs.length == 0) return null;

  // Add first page to array and keep looping until we run out of next links
  let currentPage = await scrapePage(firstNavs[0]);
  const pages = [currentPage];
  while (currentPage.next) {
    currentPage = await scrapePage(currentPage.next);
    pages.push(currentPage);
  }

  // Some data is only necessary while crawling
  return pages.map((value, index) => {
    return {
      text: value.title ?? value.current,
      link: value.current,
    };
  });
}

async function scrapePage(pageUrl: string) {
  console.log('Scraping page: ' + pageUrl);

  const html = (await axios.get(pageUrl)).data;
  const $ = cheerio.load(html);

  const prevNavs = getLinksFromElements($, '[class*="prev"]');
  const nextNavs = getLinksFromElements($, '[class*="next"]');
  const titles = $('title').toArray().map((element, index) => {
    return $(element).text();
  });

  return {
    title: titles.length > 0 ? titles[0] : null,
    previous: prevNavs.length > 0 ? prevNavs[0] : null,
    next: nextNavs.length > 0 ? nextNavs[0] : null,
    current: pageUrl,
  };
}

function getLinksFromElements($: CheerioRoot, selector: string) {
  return $(selector).toArray().map((element, index) => {
    return $(element).attr('href');
  })
      .filter((item) => item) as string[];
}
