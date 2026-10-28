class User {
  final int id;
  final String name;
  final String email;
  final int age;
  final String gender;
  final double height;
  final double weight;
  final String activityLevel;
  final String goal;
  final double targetCalories;
  final double targetProtein;
  final double targetCarbs;
  final double targetFat;
  final double? bmi;
  final String? bmiStatus;
  final double? bmr;
  final double? tdee;
  final String? createdAt;
  final String? dietType;
  final String? likes;
  final String? allergies;
  final String? dislikes;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.age = 25,
    this.gender = 'male',
    this.height = 170.0,
    this.weight = 70.0,
    this.activityLevel = 'sedentary',
    this.goal = 'maintenance',
    this.targetCalories = 2000.0,
    this.targetProtein = 120.0,
    this.targetCarbs = 250.0,
    this.targetFat = 60.0,
    this.bmi,
    this.bmiStatus,
    this.bmr,
    this.tdee,
    this.createdAt,
    this.dietType,
    this.likes,
    this.allergies,
    this.dislikes,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      age: json['age'] ?? 25,
      gender: json['gender'] ?? 'male',
      height: (json['height'] ?? 170.0).toDouble(),
      weight: (json['weight'] ?? 70.0).toDouble(),
      activityLevel: json['activity_level'] ?? 'sedentary',
      goal: json['goal'] ?? 'maintenance',
      targetCalories: (json['target_calories'] ?? json['target_protein_g'] ?? 2000.0).toDouble(),
      targetProtein: (json['target_protein'] ?? json['target_protein_g'] ?? 120.0).toDouble(),
      targetCarbs: (json['target_carbs'] ?? json['target_carbs_g'] ?? 250.0).toDouble(),
      targetFat: (json['target_fat'] ?? json['target_fat_g'] ?? 60.0).toDouble(),
      bmi: json['bmi']?.toDouble(),
      bmiStatus: json['bmi_status'],
      bmr: json['bmr']?.toDouble(),
      tdee: json['tdee']?.toDouble(),
      createdAt: json['created_at']?.toString(),
      dietType: json['diet_type'],
      likes: json['likes'],
      allergies: json['allergies'],
      dislikes: json['dislikes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
      'activity_level': activityLevel,
      'goal': goal,
    };
  }
}

class AuthResponse {
  final String accessToken;
  final String tokenType;
  final User user;
  final bool isNewUser;

  AuthResponse({
    required this.accessToken,
    required this.tokenType,
    required this.user,
    this.isNewUser = false,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] ?? '',
      tokenType: json['token_type'] ?? 'bearer',
      user: User.fromJson(json['user'] ?? {}),
      isNewUser: json['is_new_user'] ?? false,
    );
  }
}
