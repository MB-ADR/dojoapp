import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:dojo_app/models/student.dart';
import 'package:dojo_app/models/class_schedule.dart';
import 'package:dojo_app/models/payment_record.dart';
import 'package:dojo_app/models/notification_event.dart';
import 'package:dojo_app/screens/schedule_management_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

// --- DatabaseService implementation ---
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
  
  Future<void> recordPayment(String studentId, PaymentRecord payment) async {
      final student = getStudent(studentId);
      if (student == null) return;
      
      student.addPayment(payment); 
  }
  
  Future<void> recordNotification(String studentId, NotificationEvent event) async {
      final student = getStudent(studentId);
      if (student == null) return;
      
      student.addNotification(event); 
  }
  
  List<PaymentRecord> getAllPaymentRecords() => _paymentBox.values.toList();
  List<NotificationEvent> getAllNotificationEvents() => _notificationBox.values.toList();
  
}

// ==========================================
// PANTALLA 1: HORARIOS (MODIFICADA PARA USAR HiveObject/Adapter)
// ==========================================
class PantallaHorarios extends StatefulWidget {
  const PantallaHorarios({super.key});

  @override
  State<PantallaHorarios> createState() => _PantallaHorariosState();
}

class _PantallaHorariosState extends State<PantallaHorarios> {
  final Box<ClassSchedule> _scheduleBox = Hive.box<ClassSchedule>(DatabaseService.scheduleBoxName);
  List<ClassSchedule> clases = [];
  final dbService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _cargarClases();
  }

  void _cargarClases() {
    clases = _scheduleBox.values.toList();
    
    if (clases.isEmpty) {
      dbService.initialize().then((_) {
         clases = _scheduleBox.values.toList();
         setState(() {});
      });
    }
    setState(() {});
  }

  void _mostrarDialogoNuevaClase() {
    String nuevaClaseNombre = "";
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Agregar Nueva Clase"),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              labelText: "Nombre y Horario",
              hintText: "Ej: 19:00 hs - Juveniles",
            ),
            onChanged: (texto) => nuevaClaseNombre = texto,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () {
                if (nuevaClaseNombre.isNotEmpty) {
                  final nuevaClase = ClassSchedule(
                    nombre: nuevaClaseNombre,
                    diasDeSemana: const [1, 3, 5],
                  );
                  dbService.saveSchedule(nuevaClase);
                  setState(() {}); 
                  Navigator.pop(context);
                }
              },
              child: const Text("Agregar"),
            ),
          ],
        );
      },
    );
  }

  void _borrarClase(ClassSchedule clase) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Borrar clase?"),
        content: Text("Se eliminará: ${clase.nombre}. Las referencias de asistencia en alumnos se limpiarán."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Borrar", style: TextStyle(color: Colors.red)),
          )
        ],
      ),
    );

    if (confirm == true) {
      await dbService.deleteSchedule(clase.id); 
      await dbService.cleanupScheduleReferences(clase.id);
      
      setState(() {
        clases.removeWhere((c) => c.id == clase.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Horarios Dojo 🥊'),
        elevation: 0,
        actions: [
           IconButton(
            icon: const Icon(Icons.people_alt),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PantallaGestionAlumnos()),
              );
            },
          ),
        ]
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: clases.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index < clases.length) {
            return _botonHorario(context, clases[index]);
          }
          return _botonArchivados();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogoNuevaClase,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _botonHorario(BuildContext context, ClassSchedule clase) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PantallaClase(horario: clase)),
          ).then((_) => setState(() {}));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    clase.nombre,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Días: ${clase.diasDeSemana.map((d) => _diaCorto(d)).join(', ')}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const Text(
                    'Toca para ver alumnos',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onPressed: () => _borrarClase(clase),
              )
            ],
          ),
        ),
      ),
    );
  }
  
  String _diaCorto(int weekday) {
    const dias = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];
    if (weekday >= 1 && weekday <= 7) {
        return dias[weekday - 1];
    }
    return '?';
  }

  Widget _botonArchivados() {
    return Card(
      color: Colors.grey[200],
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PantallaArchivados()),
          ).then((_) => setState(() {}));
        },
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.archive, color: Colors.grey, size: 28),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alumnos Archivados',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Gestionar alumnos inactivos',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// PANTALLA 2: LISTA DE ALUMNOS (MODIFICADA PARA USAR HiveObject/Adapter)
// ==========================================
class PantallaClase extends StatefulWidget {
  final ClassSchedule horario;
  const PantallaClase({super.key, required this.horario});

