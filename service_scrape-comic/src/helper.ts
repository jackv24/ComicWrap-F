export function constructPageUrl(comicDocName: string, pageDocName: string) {
    const pageSubUrl = pageDocName.replace(/ /g, '/');
    return `https://${comicDocName}/${pageSubUrl}`;
  }