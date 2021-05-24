import { isURL } from "https://deno.land/x/is_url/mod.ts";

// function getValidUrl(inputUrl: string) {
//   if (inputUrl.startsWith('http://') || inputUrl.startsWith('https://')) {
//     return inputUrl;
//   }

//   // Add missing protocol specifier if needed
//   return `https://${inputUrl}`;
// }

function userAddComic(data: string) {
  if (!data) {
    return 'Required';
  }

  // Automatically fixed up provided url if we can
  const inputUrl = data;//getValidUrl(data);

  const parsedUrl = isURL(inputUrl);
  if (!parsedUrl) {
    return 'Invalid URL';
  }

  return 'Valid URL!';
}

const data = Deno.env.get('APPWRITE_FUNCTION_DATA');
if (!data) {
  console.log('undefined');
} else {
  const response = userAddComic(data);
  console.log(response);
}
