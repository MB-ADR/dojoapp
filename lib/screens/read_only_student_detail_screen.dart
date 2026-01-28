import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/student.dart';
import '../models/class_schedule.dart';
import '../services/database_service.dart';
 
class ReadOnlyStudentDetailScreen extends StatelessWidget {
  final String studentId;
  final String? scheduleId;
 
  const ReadOnlyStudentDetailScreen({
    super.key, 
    required this.studentId,
    this.scheduleId,
  });
 
  String _formatearFecha(DateTime dt) => DateFormat('dd/MM/yyyy').format(dt);
  
  String _mesActual(int month) {
    const meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    if (month < 1 || month > 12) return '-';
    return meses[month - 1];
  }
  
  @override
  Widget build(BuildContext context) {
    final dbService = DatabaseService();
    final now = DateTime.now();
    
    return Scaffold(
      appBar: AppBar(title: const Text('Ficha (Solo Lectura)')),
      body: FutureBuilder<Student?>(
        future: Future.value(dbService.getStudent(studentId)),
        builder: (context, studentSnapshot) {
          if (!studentSnapshot.hasData || studentSnapshot.data == null) return const Center(child: CircularProgressIndicator());
          
          final student = studentSnapshot.data!;
          // (No hubo cambios aquí, pero mantenemos el contexto)
          
          ClassSchedule? schedule;
          if (scheduleId != null) {
            schedule = dbService.getSchedule(scheduleId!);
          }
 
          int asistenciasEsteMes = 0;
          bool presenteHoy = false;
          int totalClases = 0;
          List<String> historialClase = [];
          
          final String currentClassId = schedule?.id ?? (student.classIds.isNotEmpty ? student.classIds.first : '');
 
          if (currentClassId.isNotEmpty) {
            asistenciasEsteMes = student.getAsistenciasPorClase(currentClassId, now.month, now.year);
            presenteHoy = student.fuePresenteHoy(currentClassId);
 
            if (schedule != null) {
                totalClases = schedule.calculateTotalClasses(now.month, now.year, student.creationDate);
            }
            
            historialClase = student.attendanceByClass[currentClassId] ?? [];
          }
 
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: student.photoPath != null 
                      ? FileImage(File(student.photoPath!)) as ImageProvider 
                      : null,
                  child: student.photoPath == null ? const Icon(Icons.person, size: 40) : null,
                ),
                const SizedBox(height: 20),
                
                // DATOS GENERALES
                _buildField('Nombre', student.nombre),
                _buildField('DNI', student.dni), // dni ya no es nullable, quitamos el "??"
                // CORRECCIÓN: Usar fechaNacimiento en vez de birthDate
                _buildField('Fecha Nacimiento', student.fechaNacimiento == null ? 'N/A' : _formatearFecha(student.fechaNacimiento!)),
                _buildField('Peso (Kg)', student.weightKg?.toString() ?? 'N/A'),
                _buildField('Altura (Cm)', student.heightCm?.toString() ?? 'N/A'),
                
                const Divider(height: 30),

                _buildField('Padre', '${student.nombrePadre ?? ''} ${student.apellidoPadre ?? ''}'),
                _buildField('Tel Padre', student.telefonoPadre ?? '-'),
                _buildField('Madre', '${student.nombreMadre ?? ''} ${student.apellidoMadre ?? ''}'),
                _buildField('Tel Madre', student.telefonoMadre ?? '-'),                
                const Divider(height: 30),
                _buildField('Observaciones', student.observaciones ?? '-'),
 
                const Divider(height: 30),
 
                if (schedule != null) ...[
                   Text('Asistencias ${schedule.nombre} (${_mesActual(now.month)})', 
                      style: const TextStyle(fontWeight: FontWeight.bold)
                   ),
                   const SizedBox(height: 10),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceAround,
                     children: [
                       Text('$asistenciasEsteMes / $totalClases', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                       Container(
                         padding: const EdgeInsets.all(8),
                         decoration: BoxDecoration(
                           color: presenteHoy ? Colors.green[100] : Colors.grey[200],
                           borderRadius: BorderRadius.circular(8)
                         ),
                         child: Text(presenteHoy ? 'PRESENTE HOY' : 'AUSENTE'),
                       )
                     ],
                   ),
                   const SizedBox(height: 20),
                ],
 
                Card(
                  color: Colors.orange[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text('Estrellas (Méritos)', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('${student.stars}', style: const TextStyle(fontSize: 32, color: Colors.orange)),
                      ],
                    ),
                  ),
                ),
 
                if (historialClase.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text('Historial Reciente:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...historialClase.reversed.take(5).map((d) => Text(_formatearFecha(DateTime.parse(d)))),
                ]
              ],
            ),
          );
        },
      ),
    );
  }
 
  Widget _buildField(String label, String value) {
    return ListTile(
      title: Text(value),
      subtitle: Text(label),
      dense: true,
    );
  }
}