import axiod from "https://deno.land/x/axiod/mod.ts";

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

  try {
    await axiod.get(inputUrl);
    return 'Valid URL!';
  } catch(e) {
    return `Invalid URL: ${e}`;
  }
}

const data = Deno.env.get('APPWRITE_FUNCTION_DATA');
if (!data) {
  console.log('undefined');
} else {
  const response = await userAddComic(data);
  console.log(response);
}
