import * as url from 'url';

function getValidUrl(inputUrl: string) {
  if (inputUrl.startsWith('http://') || inputUrl.startsWith('https://')) {
    return inputUrl;
  }

  // Add missing protocol specifier if needed
  return `https://${inputUrl}`;
}

async function userAddComic(data: string) {
  if (!data) {
    return 'Required';
  }

  // Automatically fixed up provided url if we can
  const inputUrl = getValidUrl(data);

  const parsedUrl = url.parse(inputUrl);
  const hostName = parsedUrl.hostname;
  if (!hostName) {
    return 'Invalid URL';
  }

  return null;
}

async function main() {
  const data = process.env.APPWRITE_FUNCTION_DATA;
  if (!data) {
    console.log('undefined');
    return;
  }

  const response = await userAddComic(data);
  console.log(response);
}

main();
