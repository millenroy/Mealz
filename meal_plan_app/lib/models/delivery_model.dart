import 'meal_model.dart';

class Delivery {
  final String id;
  final DateTime deliveryDate;
  String timeSlot;
  String address;
  String deliveryType;
  final List<DeliveryItem> items;

  Delivery({
    required this.id,
    required this.deliveryDate,
    required this.timeSlot,
    required this.address,
    required this.deliveryType,
    required this.items,
  });

  factory Delivery.fromJson(Map<String, dynamic> json) {
    return Delivery(
      id: json['_id'],
      deliveryDate: DateTime.parse(json['deliveryDate']),
      timeSlot: json['timeSlot'],
      address: json['address'],
      deliveryType: json['deliveryType'],
      items: List<DeliveryItem>.from(
        json['items'].map((x) => DeliveryItem.fromJson(x)),
      ),
    );
  }
}

class DeliveryItem {
  final String id;
  final Meal meal;
  String status;

  DeliveryItem({required this.id, required this.meal, required this.status});

  factory DeliveryItem.fromJson(Map<String, dynamic> json) {
    return DeliveryItem(
      id: json['_id'],
      meal: Meal.fromJson(json['meal']),
      status: json['status'],
    );
  }
}