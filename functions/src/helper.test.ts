/* eslint-disable require-jsdoc */

import {describe, it} from 'mocha';
import {expect} from 'chai';
import * as helper from './helper';

describe('helper', () => {
  describe('getValidUrl', () => {
    it('returns input if https protocol', async () => {
      const output = helper.getValidUrl('https://www.test.com/');
      expect(output).to.eql('https://www.test.com/');
    });

    it('returns input if http protocol', async () => {
      const output = helper.getValidUrl('http://www.test.com/');
      expect(output).to.eql('http://www.test.com/');
    });

    it('returns fixed input if missing protocol', async () => {
      const output = helper.getValidUrl('www.test.com');
      expect(output).to.eql('https://www.test.com');
    });
  });
});