  @override
  State<PantallaClase> createState() => _PantallaClaseState();
}

class _PantallaClaseState extends State<PantallaClase> {
  late List<Student> alumnos;
  late ClassSchedule _schedule;
  final dbService = DatabaseService();
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _schedule = widget.horario;
    _cargarAlumnos();
  }

  void _cargarAlumnos() {
    dbService.getStudentsForScheduleId(_schedule.id).then((students) {
        alumnos = students;
        setState(() => _cargando = false);
    });
  }

  void _actualizarAlumno(Student student) {
    dbService.saveStudent(student);
  }

  void _guardarSchedule(ClassSchedule updated) {
    _schedule = updated;
    dbService.saveSchedule(_schedule);
    setState(() {});
  }

  void _abrirConfiguracion() {
    Navigator.push<ClassSchedule?>(
      context,
      MaterialPageRoute(
        builder: (_) => ScheduleManagementScreen(
          schedule: _schedule,
          onSave: _guardarSchedule,
        ),
      ),
    ).then((_) => _cargarAlumnos());
  }

  void _eliminarAlumno(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archivar alumno'),
        content: Text('¿Deseas archivar a ${alumnos[index].nombre}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final alumnoId = alumnos[index].id;
              dbService.deleteStudent(alumnoId);
              
              setState(() {
                alumnos.removeAt(index);
              });
              
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${alumnos[index].nombre} archivado')),
              );
            },
            child: const Text('Archivar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Text(_schedule.nombre),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _abrirConfiguracion,
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : alumnos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text('No hay alumnos inscritos en esta clase'),
                      const SizedBox(height: 8),
                       ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PantallaGestionAlumnos()),
                        ).then((_) => _cargarAlumnos()),
                        child: const Text('Añadir Alumno Existente'),
                      )
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: alumnos.length,
                  itemBuilder: (context, index) {
                    final alumno = alumnos[index];
                    final asistenciasEsteMes = alumno.getAsistenciasPorClase(
                      _schedule.id, 
                      now.month, 
                      now.year
                    );
                    final totalClasesEsteMes = _schedule.calculateTotalClasses(
                      now.month,
                      now.year,
                      alumno.creationDate,
                    );

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.red[100],
                          backgroundImage: alumno.photoPath != null
                              ? FileImage(File(alumno.photoPath!)) as ImageProvider
                              : null,
                          child: alumno.photoPath == null
                              ? Text(
                                  alumno.nombre[0].toUpperCase(),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                        title: Text(
                          alumno.nombre,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Row(
                          children: [
                            const Icon(Icons.check_circle, size: 14, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text('$asistenciasEsteMes/$totalClasesEsteMes'),
                            const SizedBox(width: 12),
                            const Icon(Icons.star, size: 14, color: Colors.orange),
                            const SizedBox(width: 4),
                            Text('${alumno.stars}'),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              child: const Text('Ver ficha'),
                              onTap: () => _abrirFicha(index),
                            ),
                            PopupMenuItem(
                              child: const Text('Archivar', style: TextStyle(color: Colors.red)),
                              onTap: () => _eliminarAlumno(index),
                            ),
                          ],
                        ),
                        onTap: () => _abrirFicha(index),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PantallaGestionAlumnos()),
        ).then((_) => _cargarAlumnos()),
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Future<void> _abrirFicha(int index) async {
    final actualizado = await Navigator.push<Student?>(
      context,
      MaterialPageRoute(
        builder: (_) => PantallaFichaAlumno(
          alumno: alumnos[index],
          schedule: _schedule,
        ),
      ),
    );
    if (actualizado != null) {
      _actualizarAlumno(actualizado);
      if (actualizado.isArchived) {
          _cargarAlumnos();
      } else {
          setState(() {
            alumnos[index] = actualizado;
          });
      }
    }
  }
}

