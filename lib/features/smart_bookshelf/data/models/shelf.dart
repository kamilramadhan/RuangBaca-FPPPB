class Shelf {
  const Shelf({
    required this.id,
    required this.name,
    required this.description,
  });

  final String id;
  final String name;
  final String description;

  Map<String, dynamic> toMap() {
    return {'name': name, 'description': description};
  }

  factory Shelf.fromMap(String id, Map<String, Object?> map) {
    return Shelf(
      id: id,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
    );
  }
}
