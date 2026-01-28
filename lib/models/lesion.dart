import 'package:hive/hive.dart';

part 'lesion.g.dart';

@HiveType(typeId: 4)
class Lesion extends HiveObject {
  @HiveField(0)
  String titulo;

  @HiveField(1)
  DateTime fecha;

  @HiveField(2)
  bool altaMedica;

  Lesion({
    required this.titulo,
    required this.fecha,
    this.altaMedica = false,
  });
}