// ==========================================
// PANTALLA 3: FICHA COMPLETA (MODIFICADA PARA USAR HiveObject/Adapter y lógica de clase)
// ==========================================
class PantallaFichaAlumno extends StatefulWidget {
  final Student? alumno;
  final ClassSchedule? schedule;
  const PantallaFichaAlumno({super.key, required this.alumno, this.schedule});

  @override
  State<PantallaFichaAlumno> createState() => _PantallaFichaAlumnoState();
}

class _PantallaFichaAlumnoState extends State<PantallaFichaAlumno> {
  late Student student;
  late TextEditingController _nombreController;
  late TextEditingController _dniController;
  late TextEditingController _padreNombreController;
  late TextEditingController _padreTelController;
  late TextEditingController _madreNombreController;
  late TextEditingController _madreTelController;
  late TextEditingController _obsController;

  final Box<Student> _studentBox = Hive.box<Student>(DatabaseService.studentBoxName);
  final dbService = DatabaseService();
  
  List<ClassSchedule> clasesDisponibles = [];

  @override
  void initState() {
    super.initState();
    
    student = widget.alumno != null 
        ? widget.alumno! 
        : Student(
            id: '', 
            nombre: '', 
            dni: '', 
            creationDate: DateTime.now(),
          ); 

    _nombreController = TextEditingController(text: student.nombre);
    _dniController = TextEditingController(text: student.dni);
    _padreNombreController = TextEditingController(text: student.padreNombre ?? '');
    _padreTelController = TextEditingController(text: student.padreTel ?? '');
    _madreNombreController = TextEditingController(text: student.madreNombre ?? '');
    _madreTelController = TextEditingController(text: student.madreTel ?? '');
    _obsController = TextEditingController(text: student.observaciones ?? '');
    
    _cargarClasesDisponibles();
  }
  
  void _cargarClasesDisponibles() {
    clasesDisponibles = dbService.getAllSchedules();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _dniController.dispose();
    _padreNombreController.dispose();
    _padreTelController.dispose();
    _madreNombreController.dispose();
    _madreTelController.dispose();
    _obsController.dispose();
    super.dispose();
  }

