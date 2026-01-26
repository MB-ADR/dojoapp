import 'package:hive/hive.dart';

part 'notification_event.g.dart';

@HiveType(typeId: 3)
class NotificationEvent extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime timestamp;

  @HiveField(2)
  final String type; // Ej: 'PAYMENT_REMINDER', 'CLASS_CANCELLED', 'AWARD_GIVEN'

  @HiveField(3)
  final String messageContent;

  @HiveField(4)
  final bool isDelivered;

  NotificationEvent({
    this.id = '',
    DateTime? timestamp,
    required this.type,
    required this.messageContent,
    this.isDelivered = false,
  }) : timestamp = timestamp ?? DateTime.now();
}