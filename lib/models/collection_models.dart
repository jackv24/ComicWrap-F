class DocumentsListModel {
  late int sum;
  late List<dynamic> documents;

  DocumentsListModel({required this.sum, required this.documents});

  DocumentsListModel.fromJson(Map<String, dynamic> json) {
    sum = json['sum'];
    documents = json['documents'];
  }

  Map<String, dynamic> toJson() {
    final json = new Map<String, dynamic>();
    json['sum'] = this.sum;
    json['documents'] = this.documents;
    return json;
  }
}

class ComicDocumentModel {
  late String name;
  late String? coverImageUrl;
  late String? scrapeUrl;
  late String? lastReadDate;

  ComicDocumentModel(
      {required this.name,
      this.coverImageUrl,
      this.scrapeUrl,
      this.lastReadDate});

  ComicDocumentModel.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    coverImageUrl = json['coverImageUrl'];
    scrapeUrl = json['scrapeUrl'];
    lastReadDate = json['lastReadDate'];
  }

  Map<String, dynamic> toJson() {
    final json = new Map<String, dynamic>();
    json['name'] = name;
    if (coverImageUrl != null) json['coverImageUrl'] = coverImageUrl;
    if (scrapeUrl != null) json['scrapeUrl'] = scrapeUrl;
    if (lastReadDate != null) json['lastReadDate'] = lastReadDate;
    return json;
  }
}
