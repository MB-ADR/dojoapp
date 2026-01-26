import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/student.dart';
import '../models/class_schedule.dart';
import '../services/database_service.dart';
import 'student_detail_screen.dart'; 
 
class ArchivedStudentsScreen extends StatefulWidget {
  const ArchivedStudentsScreen({super.key});
 
  @override
  State<ArchivedStudentsScreen> createState() => _ArchivedStudentsScreenState();
}
 
class _ArchivedStudentsScreenState extends State<ArchivedStudentsScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<Student> _archivados = [];
  bool _isLoading = true;
  List<ClassSchedule> _clasesActivas = [];
 
  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }
 
  Future<void> _cargarDatosIniciales() async {
    setState(() => _isLoading = true);
    try {
      // [Todo 21] Obtener todos los alumnos archivados
      _archivados = await _dbService.getAllArchivedStudents();
      // Obtener clases activas para la reasignación
      _clasesActivas = _dbService.getAllSchedules();
    } catch (e) {
      _archivados = [];
    } finally {
      setState(() => _isLoading = false);
    }
  }
 
  String _formatearFecha(DateTime dt) {
    return DateFormat('dd/MM/yyyy').format(dt);
  }
 
  Future<void> _reactivarYReasignar(Student alumno) async {
    // 1. Reactivar (set isArchived = false)
    alumno.isArchived = false;
    await _dbService.saveStudent(alumno);
    
    if (_clasesActivas.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alumno reactivado, pero no hay clases para reasignar.')),
        );
        await _cargarDatosIniciales();
        return;
    }
    
    // 2. Reasignar
    await showModalBottomSheet(
      context: context,
      builder: (context) => ListView.builder(
        itemCount: _clasesActivas.length,
        itemBuilder: (context, index) {
          final clase = _clasesActivas[index];
          return ListTile(
            title: Text(clase.nombre),
            onTap: () async {
              // Asignar alumno a la clase (actualizar Student.classIds)
              await _dbService.assignStudentToSchedule(alumno.id, clase.id);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${alumno.nombre} reactivado y asignado a ${clase.nombre}'),
                  backgroundColor: Colors.green,
                ),
              );
              await _cargarDatosIniciales();
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    const successColor = Colors.green;
    return Scaffold(
      appBar: AppBar(title: const Text('Alumnos Archivados')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _archivados.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.archive, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text('No hay alumnos archivados'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _archivados.length,
                  itemBuilder: (context, index) {
                    final alumno = _archivados[index];
                    
                    // FIX 1: Cálculo dinámico de asistencia total del mes/año
                    int asistenciasTotal = 0;
                    final now = DateTime.now();
                    for (final classId in alumno.classIds) {
                      asistenciasTotal += alumno.getAsistenciasPorClase(classId, now.month, now.year);
                    }

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
                            Text('$asistenciasTotal'),
                            const SizedBox(width: 12),
                            const Icon(Icons.star, size: 14, color: Colors.orange),
                            const SizedBox(width: 4),
                            Text('${alumno.stars}'),
                          ],
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: successColor),
                          onPressed: () => _reactivarYReasignar(alumno),
                          child: const Text('Reactivar'),
                        ),
                        onTap: () {
                           Navigator.push(
                              context,
                              MaterialPageRoute(
                                // FIX 2: Usar 'student' en lugar de 'alumno' o 'ALUMNO' y quitar el argumento desconocido
                                builder: (_) => StudentDetailScreen(
                                  student: alumno,
                                  schedule: null, // No hay horario principal para alumnos archivados
                                ),
                              ),
                            );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
