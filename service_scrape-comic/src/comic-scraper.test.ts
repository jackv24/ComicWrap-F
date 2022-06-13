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
        let comicInfo: scraper.ComicInfo = {
          id: 'www.goodbyetohalos.com',
          scrapeUrl: 'https://www.goodbyetohalos.com/comic/archive',
        };
        
        const pages: scraper.ReturnPage[] = [];
        await scraper.scrapeComicPages(comicInfo, null, async (page) => {
          pages.push(page);
          return scraper.FoundPageResult.Success;
        });

        // Test: compare arrays with deep equality
        expect(pages).to.eql([{
          text: 'Page 1',
          docName: 'comic page-1',
          wasCrawled: false,
          link: "comic/page-1",
        }]);
      });

      it('finds page list from non-archive', async () => {
        // Execute
        let comicInfo: scraper.ComicInfo = {
          id: 'www.goodbyetohalos.com',
          scrapeUrl: 'https://www.goodbyetohalos.com/',
        };

        const pages: scraper.ReturnPage[] = [];
        await scraper.scrapeComicPages(comicInfo, null, async (page) => {
          pages.push(page);
          return scraper.FoundPageResult.Success;
        });

        // Test: compare arrays with deep equality
        expect(pages).to.eql([{
          text: 'Page 1',
          docName: 'comic page-1',
          wasCrawled: false,
          link: "comic/page-1",
        }]);
      });
    });

    describe('www.peritale.com', () => {
      it('finds page list from archive', async () => {
        // Execute
        let comicInfo: scraper.ComicInfo = {
          id: 'www.peritale.com',
          scrapeUrl: 'https://www.peritale.com/comic/archive',
        };

        const pages: scraper.ReturnPage[] = [];
        await scraper.scrapeComicPages(comicInfo, null, async (page) => {
          pages.push(page);
          return scraper.FoundPageResult.Success;
        });

        // Test: compare arrays with deep equality
        expect(pages).to.eql([{
          text: 'Page 1',
          docName: 'comic page-1',
          wasCrawled: false,
          link: "/comic/page-1",
        }]);
      });

      it('finds page list from non-archive', async () => {
        // Execute
        let comicInfo: scraper.ComicInfo = {
          id: 'www.peritale.com',
          scrapeUrl: 'https://www.peritale.com/',
        };

        const pages: scraper.ReturnPage[] = [];
        await scraper.scrapeComicPages(comicInfo, null, async (page) => {
          pages.push(page);
          return scraper.FoundPageResult.Success;
        });

        // Test: compare arrays with deep equality
        expect(pages).to.eql([{
          text: 'Page 1',
          docName: 'comic page-1',
          wasCrawled: false,
          link: "/comic/page-1",
        }]);
      });
    });

    describe('www.misfile.com', () => {
      it('finds pages', async () => {
        // Execute
        let comicInfo: scraper.ComicInfo = {
          id: 'www.misfile.com',
          scrapeUrl: 'https://www.misfile.com/',
        };

        const pages: scraper.ReturnPage[] = [];
        await scraper.scrapeComicPages(comicInfo, null, async (page) => {
          pages.push(page);
          return scraper.FoundPageResult.Success;
        });

        // Test: compare arrays with deep equality
        expect(pages).to.eql([
          {
            text: 'Misfile - Hell High - 2019-08-29',
            docName: 'hell-high 2019-08-29',
            wasCrawled: true,
            link: "https://www.misfile.com/hell-high/2019-08-29",
          },
          {
            text: 'Misfile - Hell High - 2019-08-30',
            docName: 'hell-high 2019-08-30',
            wasCrawled: true,
            link: "https://www.misfile.com/hell-high/2019-08-30",
          },
          {
            text: 'Misfile - Hell High - 2019-08-31',
            docName: 'hell-high 2019-08-31',
            wasCrawled: true,
            link: "https://www.misfile.com/hell-high/2019-08-31",
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
        let comicInfo: scraper.ComicInfo = {
          id: 'killsixbilliondemons.com',
          scrapeUrl: 'https://killsixbilliondemons.com/',
        };

        const pages: scraper.ReturnPage[] = [];
        await scraper.scrapeComicPages(comicInfo, null, async (page) => {
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
            link: 'https://killsixbilliondemons.com/comic/kill-six-billion-demons-chapter-1/'
          },
          {
            text: 'Kill Six Billion Demons » KSBD 1-1',
            docName: 'comic ksbd-chapter-1-1',
            wasCrawled: true,
            link: 'https://killsixbilliondemons.com/comic/ksbd-chapter-1-1/'
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
          let comicInfo: scraper.ComicInfo = {
            id: 'croakingbound.com',
            scrapeUrl: 'https://croakingbound.com/',
          };

          const pages: scraper.ReturnPage[] = [];
          await scraper.scrapeComicPages(comicInfo, null, async (page) => {
            pages.push(page);
            return scraper.FoundPageResult.Success;
          });
  
          // Test: compare arrays with deep equality
          expect(pages).to.eql([
            {
              // eslint-disable-next-line max-len
              text: 'Hop 01 Page 01 – CROAKINGBOUND',
              docName: 'comics hop-01-page-01',
              wasCrawled: true,
              link: 'https://croakingbound.com/comics/hop-01-page-01/'
            },
            {
              text: 'Hop 01 Page 02 – CROAKINGBOUND',
              docName: 'comics hop-01-page-02',
              wasCrawled: true,
              link: 'https://croakingbound.com/comics/hop-01-page-02/'
            },
          ]);
        });
  
        it('find image url for page', async () => {
          const imageUrl = await scraper.findImageUrlForPage('https://croakingbound.com/');
  
          expect(imageUrl).to.equal('https://croakingbound.com/wp-content/uploads/2021/05/web-CBH03PG22.png');
        });
      });

      describe('rain.thecomicseries.com', () => {
        it('finds pages', async () => {
          // Execute
          let comicInfo: scraper.ComicInfo = {
            id: 'rain.thecomicseries.com',
            scrapeUrl: 'https://rain.thecomicseries.com/',
          };

          const pages: scraper.ReturnPage[] = [];
          await scraper.scrapeComicPages(comicInfo, null, async (page) => {
            pages.push(page);
            return scraper.FoundPageResult.Success;
          });
  
          // Test: compare arrays with deep equality
          expect(pages).to.eql([
            {
              // eslint-disable-next-line max-len
              text: 'Rain - RAIN',
              docName: 'comics first',
              wasCrawled: true,
              link: 'https://rain.thecomicseries.com/comics/first/'
            },
            {
              text: 'Rain - Prologue 1',
              docName: 'comics 2',
              wasCrawled: true,
              link: 'https://rain.thecomicseries.com/comics/2'
            },
          ]);
        });
  
        it('find image url for page', async () => {
          const imageUrl = await scraper.findImageUrlForPage('https://rain.thecomicseries.com/');
  
          expect(imageUrl).to.equal('https://img.comicfury.com/comics/231/4278a1653827058b5422f1039152477.png');
        });
      });
    });
  });
});
