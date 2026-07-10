class Item {
  final String id;
  final String type;
  final String title;
  final double? amount;
  final String? dueDate;
  final String? billerName;
  final String status;
  final double confidence;
  final String? links;
  final String? rawSnippet;

  Item({
    required this.id,
    required this.type,
    required this.title,
    this.amount,
    this.dueDate,
    this.billerName,
    required this.status,
    required this.confidence,
    this.links,
    this.rawSnippet,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json["id"],
      type: json["type"] ?? "",
      title: json["title"] ?? "",
      amount: (json["amount"] as num?)?.toDouble(),
      dueDate: json["due_date"],
      billerName: json["biller_name"],
      status: json["status"] ?? "",
      confidence: (json["confidence"] as num?)?.toDouble() ?? 0,
      links: json["links"],
      rawSnippet: json["raw_snippet"],
    );
  }
}