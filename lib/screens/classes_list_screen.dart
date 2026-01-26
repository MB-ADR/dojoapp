import 'package:flutter/material.dart';
import 'package:dojo_app/models/class_schedule.dart';
import 'package:dojo_app/models/student.dart';
import 'package:dojo_app/services/database_service.dart';
import 'package:dojo_app/screens/schedule_management_screen.dart';
import 'package:dojo_app/screens/read_only_student_detail_screen.dart';
import 'package:dojo_app/screens/class_creation_screen.dart';
import 'package:dojo_app/screens/new_student_form_screen.dart'; 
import 'package:dojo_app/screens/student_detail_screen.dart'; 
import 'package:hive_flutter/hive_flutter.dart';

class ClassesListScreen extends StatefulWidget {
  const ClassesListScreen({super.key});

  @override
  State<ClassesListScreen> createState() => _ClassesListScreenState();
}

class _ClassesListScreenState extends State<ClassesListScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<ClassSchedule> _classes = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadClasses();
  }
  
  Future<void> _loadClasses() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final schedules = _dbService.getAllSchedules();
      schedules.sort((a, b) => a.nombre.compareTo(b.nombre));
      setState(() {
        _classes = schedules;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackbar('Error al cargar clases: $e');
    }
  }
  
  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  void _onClassCreatedOrUpdated() {
    _loadClasses();
  }
  
  void _navigateToClassDetail(BuildContext context, ClassSchedule classSchedule) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ClassDetailScreen(classSchedule: classSchedule),
      ),
    ).then((_) => _loadClasses()); // Recargar al volver
  }
  
  void _navigateAndCreateClass(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
       builder: (context) => const ClassCreationScreen(),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Clases'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateAndCreateClass(context),
        tooltip: 'Crear Nueva Clase',
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _classes.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      'No hay clases registradas. Presiona el botón "+" para crear la primera clase.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _classes.length,
                  itemBuilder: (context, index) {
                    final classSchedule = _classes[index];
                    return _ClassCard(
                      classSchedule: classSchedule,
                      onTap: () => _navigateToClassDetail(context, classSchedule),
                    );
                  },
                ),
    );
  }
}

// Widget para la tarjeta de la clase
class _ClassCard extends StatelessWidget {
  final ClassSchedule classSchedule;
  final VoidCallback onTap;

  const _ClassCard({
    required this.classSchedule,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final studentCount = classSchedule.studentIds.length;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      elevation: 3.0,
      child: ListTile(
        title: Text(
          classSchedule.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Alumnos inscritos: $studentCount'),
        trailing: const Icon(Icons.chevron_right, size: 24),
        onTap: onTap,
      ),
    );
  }
}

// --- CLASE DE DETALLE DE CLASE (ClassDetailScreen) ---
class ClassDetailScreen extends StatefulWidget {
  final ClassSchedule classSchedule;
  const ClassDetailScreen({super.key, required this.classSchedule});

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<Student> _enrolledStudents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEnrolledStudents();
  }

  Future<void> _loadEnrolledStudents() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final students = await _dbService.getStudentsForScheduleId(widget.classSchedule.id);
      
      students.sort((a, b) => a.nombre.compareTo(b.nombre));
      
