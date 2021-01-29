import {describe, it, before, after} from 'mocha';
import * as sinon from 'sinon';
import {expect} from 'chai';
import axios from 'axios';
import * as fs from 'fs';
import * as scraper from './comic-scraper';

describe('comic-scraper', () => {
  describe('scrapeComicPages', () => {
    let sandbox: sinon.SinonSandbox;

    before(() => {
      // Use sandbox so we can easily restore all stubs
      sandbox = sinon.createSandbox();
      const get = sandbox.stub(axios, 'get');

      const dirPath = 'test_html';
      const dir = fs.readdirSync(dirPath);
      for (const file of dir) {
        const filePath = `${dirPath}/${file}`;

        // Remove ".html" from end
        const name = file.substring(0, file.length - 5).trim();

        // Replace spaces with /
        const urlPath = name.replace(/ /g, '/');

        // Root url has / on the end, others don't
        const url = urlPath.includes('/') ? `https://${urlPath}` : `https://${urlPath}/`;
        console.log('Stubbing URL: ' + url);

        // Read file when url matching file is requested
        get.withArgs(url).resolves(Promise.resolve({
          data: fs.readFileSync(filePath).toString(),
        }));
      }
    });

    after(() => {
      sandbox.restore();
      sandbox.reset();
    });

    describe('www.goodbyetohalos.com', () => {
      it('finds page list from archive', async () => {
        // Execute
        const pages: scraper.ReturnPage[] = [];
        await scraper.scrapeComicPages('https://www.goodbyetohalos.com/comic/archive', async (page) => {
          pages.push(page);
        });

        // Test: compare arrays with deep equality
        expect(pages).to.eql([{
          text: 'Page 1',
          docName: 'comic page-1',
          wasCrawled: false,
        }]);
      });

      it('finds page list from non-archive', async () => {
        // Execute
        const pages: scraper.ReturnPage[] = [];
        await scraper.scrapeComicPages('https://www.goodbyetohalos.com/', async (page) => {
          pages.push(page);
        });

        // Test: compare arrays with deep equality
        expect(pages).to.eql([{
          text: 'Page 1',
          docName: 'comic page-1',
          wasCrawled: false,
        }]);
      });
    });

    describe('www.peritale.com', () => {
      it('finds page list from archive', async () => {
        // Execute
        const pages: scraper.ReturnPage[] = [];
        await scraper.scrapeComicPages('https://www.peritale.com/comic/archive', async (page) => {
          pages.push(page);
        });

        // Test: compare arrays with deep equality
        expect(pages).to.eql([{
          text: 'Page 1',
          docName: 'comic page-1',
          wasCrawled: false,
        }]);
      });

      it('finds page list from non-archive', async () => {
        // Execute
        const pages: scraper.ReturnPage[] = [];
        await scraper.scrapeComicPages('https://www.peritale.com/', async (page) => {
          pages.push(page);
        });

        // Test: compare arrays with deep equality
        expect(pages).to.eql([{
          text: 'Page 1',
          docName: 'comic page-1',
          wasCrawled: false,
        }]);
      });
    });

    describe('www.misfile.com', () => {
      it('finds pages', async () => {
        // Execute
        const pages: scraper.ReturnPage[] = [];
        await scraper.scrapeComicPages('https://www.misfile.com/', async (page) => {
          pages.push(page);
        });

        // Test: compare arrays with deep equality
        expect(pages).to.eql([
          {
            text: 'Misfile - Hell High - 2019-08-29',
            docName: 'hell-high 2019-08-29',
            wasCrawled: true,
          },
          {
            text: 'Misfile - Hell High - 2019-08-30',
            docName: 'hell-high 2019-08-30',
            wasCrawled: true,
          },
          {
            text: 'Misfile - Hell High - 2019-08-31',
            docName: 'hell-high 2019-08-31',
            wasCrawled: true,
          },
        ]);
      });
    });
  });
});
