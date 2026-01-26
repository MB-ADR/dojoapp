import 'package:flutter/material.dart';
import '../models/class_schedule.dart';
import '../services/database_service.dart';
import 'class_detail_screen.dart'; 
import 'archived_students_screen.dart'; 
 
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});
 
  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}
 
class _ScheduleScreenState extends State<ScheduleScreen> {
  List<ClassSchedule> _clases = [];
  final DatabaseService _dbService = DatabaseService();
  bool _isLoading = true;
 
  @override
  void initState() {
    super.initState();
    _cargarClases();
  }
 
  Future<void> _cargarClases() async {
    setState(() => _isLoading = true);
    try {
      final schedules = _dbService.getAllSchedules();
      _clases = schedules;
    } catch (e) {
      _clases = [];
    } finally {
      setState(() => _isLoading = false);
    }
  }
 
  Future<void> _mostrarDialogoNuevaClase() async {
    String nuevaClaseNombre = "";
    
    await showDialog(
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
              onPressed: nuevaClaseNombre.isNotEmpty
                  ? () async {
                      if (nuevaClaseNombre.isNotEmpty) {
                        final nuevaClase = ClassSchedule(nombre: nuevaClaseNombre); 
                        await _dbService.saveSchedule(nuevaClase);
                        
                        await _cargarClases(); 
                        Navigator.pop(context);
                      }
                    }
                  : null,
              child: const Text("Agregar"),
            ),
          ],
        );
      },
    );
  }
 
  Future<void> _borrarClase(int index) async {
    final claseABorrar = _clases[index];
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Borrar clase?"),
        content: Text("Se eliminará: ${claseABorrar.nombre}"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () async {
              await _dbService.deleteSchedule(claseABorrar.id);
              await _cargarClases(); 
              Navigator.pop(context);
            },
            child: const Text("Borrar", style: TextStyle(color: Colors.red)),
          )
        ],
      ),
    );
  }
 
  Widget _botonArchivados() {
    return Card(
      color: Colors.grey[200],
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ArchivedStudentsScreen()),
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
  
  Widget _botonHorario(BuildContext context, ClassSchedule clase, int index) {
    return Dismissible(
      key: Key(clase.id),
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) async {
        await _dbService.deleteSchedule(clase.id);
        await _cargarClases(); 
      },
      child: Card(
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ClassDetailScreen(scheduleId: clase.id), // FIX: Usar scheduleId
              ),
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
                    const Text(
                      'Toca para ver alumnos',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  onPressed: () => _borrarClase(index),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Horarios Dojo 🥊'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _clases.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index < _clases.length) {
                  return _botonHorario(context, _clases[index], index);
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
}