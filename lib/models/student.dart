import 'package:hive/hive.dart';
import 'payment_record.dart';
import 'notification_event.dart';
import 'lesion.dart';

part 'student.g.dart';

@HiveType(typeId: 1)
class Student extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String nombre;

  @HiveField(2)
  String apellido;

  @HiveField(3)
  String? photoPath;

  @HiveField(4)
  String dni;

  @HiveField(5)
  DateTime? fechaNacimiento;

  @HiveField(6)
  double? weightKg;

  @HiveField(7)
  int? heightCm;

  @HiveField(8)
  String? nombrePadre;

  @HiveField(9)
  String? apellidoPadre;

  @HiveField(10)
  String? telefonoPadre;

  @HiveField(11)
  String? nombreMadre;

  @HiveField(12)
  String? apellidoMadre;

  @HiveField(13)
  String? telefonoMadre;

  @HiveField(14)
  String? contactoEmergenciaNombre;

  @HiveField(15)
  String? contactoEmergenciaApellido;

  @HiveField(16)
  String? contactoEmergenciaTelefono;

  @HiveField(17)
  String? observaciones;

  @HiveField(18)
  bool isArchived;

  @HiveField(19)
  int stars;

  @HiveField(20)
  Map<String, List<String>> attendanceByClass;

  @HiveField(21)
  List<String> classIds;

  @HiveField(22)
  List<PaymentRecord> paymentHistory;

  @HiveField(23)
  List<NotificationEvent> notificationHistory;

  @HiveField(24)
  DateTime creationDate;

  @HiveField(25)
  List<String> searchableTags;

  @HiveField(26)
  List<Lesion> lesiones;

  @HiveField(27)
  Map<String, int> medallas; // {oro: 2, plata: 1, bronce: 3, corazon: 5}

  Student({
    this.id = '',
    required this.nombre,
    this.apellido = '',
    this.photoPath,
    required this.dni,
    this.fechaNacimiento,
    this.weightKg,
    this.heightCm,
    this.nombrePadre,
    this.apellidoPadre,
    this.telefonoPadre,
    this.nombreMadre,
    this.apellidoMadre,
    this.telefonoMadre,
    this.contactoEmergenciaNombre,
    this.contactoEmergenciaApellido,
    this.contactoEmergenciaTelefono,
    this.observaciones,
    this.isArchived = false,
    this.stars = 0,
    Map<String, List<String>>? attendanceByClass,
    List<String>? classIds,
    List<PaymentRecord>? paymentHistory,
    List<NotificationEvent>? notificationHistory,
    DateTime? creationDate,
    List<String>? searchableTags,
    List<Lesion>? lesiones,
    Map<String, int>? medallas,
  })  : attendanceByClass = attendanceByClass ?? {},
        classIds = classIds ?? [],
        paymentHistory = paymentHistory ?? [],
        notificationHistory = notificationHistory ?? [],
        creationDate = creationDate ?? DateTime.now(),
        searchableTags = searchableTags ?? [],
        lesiones = lesiones ?? [],
        medallas = medallas ?? {'oro': 0, 'plata': 0, 'bronce': 0, 'corazon': 0};

  // --- GETTERS ---

  String get nombreCompleto => '$nombre $apellido';

  String get fechaInscripcion {
    // Extraer fecha del ID formato: 20262601-dni
    if (id.isEmpty || !id.contains('-')) return '';
    final datePart = id.split('-')[0];
    if (datePart.length != 8) return '';
    
    final year = datePart.substring(0, 4);
    final month = datePart.substring(4, 6);
    final day = datePart.substring(6, 8);
    
    return '$day/$month/$year';
  }

  int get edad {
    if (fechaNacimiento == null) return 0;
    var age = DateTime.now().year - fechaNacimiento!.year;
    if (DateTime.now().month < fechaNacimiento!.month ||
        (DateTime.now().month == fechaNacimiento!.month &&
            DateTime.now().day < fechaNacimiento!.day)) {
      age--;
    }
    return age;
  }

  String get categoriaBusqueda {
    if (edad >= 3 && edad <= 11) {
      return "Inicial";
    } else if (edad >= 12 && edad <= 17) {
      return "Juvenil";
    } else if (edad >= 18) {
      return "Adulto";
    }
    return "Sin Categoría";
  }

  int get totalMedallas {
    return (medallas['oro'] ?? 0) +
        (medallas['plata'] ?? 0) +
        (medallas['bronce'] ?? 0) +
        (medallas['corazon'] ?? 0);
  }

  bool get tieneLesionesPendientes {
    return lesiones.any((l) => !l.altaMedica);
  }

  // --- LÓGICA DE ASISTENCIA ---

  int getAsistenciasPorClase(String classId, int month, int year) {
    if (!attendanceByClass.containsKey(classId)) return 0;

    return attendanceByClass[classId]!.where((dateStr) {
      final date = DateTime.parse(dateStr);
      return date.month == month && date.year == year;
    }).length;
  }

  int getAsistenciasTotalesDelMes(int month, int year) {
    int total = 0;
    for (var classId in classIds) {
      total += getAsistenciasPorClase(classId, month, year);
    }
    return total;
  }

  bool fuePresenteHoy(String classId) {
    if (!attendanceByClass.containsKey(classId)) return false;

    final now = DateTime.now();
    final todayStr = DateTime(now.year, now.month, now.day).toIso8601String();
    return attendanceByClass[classId]!
        .any((d) => d.startsWith(todayStr.substring(0, 10)));
  }

  void toggleAsistenciaHoy(String classId) {
    final now = DateTime.now();
    final todayPrefix =
        DateTime(now.year, now.month, now.day).toIso8601String().substring(0, 10);

    if (!attendanceByClass.containsKey(classId)) {
      attendanceByClass[classId] = [];
    }

    final lista = attendanceByClass[classId]!;
    final existe = lista.any((d) => d.startsWith(todayPrefix));

    if (existe) {
      lista.removeWhere((d) => d.startsWith(todayPrefix));
    } else {
      lista.add(now.toIso8601String());
    }
  }

  // --- LÓGICA DE PAGOS ---

  void addPayment(PaymentRecord payment) {
    paymentHistory.add(payment);
    save();
  }

  // --- LÓGICA DE NOTIFICACIONES ---

  void addNotification(NotificationEvent event) {
    notificationHistory.add(event);
    save();
  }

  // --- LÓGICA DE LESIONES ---

  void agregarLesion(String titulo) {
    lesiones.add(Lesion(titulo: titulo, fecha: DateTime.now()));
    save();
  }

  void marcarAltaMedica(int index) {
    if (index >= 0 && index < lesiones.length) {
      lesiones[index].altaMedica = true;
      save();
    }
  }

  // --- LÓGICA DE MEDALLAS ---

  void agregarMedalla(String tipo) {
    if (medallas.containsKey(tipo)) {
      medallas[tipo] = (medallas[tipo] ?? 0) + 1;
      save();
    }
  }
}