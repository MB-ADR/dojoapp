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

    // Si no hay horarios, crear algunos por defecto
    if (_scheduleBox.isEmpty) {
      await _seedInitialSchedules();
    }
  }

  Future<void> _seedInitialSchedules() async {
    final initialSchedules = [
      ClassSchedule(id: 'infantil_17', nombre: '17:00 hs - Infantiles', diasDeSemana: [1, 3, 5]),
      ClassSchedule(id: 'juvenil_19', nombre: '19:00 hs - Juveniles', diasDeSemana: [2, 4, 6]),
      ClassSchedule(id: 'adulto_21', nombre: '21:00 hs - Adultos', diasDeSemana: [1, 4]),
      ClassSchedule(id: 'competidor_22', nombre: '22:00 hs - Competidores', diasDeSemana: [2, 5]),
    ];

    for (var schedule in initialSchedules) {
      await saveSchedule(schedule);
    }
  }

  // --- Gestión de Horarios ---
  Future<void> saveSchedule(ClassSchedule schedule) async {
    if (schedule.id.isEmpty) {
      schedule.id = _uuid.v4();
    }
    await _scheduleBox.put(schedule.id, schedule);
  }

  Future<void> deleteSchedule(String id) async {
    await _scheduleBox.delete(id);
  }

  List<ClassSchedule> getAllSchedules() {
    return _scheduleBox.values.toList();
  }

  ClassSchedule? getSchedule(String id) {
    return _scheduleBox.get(id);
  }
  
  // Lógica adicional para limpiar referencias al borrar una clase (Requerido por TODO 3)
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


  // --- Gestión de Alumnos ---
  Future<void> saveStudent(Student student) async {
    if (student.id.isEmpty) {
      student.id = _uuid.v4();
    }
    await _studentBox.put(student.id, student);
  }

  Future<void> deleteStudent(String id) async {
    // Soft delete: solo lo marcamos como archivado
    final student = getStudent(id);
    if (student != null) {
      student.isArchived = true;
      await saveStudent(student);
    }
  }

  Student? getStudent(String id) {
    return _studentBox.get(id);
  }

  Future<List<Student>> getStudentsForScheduleId(String scheduleId) async {
    final allStudents = await getAllStudents();
    return allStudents
        .where((s) => s.classIds.contains(scheduleId) && !s.isArchived)
        .toList();
  }

  Future<List<Student>> getAllStudents() async {
    return _studentBox.values.toList();
  }

  Future<List<Student>> getAllArchivedStudents() async {
    final allStudents = await getAllStudents();
    return allStudents.where((s) => s.isArchived).toList();
  }

  // --- Relaciones ---
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
  
  // --- Gestión de Pagos (Implementación base) ---
  Future<void> recordPayment(String studentId, PaymentRecord payment) async {
      final student = getStudent(studentId);
      if (student == null) return;
      
      student.addPayment(payment); 
  }
  
  // --- Gestión de Notificaciones (Implementación base) ---
  Future<void> recordNotification(String studentId, NotificationEvent event) async {
      final student = getStudent(studentId);
      if (student == null) return;
      
      student.addNotification(event); 
  }
  
  // Métodos para acceder a pagos/notificaciones globales si se decide no guardarlos solo en el estudiante
  List<PaymentRecord> getAllPaymentRecords() => _paymentBox.values.toList();
  List<NotificationEvent> getAllNotificationEvents() => _notificationBox.values.toList();
  
}
