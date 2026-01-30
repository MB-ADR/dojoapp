import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/student.dart';
import '../models/class_schedule.dart';
import '../models/payment_record.dart';
import '../models/notification_event.dart';

class DatabaseService {
  static const String studentBoxName = 'students';
  static const String scheduleBoxName = 'schedules';
  static const String paymentBoxName = 'payments';
  static const String notificationBoxName = 'notifications';

  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  late Box<Student> _studentBox;
  late Box<ClassSchedule> _scheduleBox;
  late Box<PaymentRecord> _paymentBox;
  late Box<NotificationEvent> _notificationBox;
  final Uuid _uuid = const Uuid();

  Future<void> initialize() async {
    _studentBox = await Hive.openBox<Student>(studentBoxName);
    _scheduleBox = await Hive.openBox<ClassSchedule>(scheduleBoxName);
    _paymentBox = await Hive.openBox<PaymentRecord>(paymentBoxName);
    _notificationBox = await Hive.openBox<NotificationEvent>(notificationBoxName);
  }

  // --- GESTIÓN DE ALUMNOS ---

  Future<void> saveStudent(Student student) async {
    if (student.id.isEmpty) {
      // Generar ID único formato: YYYYMMDD-DNI
      final now = DateTime.now();
      final datePrefix = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      student.id = '$datePrefix-${student.dni}';
      student.creationDate = now;
    }
    await _studentBox.put(student.id, student);
  }

  Future<void> deleteStudent(String id) async {
    final student = getStudent(id);
    if (student != null) {
      student.isArchived = true;
      await saveStudent(student);
    }
  }

  Student? getStudent(String id) {
    return _studentBox.get(id);
  }

  Future<List<Student>> getAllStudents() async {
    return _studentBox.values.where((s) => !s.isArchived).toList();
  }

  Future<List<Student>> getStudentsByCategoria(String categoria) async {
    final allStudents = await getAllStudents();
    return allStudents.where((s) => s.categoriaBusqueda == categoria).toList();
  }

  Future<List<Student>> getAllArchivedStudents() async {
    return _studentBox.values.where((s) => s.isArchived).toList();
  }

  Future<List<Student>> getStudentsForScheduleId(String scheduleId) async {
    final allStudents = await getAllStudents();
    return allStudents
        .where((s) => s.classIds.contains(scheduleId))
        .toList();
  }

  // Buscar alumnos con cumpleaños mañana
  List<Student> getStudentsWithBirthdayTomorrow() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final allStudents = _studentBox.values.where((s) => !s.isArchived).toList();
    
