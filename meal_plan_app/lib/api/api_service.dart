import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/delivery_model.dart';
import '../models/meal_model.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';

class ApiService {

  // Use 10.0.2.2 for Android Emulator. Use localhost for iOS Sim/web.
  final String _baseUrl = 'http://10.0.2.2:3010/api';
  // final String _baseUrl = 'http://localhost:3010/api';
  // final String _baseUrl = 'http://192.168.1.1:3010/api';

  final UserProvider userProvider;
  ApiService(this.userProvider);

  // NOTE: Replace this with the actual user ID from your MongoDB database!
  // final String _userId = '6884a195620c4e87b562749e';
  // String get _userId => userProvider.userId ?? '';

  Future<List<User>> fetchUsers() async {
  final uri = Uri.parse('$_baseUrl/users');
  final response = await http.get(uri);
  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    return data.map((d) => User.fromJson(d)).toList();
  } else {
    throw Exception('Failed to fetch users');
  }
}

  // Fetches deliveries for a specific user and date
  Future<List<Delivery>> getDeliveries(DateTime date, String userId) async {
    final uri = Uri.parse(
      '$_baseUrl/deliveries?date=${DateFormat('yyyy-MM-dd').format(date)}&userId=$userId',
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        // final List<dynamic> data = json.decode(response.body);
        // return data.map((d) => Delivery.fromJson(d)).toList();
        final body = response.body;
        if (body.isEmpty || body == 'null') return [];
        final List<dynamic> data = json.decode(body) ?? [];
        return data.map((d) => Delivery.fromJson(d)).toList();
      } else {
        throw Exception('Failed to load deliveries: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch deliveries: $e');
    }
  }

  // Fetches details for the logged-in user 
  Future<User> getUserDetails(String userId) async {
    final uri = Uri.parse('$_baseUrl/users/$userId');
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      // return User.fromJson(json.decode(response.body));
      final body = response.body;
      if (body.isEmpty || body == 'null') {
        throw Exception('User not found');
      }
      return User.fromJson(json.decode(body));
    } else {
      throw Exception('Failed to load user details');
    }
  }

  // Fetches the available time slots from the server config
  Future<List<String>> getTimeSlots() async {
    final uri = Uri.parse('$_baseUrl/config/timeslots');
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return List<String>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load time slots');
    }
  }

  // Updates a delivery slot's core details
  Future<void> updateDeliverySlot(
    String deliveryId, {
    String? timeSlot,
    String? address,
    bool? isPickup,
  }) async {
    final uri = Uri.parse('$_baseUrl/deliveries/$deliveryId/update');
    final body = {
      if (timeSlot != null) 'timeSlot': timeSlot,
      if (address != null) 'address': address,
      if (isPickup != null) 'deliveryType': isPickup ? 'pickup' : 'delivery',
    };

    final response = await http.put(
      uri,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: json.encode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update delivery slot');
    }
  }

  // Marks a specific item in a delivery as 'skipped'
  Future<void> skipItem(String deliveryId, String itemId) async {
    final uri = Uri.parse(
      '$_baseUrl/deliveries/$deliveryId/items/$itemId/skip',
    );
    final response = await http.put(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to skip item');
    }
  }

  // Reschedules a delivery slot to a new date and time
  Future<void> rescheduleDeliverySlot(String deliveryId, DateTime newDate, String newTimeSlot) async {
    final uri = Uri.parse('$_baseUrl/deliveries/$deliveryId/reschedule');
    final response = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'newDate': newDate.toIso8601String()}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to reschedule delivery');
    }
    // Update time slot if needed
    final updateUri = Uri.parse('$_baseUrl/deliveries/$deliveryId/update');
    final updateResponse = await http.put(
      updateUri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'timeSlot': newTimeSlot}),
    );
    if (updateResponse.statusCode != 200) {
      throw Exception('Failed to update time slot');
    }
  }

  // Swaps a meal in the delivery
  Future<void> swapMeal(String deliveryId, String itemId, String newMealId) async {
    final uri = Uri.parse('$_baseUrl/deliveries/$deliveryId/items/$itemId/swap');
    final response = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'newMealId': newMealId}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to swap meal');
    }
  }

  // Fetches available meals from the server
  Future<List<Meal>> getMeals() async {
    final uri = Uri.parse('$_baseUrl/meals');
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((d) => Meal.fromJson(d)).toList();
    } else {
      throw Exception('Failed to fetch meals');
    }
  }

  // Moves a meal to a new date
  Future<void> moveMeal(String deliveryId, DateTime newDate) async {
    final uri = Uri.parse('$_baseUrl/deliveries/$deliveryId/reschedule');
    final response = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'newDate': newDate.toUtc().toIso8601String()}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to move meal');
    }
  }

  // You would add other methods like move here...
}
