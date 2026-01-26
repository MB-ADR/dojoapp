import 'package:hive/hive.dart';
import 'payment_record.dart';
import 'notification_event.dart';

part 'student.g.dart';

@HiveType(typeId: 1)
class Student extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String nombre;

  @HiveField(2)
  String? photoPath;

  @HiveField(3)
  String dni; // CHANGED: Non-nullable String

  @HiveField(4)
  DateTime? fechaNacimiento; // RENAMED from birthDate

  @HiveField(5)
  double? weightKg;

  @HiveField(6)
  int? heightCm;

  @HiveField(7)
  String? padreNombre;

  @HiveField(8)
  String? padreTel;

  @HiveField(9)
  String? madreNombre;

  @HiveField(10)
  String? madreTel;

  @HiveField(11)
  String? observaciones;

  @HiveField(12)
  bool isArchived;

  @HiveField(13)
  int stars; 

  @HiveField(14)
  Map<String, List<String>> attendanceByClass; // CLAVE: ID de Clase -> Lista de Fechas

  @HiveField(15)
  List<String> classIds; // Clases a las que está inscrito
  
  // --- NUEVOS CAMPOS PARA PAGOS Y NOTIFICACIONES ---
  
  @HiveField(16)
  List<PaymentRecord> paymentHistory; // Historial de pagos

  @HiveField(17)
  List<NotificationEvent> notificationHistory; // Historial de notificaciones enviadas

  @HiveField(18) // Renumbering fields to accommodate new ones
  DateTime creationDate;
  
  @HiveField(19)
  List<String> searchableTags;

  Student({
    this.id = '',
    required this.nombre,
    this.photoPath,
    required this.dni, // CHANGED: Required
    this.fechaNacimiento, // RENAMED
    this.weightKg,
    this.heightCm,
    this.padreNombre,
    this.padreTel,
    this.madreNombre,
    this.madreTel,
    this.observaciones,
    this.isArchived = false,
    this.stars = 0,
    Map<String, List<String>>? attendanceByClass,
    List<String>? classIds,
    List<PaymentRecord>? paymentHistory,
    List<NotificationEvent>? notificationHistory,
    DateTime? creationDate,
    List<String>? searchableTags,
  })  : attendanceByClass = attendanceByClass ?? {},
        classIds = classIds ?? [],
        paymentHistory = paymentHistory ?? [],
        notificationHistory = notificationHistory ?? [],
        creationDate = creationDate ?? DateTime.now(),
        searchableTags = searchableTags ?? [];

  // --- GETTERS INTELIGENTES ---
  
  int get edad {
    if (fechaNacimiento == null) return 0;
    var age = DateTime.now().year - fechaNacimiento!.year;
    // Ajuste por mes/día
    if (DateTime.now().month < fechaNacimiento!.month || 
        (DateTime.now().month == fechaNacimiento!.month && DateTime.now().day < fechaNacimiento!.day)) {
      age--;
    }
    return age;
  }

  String get categoriaBusqueda {
    if (edad >= 3 && edad <= 6) {
      return "Inicial";
    } else if (edad >= 7 && edad <= 17) {
      return "Juvenil";
    } else if (edad >= 18) {
      return "Adulto";
    }
    return "Sin Categoría";
  }

  // --- LÓGICA DINÁMICA DE ASISTENCIA ---

  // Obtener asistencias de una clase específica en un mes
  int getAsistenciasPorClase(String classId, int month, int year) {
    if (!attendanceByClass.containsKey(classId)) return 0;
    
    return attendanceByClass[classId]!.where((dateStr) {
      final date = DateTime.parse(dateStr);
      return date.month == month && date.year == year;
    }).length;
  }

  // Saber si vino HOY a ESTA clase
  bool fuePresenteHoy(String classId) {
    if (!attendanceByClass.containsKey(classId)) return false;
    
    final now = DateTime.now();
    final todayStr = DateTime(now.year, now.month, now.day).toIso8601String();
    // Buscamos si la fecha de hoy existe en la lista de ESA clase
    return attendanceByClass[classId]!.any((d) => d.startsWith(todayStr.substring(0, 10)));
  }

  // Marcar presente (Toggle)
  void toggleAsistenciaHoy(String classId) {
    final now = DateTime.now();
    final todayPrefix = DateTime(now.year, now.month, now.day).toIso8601String().substring(0, 10);
    
    // Asegurar que existe la lista para esta clase
    if (!attendanceByClass.containsKey(classId)) {
      attendanceByClass[classId] = [];
    }

    final lista = attendanceByClass[classId]!;
    final existe = lista.any((d) => d.startsWith(todayPrefix));

    if (existe) {
      // Si ya vino, lo borramos (ANULAR)
      lista.removeWhere((d) => d.startsWith(todayPrefix));
    } else {
      // Si no vino, lo agregamos (PRESENTE)
      lista.add(now.toIso8601String());
    }
  }

  // --- LÓGICA DE PAGOS (NUEVO) ---

  void addPayment(PaymentRecord payment) {
    paymentHistory.add(payment);
    save(); // Guardar el objeto Hive modificado
  }
  
  // --- LÓGICA DE NOTIFICACIONES (NUEVO) ---

  void addNotification(NotificationEvent event) {
    notificationHistory.add(event);
    save(); // Guardar el objeto Hive modificado
  }
}