import 'package:hive/hive.dart';

part 'class_schedule.g.dart';

@HiveType(typeId: 0)
class ClassSchedule extends HiveObject {
  @HiveField(0)
  String id; // <--- Agregado para que DatabaseService funcione

  @HiveField(1)
  String nombre;

  @HiveField(2)
  List<int> diasDeSemana;

  @HiveField(3)
  List<String> fechasCanceladas;

  @HiveField(4)
  List<String> studentIds; // Relación con alumnos

  ClassSchedule({
    this.id = '', // Por defecto vacío, se genera al guardar
    required this.nombre,
    this.diasDeSemana = const [],
    List<String>? fechasCanceladas,
    List<String>? studentIds,
  })  : fechasCanceladas = fechasCanceladas ?? [],
        studentIds = studentIds ?? [];

  // Helpers
  bool esHoyDiaDeClase() {
    final now = DateTime.now();
    // En Dart: Lunes=1 ... Domingo=7.
    // Verificamos si el dia actual está en la lista permitida
    return diasDeSemana.contains(now.weekday);
  }

  // Método auxiliar para contar clases en un mes (simplificado)
  int calculateTotalClasses(int month, int year, DateTime? studentCreationDate) {
    int count = 0;
    final effectiveCreationDate = studentCreationDate ?? DateTime(1900, 1, 1); // Asume una fecha muy antigua si es nula
    // Lógica básica: iterar todos los días del mes y ver si coincide con diasDeSemana
    final daysInMonth = DateTime(year, month + 1, 0).day;
    for (int i = 1; i <= daysInMonth; i++) {
      final date = DateTime(year, month, i);
      if (date.isBefore(effectiveCreationDate)) continue;
      if (diasDeSemana.contains(date.weekday)) {
        count++;
      }
    }
    return count;
  }

  void addCancelledDate(DateTime date) {
    // Guardar solo la parte de la fecha YYYY-MM-DD
    final dateStr = date.toIso8601String().split('T').first;
    if (!fechasCanceladas.contains(dateStr)) {
      fechasCanceladas.add(dateStr);
    }
  }

  void removeCancelledDate(DateTime date) {
    final dateStr = date.toIso8601String().split('T').first;
    fechasCanceladas.remove(dateStr);
  }
}