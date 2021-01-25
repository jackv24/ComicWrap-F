import {describe, it, beforeEach, afterEach} from 'mocha';
import * as sinon from 'sinon';
import {expect} from 'chai';
import axios from 'axios';
import * as scraper from './comic-scraper';

describe('comic-scraper', () => {
  describe('scrapeComicPages', () => {
    let sandbox: sinon.SinonSandbox;

    beforeEach(() => {
      // Use sandbox so we can easily restore all stubs
      sandbox = sinon.createSandbox();
    });

    afterEach(() => {
      sandbox.restore();
      sandbox.reset();
    });

    describe('www.goodbyetohalos.com', () => {
      function stubWebsite() {
        const get = sandbox.stub(axios, 'get');

        // Archive page
        get.withArgs('https://www.goodbyetohalos.com/comic/archive').resolves(Promise.resolve({
          data: `
          <select name="comic">
            <option value="comic/page-1">Page 1</option>
          </select>
          `,
        }));

        // Non-archive page
        get.withArgs('https://www.goodbyetohalos.com/').resolves(Promise.resolve({
          data: `
          <nav role="navigation">
            <ul id="navigation" class="slimmenu">
              <li class="link archive">
                <a href="https://www.goodbyetohalos.com/comic/archive" title="Archive"></a>
              </li>
            </ul>
          </nav>
          `,
        }));
      }

      it('finds page list from archive', async () => {
        // Setup
        stubWebsite();

        // Execute
        const pages = await scraper.scrapeComicPages('https://www.goodbyetohalos.com/comic/archive');

        // Test: compare arrays with deep equality
        expect(pages).to.eql([{text: 'Page 1', link: 'comic/page-1'}]);
      });

      it('finds page list from non-archive', async () => {
        // Setup
        stubWebsite();

        // Execute
        const pages = await scraper.scrapeComicPages('https://www.goodbyetohalos.com/');

        // Test: compare arrays with deep equality
        expect(pages).to.eql([{text: 'Page 1', link: 'comic/page-1'}]);
      });
    });

    describe('www.peritale.com', () => {
      function stubWebsite() {
        const get = sandbox.stub(axios, 'get');

        // Archive page
        get.withArgs('https://www.peritale.com/comic/archive').resolves(Promise.resolve({
          data: `
          <select name="comic">
            <option value="comic/page-1">Page 1</option>
          </select>
          `,
        }));

        // Non-archive page
        get.withArgs('https://www.peritale.com/').resolves(Promise.resolve({
          data: `
          <div id="wrapper">
            <div id="menu">
              <a id="archive" href="https://www.peritale.com/comic/archive"></a>
            </div>
          </div>
          `,
        }));
      }

      it('finds page list from archive', async () => {
        // Setup
        stubWebsite();

        // Execute
        const pages = await scraper.scrapeComicPages('https://www.peritale.com/comic/archive');

        // Test: compare arrays with deep equality
        expect(pages).to.eql([{text: 'Page 1', link: 'comic/page-1'}]);
      });

      it('finds page list from non-archive', async () => {
        // Setup
        stubWebsite();

        // Execute
        const pages = await scraper.scrapeComicPages('https://www.peritale.com/');

        // Test: compare arrays with deep equality
        expect(pages).to.eql([{text: 'Page 1', link: 'comic/page-1'}]);
      });
    });
  });
});
