class Model3D {
  final String name;
  final String url;
  final String description;
  final int id;
  String downloadUrl;

  Model3D({
    required this.id,
    required this.name,
    required this.url,
    this.description = "",
    this.downloadUrl = "",
  });

  factory Model3D.fromJson(Map<String, dynamic>? json) {
    return Model3D(
        id: json?['id'],
        name: json?['name'] ?? "",
        url: json?['url'] ?? "",
        description: json?['description'] ?? "");
  }
}
