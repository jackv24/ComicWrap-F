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
        console.log('Stubbing URL path: ' + urlPath);

        // Match possible url variants
        const urls = [
          `https://${urlPath}`,
          `https://${urlPath}/`,
          `http://${urlPath}`,
          `http://${urlPath}/`,
        ];

        // Read file when url matching file is requested
        get.withArgs(sinon.match.in(urls)).resolves(Promise.resolve({
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
          return scraper.FoundPageResult.Success;
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
          return scraper.FoundPageResult.Success;
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
          return scraper.FoundPageResult.Success;
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
          return scraper.FoundPageResult.Success;
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
          return scraper.FoundPageResult.Success;
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

      it('find image url for page', async () => {
        const imageUrl = await scraper.findImageUrlForPage('https://www.misfile.com/');

        expect(imageUrl).to.equal('https://www.misfile.com/comics/1611610701-page341.jpg');
      });
    });

    describe('killsixbilliondemons.com', () => {
      it('finds pages', async () => {
        // Execute
        const pages: scraper.ReturnPage[] = [];
        await scraper.scrapeComicPages('https://killsixbilliondemons.com/', async (page) => {
          pages.push(page);
          return scraper.FoundPageResult.Success;
        });

        // Test: compare arrays with deep equality
        expect(pages).to.eql([
          {
            // eslint-disable-next-line max-len
            text: 'Kill Six Billion Demons » KILL SIX BILLION DEMONS – Chapter 1',
            docName: 'comic kill-six-billion-demons-chapter-1',
            wasCrawled: true,
          },
          {
            text: 'Kill Six Billion Demons » KSBD 1-1',
            docName: 'comic ksbd-chapter-1-1',
            wasCrawled: true,
          },
        ]);
      });

      it('find image url for page', async () => {
        const imageUrl = await scraper.findImageUrlForPage('https://killsixbilliondemons.com/');

        expect(imageUrl).to.equal('https://killsixbilliondemons.com/wp-content/uploads/2021/01/BOI26.jpg');
      });

      describe('croakingbound.com', () => {
        it('finds pages', async () => {
          // Execute
          const pages: scraper.ReturnPage[] = [];
          await scraper.scrapeComicPages('https://croakingbound.com/', async (page) => {
            pages.push(page);
            return scraper.FoundPageResult.Success;
          });
  
          // Test: compare arrays with deep equality
          expect(pages).to.eql([
            {
              // eslint-disable-next-line max-len
              text: 'Kill Six Billion Demons » KILL SIX BILLION DEMONS – Chapter 1',
              docName: 'Hop 01 Page 01 – CROAKINGBOUND',
              wasCrawled: true,
            },
            {
              text: 'Hop 01 Page 02 – CROAKINGBOUND',
              docName: 'comics hop-01-page-02',
              wasCrawled: true,
            },
          ]);
        });
  
        it('find image url for page', async () => {
          const imageUrl = await scraper.findImageUrlForPage('https://croakingbound.com/');
  
          expect(imageUrl).to.equal('https://croakingbound.com/wp-content/uploads/2021/05/web-CBH03PG22.png');
        });
      });
    });
  });
});
