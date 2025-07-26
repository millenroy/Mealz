class Meal {
  final String id;
  final String name;
  final String description;
  final String imageUrl;

  Meal({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json['_id'],
      name: json['name'],
      description: json['description'] ?? 'No description available.',
      imageUrl: json['imageUrl'],
    );
  }
}