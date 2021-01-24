export function getValidUrl(inputUrl: string) {
  if (inputUrl.startsWith('http://') || inputUrl.startsWith('https://')) {
    return inputUrl;
  }

  // Add missing protocol specifier if needed
  return `https://${inputUrl}`;
}
