class PromoTemplate {
  final String id;
  final String title;
  final String message;
  final bool isActive;
  final DateTime createdAt;

  PromoTemplate({
    required this.id,
    required this.title,
    required this.message,
    required this.isActive,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'isActive': isActive,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory PromoTemplate.fromJson(Map<String, dynamic> json) {
    return PromoTemplate(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
    );
  }

  PromoTemplate copyWith({
    String? id,
    String? title,
    String? message,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return PromoTemplate(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class SendHistory {
  final String phoneNumber;
  final String message;
  final DateTime timestamp;

  SendHistory({
    required this.phoneNumber,
    required this.message,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'phoneNumber': phoneNumber,
      'message': message,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory SendHistory.fromJson(Map<String, dynamic> json) {
    return SendHistory(
      phoneNumber: json['phoneNumber'] as String,
      message: json['message'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
    );
  }
}