    return allStudents.where((student) {
      if (student.fechaNacimiento == null) return false;
      return student.fechaNacimiento!.month == tomorrow.month &&
          student.fechaNacimiento!.day == tomorrow.day;
    }).toList();
  }

  // --- GESTIÓN DE CLASES ---

  Future<void> saveSchedule(ClassSchedule schedule) async {
    if (schedule.id.isEmpty) {
      schedule.id = _uuid.v4();
    }
    await _scheduleBox.put(schedule.id, schedule);
  }

  Future<void> deleteSchedule(String id) async {
    await _scheduleBox.delete(id);
    await cleanupScheduleReferences(id);
  }

  List<ClassSchedule> getAllSchedules() {
    return _scheduleBox.values.toList();
  }

  ClassSchedule? getSchedule(String id) {
    return _scheduleBox.get(id);
  }

  Future<void> cleanupScheduleReferences(String scheduleId) async {
    final allStudents = await getAllStudents();
    for (var student in allStudents) {
      bool changed = false;

      if (student.classIds.contains(scheduleId)) {
        student.classIds.remove(scheduleId);
        changed = true;
      }

      if (student.attendanceByClass.containsKey(scheduleId)) {
        student.attendanceByClass.remove(scheduleId);
        changed = true;
      }

      if (changed) {
        await saveStudent(student);
      }
    }
  }

  // --- RELACIONES ALUMNO-CLASE ---

  Future<void> assignStudentToSchedule(String studentId, String scheduleId) async {
    final student = getStudent(studentId);
    final schedule = getSchedule(scheduleId);
    if (student == null || schedule == null) return;

    if (!student.classIds.contains(scheduleId)) {
      student.classIds.add(scheduleId);
      await saveStudent(student);
    }

    if (!schedule.studentIds.contains(studentId)) {
      schedule.studentIds.add(studentId);
      await saveSchedule(schedule);
    }
  }

  Future<void> unassignStudentFromSchedule(String studentId, String scheduleId) async {
    final student = getStudent(studentId);
    final schedule = getSchedule(scheduleId);
    if (student == null || schedule == null) return;

    if (student.classIds.contains(scheduleId)) {
      student.classIds.remove(scheduleId);
      await saveStudent(student);
    }

    if (schedule.studentIds.contains(studentId)) {
      schedule.studentIds.remove(studentId);
      await saveSchedule(schedule);
    }
  }

  // --- SISTEMA DE PREMIOS ---

  // Calcular ganadores del mes (ejecutar el día 1 del mes siguiente)
  Future<Map<String, dynamic>> calcularGanadoresDelMes(int year, int month) async {
    final allStudents = await getAllStudents();
    
    // Calcular estrellas totales del mes para cada alumno
    final studentScores = <String, int>{};
    
    for (var student in allStudents) {
      int totalAsistencias = 0;
      int totalClasesDelMes = 0;
      
      for (var classId in student.classIds) {
        final schedule = getSchedule(classId);
        if (schedule != null) {
          totalAsistencias += student.getAsistenciasPorClase(classId, month, year);
          totalClasesDelMes += schedule.calculateTotalClasses(month, year, student.creationDate);
        }
      }
      
      // Estrella automática si asistió a todas las clases
      int estrellasDelMes = student.stars;
      if (totalClasesDelMes > 0 && totalAsistencias >= totalClasesDelMes) {
        estrellasDelMes += 1;
      }
      
      if (estrellasDelMes > 0) {
        studentScores[student.id] = estrellasDelMes;
      }
    }
    
    // Ordenar por estrellas
    final sortedStudents = studentScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return {
      'oro': sortedStudents.isNotEmpty ? sortedStudents[0].key : null,
      'plata': sortedStudents.length > 1 ? sortedStudents[1].key : null,
      'bronce': sortedStudents.length > 2 ? sortedStudents[2].key : null,
      'participantes': sortedStudents.length > 3 
          ? sortedStudents.skip(3).map((e) => e.key).toList() 
          : <String>[],
      'empate': sortedStudents.length > 1 && sortedStudents[0].value == sortedStudents[1].value,
      'scores': studentScores,
    };
  }

  Future<void> otorgarMedallas(Map<String, dynamic> ganadores) async {
    // Oro
    if (ganadores['oro'] != null) {
      final student = getStudent(ganadores['oro']);
      if (student != null) {
        student.agregarMedalla('oro');
      }
    }
    
    // Plata
    if (ganadores['plata'] != null) {
      final student = getStudent(ganadores['plata']);
      if (student != null) {
        student.agregarMedalla('plata');
      }
    }
    
    // Bronce
    if (ganadores['bronce'] != null) {
      final student = getStudent(ganadores['bronce']);
      if (student != null) {
        student.agregarMedalla('bronce');
      }
    }
    
    // Corazones para participantes
    final participantes = ganadores['participantes'] as List<String>?;
    if (participantes != null) {
      for (var studentId in participantes) {
        final student = getStudent(studentId);
        if (student != null) {
          student.agregarMedalla('corazon');
        }
      }
    }
  }

  // Rankings históricos
  List<Student> getRankingByMedal(String medalType) {
    final allStudents = _studentBox.values.where((s) => !s.isArchived).toList();
    allStudents.sort((a, b) => 
      (b.medallas[medalType] ?? 0).compareTo(a.medallas[medalType] ?? 0)
    );
    return allStudents.where((s) => (s.medallas[medalType] ?? 0) > 0).toList();
  }

  // --- GESTIÓN DE PAGOS ---

  Future<void> recordPayment(String studentId, PaymentRecord payment) async {
    final student = getStudent(studentId);
    if (student == null) return;
    student.addPayment(payment);
  }

  // --- GESTIÓN DE NOTIFICACIONES ---

  Future<void> recordNotification(String studentId, NotificationEvent event) async {
    final student = getStudent(studentId);
    if (student == null) return;
    student.addNotification(event);
  }

  List<PaymentRecord> getAllPaymentRecords() => _paymentBox.values.toList();
  List<NotificationEvent> getAllNotificationEvents() => _notificationBox.values.toList();
}