import 'package:flutter/material.dart';
import '../models/class_schedule.dart';
import '../models/student.dart';
import '../services/database_service.dart';
import 'read_only_student_detail_screen.dart'; // IMPORTAR NUEVA VISTA SOLO LECTURA
 
class ClassDetailScreen extends StatefulWidget {
  final String scheduleId;
 
  const ClassDetailScreen({super.key, required this.scheduleId});
 
  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}
 
class _ClassDetailScreenState extends State<ClassDetailScreen> {
  final DatabaseService _dbService = DatabaseService();
  ClassSchedule? _schedule;
  List<Student> _students = [];
  bool _isLoading = true;
 
  @override
  void initState() {
    super.initState();
    _loadClassDetails();
  }
 
  Future<void> _loadClassDetails() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final schedule = _dbService.getSchedule(widget.scheduleId);
      if (schedule != null) {
        // Cargar estudiantes asociados (usando el método bidireccional)
        final students = await _dbService.getStudentsForScheduleId(widget.scheduleId);
        
        setState(() {
          _schedule = schedule;
          _students = students;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        // Manejar horario no encontrado
        _showSnackBar('Error: Clase no encontrada.');
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error al cargar detalles de la clase: $e');
      print('Error loading class details: $e');
    }
  }
 
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
 
  // --- Lógica para la vinculación de alumnos (Todo #5) ---
 
  Future<List<Student>> _loadAllUnassignedStudents() async {
    if (_schedule == null) return [];
    try {
      final allStudents = await _dbService.getAllStudents();
      final assignedIds = _schedule!.studentIds;
 
      // Filtramos: no archivados Y no asignados a esta clase
      return allStudents
          .where((s) => !s.isArchived && !assignedIds.contains(s.id))
          .toList();
    } catch (e) {
      _showSnackBar('No se pudieron cargar todos los alumnos: $e');
      return [];
    }
  }
 
  void _assignStudent(String studentId) async {
    try {
      await _dbService.assignStudentToSchedule(studentId, widget.scheduleId);
      _showSnackBar('Alumno asignado exitosamente.');
      // Recargar la lista de alumnos de la clase
      await _loadClassDetails(); 
    } catch (e) {
      _showSnackBar('Error al asignar alumno.');
      print('Assignment error: $e');
    }
  }
 
  void _openStudentSelection() async {
    if (_schedule == null || _isLoading) return;
    
    // 1. Load unassigned students
    final unassignedStudents = await _loadAllUnassignedStudents();
 
    if (unassignedStudents.isNotEmpty) {
      // 2. Present selection list
      _showStudentSelectionDialog(unassignedStudents);
    } else {
      // 3. Prompt to create a new student
      _showCreateStudentPrompt();
    }
  }
 
  void _showStudentSelectionDialog(List<Student> availableStudents) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Añadir Alumno a: ${_schedule!.nombre}', style: Theme.of(context).textTheme.titleLarge),
              ),
              ...availableStudents.map((student) => ListTile(
                title: Text(student.nombre),
                subtitle: Text('ID: ${student.id.substring(0, 8)}...'),
                onTap: () {
                  Navigator.pop(context);
                  _assignStudent(student.id);
                },
              )),
              ListTile(
                leading: const Icon(Icons.person_add),
                title: const Text('Crear Nuevo Alumno'),
                onTap: _showCreateStudentPrompt,
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
 
  void _showCreateStudentPrompt() {
    Navigator.pop(context); // Cierra el selector si está abierto
    _showSnackBar('Función de creación de nuevo alumno pendiente (Se requiere implementar StudentCreationScreen).');
  }
 
  // --- Fin Lógica de vinculación ---
 
  // --- LÓGICA DE ASISTENCIA Y PUNTUACIÓN (Requerimientos 3 y 5) ---
  void _toggleAttendance(Student student) {
    if (_schedule == null) return;
    
    // 1. Toggle state in the student object (in-memory)
    student.toggleAsistenciaHoy(widget.scheduleId);
    
    // 2. Persist change (Assuming Hive Object save)
    student.save();
    
    // 3. Refresh UI state
    setState(() {
      _showSnackBar('Asistencia actualizada para ${student.nombre}.');
    });
  }

  void _updateStudentStars(Student student, int delta) {
    if (delta == 0) return;

    // 1. Update stars (in-memory)
    student.stars += delta;
    
    // 2. Persist change
    student.save();
    
    // 3. Refresh UI state
    setState(() {
      _showSnackBar('${student.nombre}: Puntos actualizados. Nuevo total: ${student.stars}');
    });
  }
  // --- FIN LÓGICA DE ASISTENCIA Y PUNTUACIÓN ---
  String _getDaysString(List<int> days) {
    if (days.isEmpty) return 'No especificado';
    
    final dayMap = {
      1: 'Lunes', 2: 'Martes', 3: 'Miércoles', 4: 'Jueves', 
      5: 'Viernes', 6: 'Sábado', 7: 'Domingo'
    };
    
    final dayNames = days.map((d) => dayMap[d] ?? 'Día $d').toList();
    return dayNames.join(', ');
  }
 
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
 
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Clase'),
        backgroundColor: colorScheme.primaryContainer,
        actions: [
          // Acción para borrar clase (Pendiente de lógica en DBService)
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () {
              _showSnackBar('Función de eliminación pendiente.');
            },
            tooltip: 'Eliminar Clase',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _schedule == null
              ? const Center(child: Text('Clase no encontrada.'))
              : ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: <Widget>[
                    // --- Detalles de la Clase ---
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _schedule!.nombre,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: colorScheme.primary),
                            ),
                            const Divider(height: 24),
                            ListTile(
                              leading: const Icon(Icons.calendar_today),
                              title: Text(_getDaysString(_schedule!.diasDeSemana)),
                              subtitle: const Text('Días de la semana'),
                            ),
                            ListTile(
                              leading: const Icon(Icons.people_alt),
                              title: Text('${_students.length} Alumnos Inscritos'),
                              subtitle: const Text('Toca para gestionar alumnos'),
                              onTap: _openStudentSelection, // Llama al nuevo método
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // --- Lista de Alumnos ---
                    Text(
                      'Alumnos Inscritos',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Divider(),
                    if (_students.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 10.0),
                        child: Text('Aún no hay alumnos en esta clase.'),
                      ),
                    ..._students.map((student) => Card(
                      margin: const EdgeInsets.symmetric(vertical: 2.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(student.nombre.isNotEmpty ? student.nombre[0] : '?'),
                        ),
                        title: Text(student.nombre),
                        subtitle: Text('ID: ${student.id.substring(0, 8)}...'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 1. Asistencia Toggle (Requerimiento 2)
                            Tooltip(
                              message: student.fuePresenteHoy(widget.scheduleId) ? 'Marcar Ausente' : 'Marcar Presente',
                              child: Checkbox(
                                value: student.fuePresenteHoy(widget.scheduleId),
                                onChanged: (value) => _toggleAttendance(student),
                                activeColor: colorScheme.primary,
                              ),
                            ),
                            
                            const SizedBox(width: 12),

                            // 2. Control de Puntos (Estrellas - Requerimiento 5)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Restar Punto
                                Tooltip(
                                  message: 'Restar 1 Punto',
                                  child: IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                    onPressed: () => _updateStudentStars(student, -1),
                                    iconSize: 22,
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    constraints: const BoxConstraints(),
                                  ),
                                ),
                                
                                // Puntuación Actual
                                Text(
                                  '${student.stars}',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.onSurface),
                                ),

                                // Sumar Punto
                                Tooltip(
                                  message: 'Sumar 1 Punto',
                                  child: IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                    onPressed: () => _updateStudentStars(student, 1),
                                    iconSize: 22,
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    constraints: const BoxConstraints(),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(width: 15),

                            // 3. Contador de Asistencias del Mes (Requerimiento 4)
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${student.getAsistenciasPorClase(widget.scheduleId, now.month, now.year)}',
                                  style: TextStyle(color: colorScheme.secondary, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const Text('Mes', style: TextStyle(fontSize: 9)),
                              ],
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                        onTap: () {
                          // --- ACTUALIZACIÓN PARA TODO #6 ---
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ReadOnlyStudentDetailScreen(
                                studentId: student.id,
                                scheduleId: _schedule!.id,
                              ),
                            ),
                          );
                        },
                      ),
                    )),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openStudentSelection,
        label: const Text('Añadir Alumno'),
        icon: const Icon(Icons.person_add),
        tooltip: 'Añadir Alumno a la Clase',
      ),
    );
  }
}
