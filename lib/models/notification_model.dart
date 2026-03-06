import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  gigAccepted,
  rentalRequested,
  rentalApproved,
  completed,
  ratingReceived,
  reportUpdate,
  adminAnnouncement,
}

class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String body;
  final String? targetId;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.targetId,
    this.isRead = false,
    required this.createdAt,
  });

  // ── Firestore serialization ──────────────────────────────────────────────

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      type: data['type'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      targetId: data['targetId'],
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      'title': title,
      'body': body,
      'targetId': targetId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      type: type,
      title: title,
      body: body,
      targetId: targetId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}