      setState(() {
        _enrolledStudents = students;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackbar('Error al cargar alumnos de la clase: $e');
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Acción A: Vincular Alumno Existente
  Future<void> _linkExistingStudent() async {
    final allStudents = await _dbService.getAllStudents();
    final unassignedStudents = allStudents
        .where((s) => !s.classIds.contains(widget.classSchedule.id) && !s.isArchived)
        .toList();
    
    if (unassignedStudents.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay alumnos activos disponibles para vincular.')),
        );
        return;
    }

    final Student? selectedStudent = await showDialog<Student>(
      context: context,
      builder: (context) => _StudentSelectionDialog(students: unassignedStudents),
    );

    if (selectedStudent != null) {
      await _dbService.assignStudentToSchedule(selectedStudent.id, widget.classSchedule.id);
      _loadEnrolledStudents(); // Refrescar lista
    }
  }

  // Acción B: Crear Nuevo Alumno y Asignarlo
  Future<void> _createNewStudentAndAssign() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const NewStudentFormScreen(), 
      ),
    );

    if (result is String && result.isNotEmpty) { // Esperamos el ID del nuevo estudiante
        await _dbService.assignStudentToSchedule(result, widget.classSchedule.id);
        _loadEnrolledStudents(); // Refrescar lista
    }
  }

  // Acción al tocar un alumno (Debe abrir ReadOnlyStudentDetailScreen)
  void _viewStudentDetails(Student student) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReadOnlyStudentDetailScreen(studentId: student.id),
      ),
    );
  }

  void _deleteStudentFromClass(Student student) {
    // Desvincular
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desvincular Alumno'),
        content: Text('¿Estás seguro de que deseas desvincular a ${student.nombre} de la clase "${widget.classSchedule.nombre}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              await _dbService.unassignStudentFromSchedule(student.id, widget.classSchedule.id);
              _loadEnrolledStudents();
              Navigator.of(ctx).pop();
            },
            child: const Text('Desvincular', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.classSchedule.nombre),
        actions: [
          // Botón para configurar horarios (Conecta con ScheduleManagementScreen)
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Configurar Horarios/Días',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ScheduleManagementScreen(
                    schedule: widget.classSchedule,
                    onSave: (updatedSchedule) {
                      _dbService.saveSchedule(updatedSchedule).then((_) {
                        if (!mounted) return;
                        _loadEnrolledStudents(); 
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Horarios actualizados.')),
                        );
                      });
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Sección de Acciones rápidas
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Acción A: Vincular Alumno Existente
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: ElevatedButton.icon(
                            onPressed: _linkExistingStudent,
                            icon: const Icon(Icons.link),
                            label: const Text('Vincular Alumno Existente'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 40),
                            ),
                          ),
                        ),
                      ),
                      // Acción B: Crear Nuevo Alumno
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4.0),
                          child: ElevatedButton.icon(
                            onPressed: _createNewStudentAndAssign,
                            icon: const Icon(Icons.person_add),
                            label: const Text('Crear Nuevo Alumno'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 40),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                
                // Lista de Alumnos Inscritos
                Expanded(
                  child: _enrolledStudents.isEmpty
                      ? const Center(
                          child: Text('Aún no hay alumnos inscritos en esta clase.'),
                        )
                      : ListView.builder(
                          itemCount: _enrolledStudents.length,
                          itemBuilder: (context, index) {
                            final student = _enrolledStudents[index];
                            return _EnrolledStudentTile(
                              student: student,
                              onTap: () => _viewStudentDetails(student),
                              onRemove: () => _deleteStudentFromClass(student),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

// --- WIDGETS AUXILIARES ---

// Diálogo para seleccionar alumno existente
class _StudentSelectionDialog extends StatefulWidget {
  final List<Student> students;
  const _StudentSelectionDialog({required this.students});

  @override
  State<_StudentSelectionDialog> createState() => _StudentSelectionDialogState();
}

class _StudentSelectionDialogState extends State<_StudentSelectionDialog> {
  Student? _selectedStudent;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Seleccionar Alumno para Vincular'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: widget.students.map((student) {
            return RadioListTile<Student>(
              title: Text(student.nombre),
              value: student,
              groupValue: _selectedStudent,
              onChanged: (Student? value) {
                setState(() {
                  _selectedStudent = value;
                });
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _selectedStudent != null
              ? () => Navigator.of(context).pop(_selectedStudent)
              : null,
          child: const Text('Vincular'),
        ),
      ],
    );
  }
}

// Tile para mostrar un alumno inscrito (con acción de quitar)
class _EnrolledStudentTile extends StatelessWidget {
  final Student student;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _EnrolledStudentTile({
    required this.student,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      elevation: 1.0,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          child: Text(
            student.nombre.isNotEmpty ? student.nombre.substring(0, 1) : '?',
            style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer),
          ),
        ),
        title: Text(
            student.nombre,
            style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text('Estrellas: ${student.stars}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.link_off, color: Colors.red),
              tooltip: 'Desvincular de la clase',
              onPressed: onRemove,
            ),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
        onTap: onTap, // Abre la ficha en modo SOLO LECTURA
      ),
    );
  }
}

// Nota: Se asume que ClassCreationScreen, NewStudentFormScreen y ReadOnlyStudentDetailScreen existen.
