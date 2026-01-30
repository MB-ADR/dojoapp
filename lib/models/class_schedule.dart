import 'package:hive/hive.dart';

part 'class_schedule.g.dart';

@HiveType(typeId: 0)
class ClassSchedule extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String disciplina; // "Kick Boxing", "Muay Thai"

  @HiveField(2)
  String horario; // "17:15"

  @HiveField(3)
  String categoria; // "Inicial", "Juvenil", "Adulto"

  @HiveField(4)
  List<int> diasDeSemana; // [1,3,5] = Lun, Mie, Vie

  @HiveField(5)
  List<String> fechasCanceladas;

  @HiveField(6)
  List<String> studentIds;

  ClassSchedule({
    this.id = '',
    required this.disciplina,
    required this.horario,
    required this.categoria,
    this.diasDeSemana = const [],
    List<String>? fechasCanceladas,
    List<String>? studentIds,
  })  : fechasCanceladas = fechasCanceladas ?? [],
        studentIds = studentIds ?? [];

  // Nombre completo para mostrar
  String get nombre => '$disciplina - $horario - $categoria';

  bool esHoyDiaDeClase() {
    final now = DateTime.now();
    return diasDeSemana.contains(now.weekday);
  }
  
  // Obtener hora de inicio de la clase en formato DateTime
  DateTime? getClassStartTime() {
  try {
    // Parsear horario "17:15" a DateTime de hoy
    final parts = horario.split(':');
    if (parts.length != 2) return null;
    
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  } catch (e) {
    return null;
  }
  }

// Verificar si es momento de tomar asistencia (durante clase + 30 min después)
  bool puedeTomarAsistenciaAhora() {
  if (!esHoyDiaDeClase()) return false;
  
  final startTime = getClassStartTime();
  if (startTime == null) return false;
  
  final now = DateTime.now();
  final endWindow = startTime.add(const Duration(minutes: 90)); // Clase + 30 min después
  
  return now.isAfter(startTime) && now.isBefore(endWindow);
  }
  int calculateTotalClasses(int month, int year, DateTime? studentCreationDate) {
    int count = 0;
    final effectiveCreationDate = studentCreationDate ?? DateTime(1900, 1, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    
    for (int i = 1; i <= daysInMonth; i++) {
      final date = DateTime(year, month, i);
      if (date.isBefore(effectiveCreationDate)) continue;
      
      final dateStr = date.toIso8601String().split('T').first;
      if (fechasCanceladas.contains(dateStr)) continue;
      
      if (diasDeSemana.contains(date.weekday)) {
        count++;
      }
    }
    return count;
  }

  void addCancelledDate(DateTime date) {
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