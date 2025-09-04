import 'package:intl/intl.dart';

class Profile {
  final int? id;
  final String name;
  final int age;
  final String gender;
  final String bloodGroup;
  final double? height; // Height in cm
  final double? weight; // Weight in kg
  final String? medication; // Medication details
  final DateTime createdAt;
  final DateTime updatedAt;

  Profile({
    this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.bloodGroup,
    this.height,
    this.weight,
    this.medication,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Calculate BMI if height and weight are available
  double? get bmi {
    if (height == null || weight == null || height! <= 0) return null;
    final heightInMeters = height! / 100;
    return weight! / (heightInMeters * heightInMeters);
  }

  /// Get BMI category based on WHO standards
  String get bmiCategory {
    final bmiValue = bmi;
    if (bmiValue == null) return 'Unknown';

    if (bmiValue < 18.5) return 'Underweight';
    if (bmiValue < 25.0) return 'Normal';
    if (bmiValue < 30.0) return 'Overweight';
    return 'Obese';
  }

  Profile copyWith({
    int? id,
    String? name,
    int? age,
    String? gender,
    String? bloodGroup,
    double? height,
    double? weight,
    String? medication,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      medication: medication ?? this.medication,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'blood_group': bloodGroup,
      'height': height,
      'weight': weight,
      'medication': medication,
      'created_at': DateFormat('yyyy-MM-dd HH:mm:ss').format(createdAt),
      'updated_at': DateFormat('yyyy-MM-dd HH:mm:ss').format(updatedAt),
    };
  }

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      age: map['age']?.toInt() ?? 0,
      gender: map['gender'] ?? '',
      bloodGroup: map['blood_group'] ?? '',
      height: map['height']?.toDouble(),
      weight: map['weight']?.toDouble(),
      medication: map['medication']?.toString(),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  @override
  String toString() {
    return 'Profile{id: $id, name: $name, age: $age, gender: $gender, bloodGroup: $bloodGroup, height: $height, weight: $weight, medication: $medication}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Profile &&
        other.id == id &&
        other.name == name &&
        other.age == age &&
        other.gender == gender &&
        other.bloodGroup == bloodGroup &&
        other.height == height &&
        other.weight == weight &&
        other.medication == medication;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        age.hashCode ^
        gender.hashCode ^
        bloodGroup.hashCode ^
        height.hashCode ^
        weight.hashCode ^
        medication.hashCode;
  }
}
