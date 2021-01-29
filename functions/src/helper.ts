export function getValidUrl(inputUrl: string) {
  if (inputUrl.startsWith('http://') || inputUrl.startsWith('https://')) {
    return inputUrl;
  }

  // Add missing protocol specifier if needed
  return `https://${inputUrl}`;
}

export function separatePageTitle(pageTitle: string) {
  const split = pageTitle.split('-');
  if (split.length < 2) {
    return {
      comicTitle: null,
      pageTitle: pageTitle,
    };
  }

  const remaining = split.slice(1);

  return {
    comicTitle: split[0].trim(),
    pageTitle: remaining.join('-').trim(),
  };
}

export function constructPageUrl(comicDocName: string, pageDocName: string) {
  const pageSubUrl = pageDocName.replace(/ /g, '/');
  return `https://${comicDocName}/${pageSubUrl}`;
}