  Future<void> _tomarFoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? foto = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (foto == null) return;
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String fileName = 'alumno_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final File saved = await File(foto.path).copy('${appDir.path}/$fileName');
      setState(() => student.photoPath = saved.path);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al tomar foto: $e')),
      );
    }
  }

  void _marcarAsistencia() {
    if (widget.schedule == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debe estar en una pantalla de clase para marcar asistencia.'),
            duration: Duration(seconds: 3),
          ),
        );
        return;
    }
    
    if (!widget.schedule!.esHoyDiaDeClase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hoy no hay clase programada para este horario.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      student.toggleAsistenciaHoy(widget.schedule!.id);
    });
  }

  void _agregarEstrella() => setState(() => student.stars++);
  void _quitarEstrella() => setState(() {
    if (student.stars > 0) student.stars--;
  });

  void _guardarYSalir() {
    student.nombre = _nombreController.text;
    student.dni = _dniController.text;
    student.padreNombre = _padreNombreController.text.isNotEmpty ? _padreNombreController.text : null;
    student.padreTel = _padreTelController.text.isNotEmpty ? _padreTelController.text : null;
    student.madreNombre = _madreNombreController.text.isNotEmpty ? _madreNombreController.text : null;
    student.madreTel = _madreTelController.text.isNotEmpty ? _madreTelController.text : null;
    student.observaciones = _obsController.text.isNotEmpty ? _obsController.text : null;
    
    if (student.id.isEmpty) {
      student.id = _studentBox.keys.isNotEmpty ? 'std_${_studentBox.keys.length + 1}' : 'std_001';
      student.creationDate = DateTime.now();
      
      if (widget.schedule != null) {
        student.classIds.add(widget.schedule!.id);
        student.toggleAsistenciaHoy(widget.schedule!.id); 
      }
    }
    dbService.saveStudent(student);
    
    Navigator.of(context).pop(student);
  }

  Future<void> _archivarAlumno() async {
    if (student.id.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Guarda primero al alumno para poder archivarlo.')),
        );
        return;
    }
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archivar Alumno'),
        content: Text('¿Deseas archivar a ${student.nombre}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Archivar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      student.isArchived = true;
      dbService.saveStudent(student);
      if (mounted) Navigator.of(context).pop(student);
    }
  }
  
  String _formatearFecha(DateTime dt) {
    return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
  }
  
  void _desinscribirDeClase(ClassSchedule clase) {
      setState(() {
          student.classIds.remove(clase.id);
          student.attendanceByClass.remove(clase.id);
          dbService.saveStudent(student);
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${student.nombre} desinscrito de ${clase.nombre}')),
          );
          if (widget.schedule != null && clase.id == widget.schedule!.id) {
              Navigator.pop(context); 
          } else {
              _cargarClasesDisponibles();
          }
      });
  }
  
  void _inscribirEnClase(ClassSchedule clase) {
      setState(() {
          if (!student.classIds.contains(clase.id)) {
              student.classIds.add(clase.id);
              dbService.saveStudent(student);
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${student.nombre} inscrito en ${clase.nombre}')),
              );
              _cargarClasesDisponibles();
          }
      });
  }


  Widget _buildDatosParentales(
    String titulo,
    TextEditingController nombre,
    TextEditingController tel,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DATOS $titulo',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nombre,
              decoration: InputDecoration(
                labelText: 'Nombre $titulo',
                prefixIcon: const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tel,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Teléfono $titulo',
                prefixIcon: const Icon(Icons.phone),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _mesActual(int month) {
    const meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return meses[month - 1];
  }
}


// ==========================================
// PANTALLA 4: ALUMNOS ARCHIVADOS (MODIFICADA PARA USAR HiveObject/Adapter)
// ==========================================
class PantallaArchivados extends StatefulWidget {
  const PantallaArchivados({super.key});

  @override
  State<PantallaArchivados> createState() => _PantallaArchivadosState();
}

class _PantallaArchivadosState extends State<PantallaArchivados> {
  final dbService = DatabaseService();
  List<Student> archivados = [];

  @override
  void initState() {
    super.initState();
    _cargarArchivados();
  }

  void _cargarArchivados() {
    dbService.getAllArchivedStudents().then((students) {
        archivados = students;
        setState(() {});
    });
  }
  
  void _reasignarAlumno(Student alumno) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final clasesDisponibles = dbService.getAllSchedules();
        return ListView.builder(
          itemCount: clasesDisponibles.length,
          itemBuilder: (context, index) {
            final clase = clasesDisponibles[index];
            return ListTile(
              title: Text(clase.nombre),
              onTap: () {
                dbService.assignStudentToSchedule(alumno.id, clase.id);
                alumno.isArchived = false;
                alumno.save();
                _cargarArchivados();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${alumno.nombre} reactivado e inscrito en ${clase.nombre}')),
                );
              },
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alumnos Archivados')),
      body: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: archivados.length,
              itemBuilder: (context, index) {
                final alumno = archivados[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey[300],
                      backgroundImage: alumno.photoPath != null
                          ? FileImage(File(alumno.photoPath!)) as ImageProvider
                          : null,
                      child: alumno.photoPath == null
                          ? Text(alumno.nombre[0].toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.bold))
                          : null,
                    ),
                    title: Text(alumno.nombre),
                    subtitle: Row(
                      children: [
                        const Icon(Icons.check_circle, size: 14, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text('${alumno.asistenciasTotal}'),
                        const SizedBox(width: 12),
                        const Icon(Icons.star, size: 14, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text('${alumno.stars}'),
                      ],
                    ),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
                      onPressed: () => _reasignarAlumno(alumno),
                      child: const Text('Reactivar'),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// Placeholder para PantallaGestionAlumnos (CRUD general)
class PantallaGestionAlumnos extends StatelessWidget {
  const PantallaGestionAlumnos({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión General de Alumnos')),
      body: const Center(child: Text('Implementar aquí la vista maestra de alumnos (PantallaGestionAlumnos)')),
    );
  }
}
// Placeholders de clases que deben existir:
class AppTheme {
  static const Color primaryColor = Colors.blue;
  static const Color accentColor = Colors.deepOrange;
  static const Color successColor = Colors.green;
  static final ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.blue,
    primaryColor: primaryColor,
    colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue).copyWith(secondary: accentColor),
  );
}
// Fin de Placeholders
