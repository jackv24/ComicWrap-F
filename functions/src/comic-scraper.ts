import axios from 'axios';
import * as cheerio from 'cheerio';

export async function scrapeComicPages(pageUrl: string) {
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
  const archiveLinks = $('.archive > a').toArray().map((element, index) => {
    return $(element).attr('href');
  });

  if (archiveLinks.length > 0) return archiveLinks[0];

  return null;
}
