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
