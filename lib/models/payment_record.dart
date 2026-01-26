import 'package:hive/hive.dart';

part 'payment_record.g.dart';

@HiveType(typeId: 2)
class PaymentRecord extends HiveObject {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final String method; // Ej: 'Cash', 'Transfer', 'Card'

  @HiveField(3)
  final bool isPaid; // True si el pago fue exitoso

  @HiveField(4)
  final String? description;

  PaymentRecord({
    required this.date,
    required this.amount,
    required this.method,
    this.isPaid = true,
    this.description,
  });
}