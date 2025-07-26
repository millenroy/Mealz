class User {
  final String id;
  final String name;
  final List<Address> addresses;
  final DateTime subscriptionValidUntil;

  User({
    required this.id,
    required this.name,
    required this.addresses,
    required this.subscriptionValidUntil, 
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'],
      name: json['name'],
      addresses: List<Address>.from(
        json['addresses'].map((x) => Address.fromJson(x)),
      ),
      subscriptionValidUntil: json['subscriptionValidUntil'] != null
          ? DateTime.parse(json['subscriptionValidUntil'])
          : DateTime.now().add(const Duration(days: 30)), 
    );
  }
}

class Address {
  final String nickname;
  final String details;

  Address({required this.nickname, required this.details});

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      nickname: json['nickname'],
      details: json['details'],
    );
  }
}