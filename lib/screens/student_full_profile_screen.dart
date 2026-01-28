import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/student.dart';
import '../models/class_schedule.dart';
import '../models/lesion.dart';
import '../services/database_service.dart';

class StudentFullProfileScreen extends StatefulWidget {
  final Student student;

  const StudentFullProfileScreen({super.key, required this.student});

  @override
  State<StudentFullProfileScreen> createState() => _StudentFullProfileScreenState();
}

class _StudentFullProfileScreenState extends State<StudentFullProfileScreen> {
  final DatabaseService _dbService = DatabaseService();
  late Student _student;
  final ImagePicker _picker = ImagePicker();

  // Controllers
  late TextEditingController _nombreController;
  late TextEditingController _apellidoController;
  late TextEditingController _dniController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _nombrePadreController;
  late TextEditingController _apellidoPadreController;
  late TextEditingController _telefonoPadreController;
  late TextEditingController _nombreMadreController;
  late TextEditingController _apellidoMadreController;
  late TextEditingController _telefonoMadreController;
  late TextEditingController _contactoEmergenciaNombreController;
  late TextEditingController _contactoEmergenciaApellidoController;
  late TextEditingController _contactoEmergenciaTelefonoController;
  late TextEditingController _observacionesController;

  @override
  void initState() {
    super.initState();
    _student = widget.student;
    _initControllers();
  }

  void _initControllers() {
    _nombreController = TextEditingController(text: _student.nombre);
    _apellidoController = TextEditingController(text: _student.apellido);
    _dniController = TextEditingController(text: _student.dni);
    _weightController = TextEditingController(text: _student.weightKg?.toString() ?? '');
    _heightController = TextEditingController(text: _student.heightCm?.toString() ?? '');
    _nombrePadreController = TextEditingController(text: _student.nombrePadre ?? '');
    _apellidoPadreController = TextEditingController(text: _student.apellidoPadre ?? '');
    _telefonoPadreController = TextEditingController(text: _student.telefonoPadre ?? '');
    _nombreMadreController = TextEditingController(text: _student.nombreMadre ?? '');
    _apellidoMadreController = TextEditingController(text: _student.apellidoMadre ?? '');
    _telefonoMadreController = TextEditingController(text: _student.telefonoMadre ?? '');
    _contactoEmergenciaNombreController = TextEditingController(text: _student.contactoEmergenciaNombre ?? '');
    _contactoEmergenciaApellidoController = TextEditingController(text: _student.contactoEmergenciaApellido ?? '');
    _contactoEmergenciaTelefonoController = TextEditingController(text: _student.contactoEmergenciaTelefono ?? '');
    _observacionesController = TextEditingController(text: _student.observaciones ?? '');
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _dniController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _nombrePadreController.dispose();
    _apellidoPadreController.dispose();
    _telefonoPadreController.dispose();
    _nombreMadreController.dispose();
    _apellidoMadreController.dispose();
    _telefonoMadreController.dispose();
    _contactoEmergenciaNombreController.dispose();
    _contactoEmergenciaApellidoController.dispose();
    _contactoEmergenciaTelefonoController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1000,
      );

      if (image != null) {
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String fileName = 'student_${_student.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final File savedImage = await File(image.path).copy('${appDir.path}/$fileName');

        setState(() {
          _student.photoPath = savedImage.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar foto: $e')),
        );
      }
    }
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _student.fechaNacimiento ?? DateTime.now().subtract(const Duration(days: 365 * 10)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _student.fechaNacimiento = picked;
      });
    }
  }

  Future<void> _saveAndExit() async {
    if (_nombreController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre es obligatorio')),
      );
      return;
    }

    if (_apellidoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El apellido es obligatorio')),
      );
      return;
    }

    if (_student.fechaNacimiento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La fecha de nacimiento es obligatoria')),
      );
      return;
    }

    // Actualizar datos del estudiante
    _student.nombre = _nombreController.text.trim();
    _student.apellido = _apellidoController.text.trim();
    _student.dni = _dniController.text.trim();
    _student.weightKg = double.tryParse(_weightController.text.trim());
    _student.heightCm = int.tryParse(_heightController.text.trim());
    _student.nombrePadre = _nombrePadreController.text.trim().isEmpty ? null : _nombrePadreController.text.trim();
    _student.apellidoPadre = _apellidoPadreController.text.trim().isEmpty ? null : _apellidoPadreController.text.trim();
    _student.telefonoPadre = _telefonoPadreController.text.trim().isEmpty ? null : _telefonoPadreController.text.trim();
    _student.nombreMadre = _nombreMadreController.text.trim().isEmpty ? null : _nombreMadreController.text.trim();
    _student.apellidoMadre = _apellidoMadreController.text.trim().isEmpty ? null : _apellidoMadreController.text.trim();
    _student.telefonoMadre = _telefonoMadreController.text.trim().isEmpty ? null : _telefonoMadreController.text.trim();
    _student.contactoEmergenciaNombre = _contactoEmergenciaNombreController.text.trim().isEmpty ? null : _contactoEmergenciaNombreController.text.trim();
    _student.contactoEmergenciaApellido = _contactoEmergenciaApellidoController.text.trim().isEmpty ? null : _contactoEmergenciaApellidoController.text.trim();
    _student.contactoEmergenciaTelefono = _contactoEmergenciaTelefonoController.text.trim().isEmpty ? null : _contactoEmergenciaTelefonoController.text.trim();
    _student.observaciones = _observacionesController.text.trim().isEmpty ? null : _observacionesController.text.trim();

    await _dbService.saveStudent(_student);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _showAddLesionDialog() {
    final TextEditingController lesionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Lesión'),
        content: TextField(
          controller: lesionController,
          decoration: const InputDecoration(
            labelText: 'Título de la lesión',
            hintText: 'Ej: NUDILLO',
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (lesionController.text.trim().isNotEmpty) {
                setState(() {
                  _student.agregarLesion(lesionController.text.trim().toUpperCase());
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return DateFormat('dd/MM/yyyy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = _student.photoPath != null && _student.photoPath!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(_student.nombreCompleto),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveAndExit,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: hasPhoto ? FileImage(File(_student.photoPath!)) : null,
                      child: !hasPhoto
                          ? const Icon(Icons.camera_alt, size: 40, color: Colors.grey)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Toca para cambiar foto',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),

            const SizedBox(height: 24),

            // Datos personales
            const Text(
              'DATOS PERSONALES',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(labelText: 'Nombre *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _apellidoController,
              decoration: const InputDecoration(labelText: 'Apellido *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dniController,
              decoration: const InputDecoration(labelText: 'DNI'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            
            // Fecha de nacimiento
            InkWell(
              onTap: _selectBirthDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fecha de Nacimiento *',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _student.fechaNacimiento != null
                      ? '${_formatDate(_student.fechaNacimiento!)} (${_student.edad} años)'
                      : 'Seleccionar fecha',
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    decoration: const InputDecoration(labelText: 'Peso (kg)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _heightController,
                    decoration: const InputDecoration(labelText: 'Altura (cm)'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ID y Fecha de inscripción (solo lectura)
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ID: ${_student.id}', style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                    const SizedBox(height: 4),
                    Text('Fecha de inscripción: ${_student.fechaInscripcion}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Datos del padre
            const Text(
              'DATOS DEL PADRE/TUTOR',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            TextField(
              controller: _nombrePadreController,
              decoration: const InputDecoration(labelText: 'Nombre del Padre'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _apellidoPadreController,
              decoration: const InputDecoration(labelText: 'Apellido del Padre'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _telefonoPadreController,
              decoration: const InputDecoration(labelText: 'Teléfono del Padre'),
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: 24),

            // Datos de la madre
            const Text(
              'DATOS DE LA MADRE/TUTOR',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            TextField(
              controller: _nombreMadreController,
              decoration: const InputDecoration(labelText: 'Nombre de la Madre'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _apellidoMadreController,
              decoration: const InputDecoration(labelText: 'Apellido de la Madre'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _telefonoMadreController,
              decoration: const InputDecoration(labelText: 'Teléfono de la Madre'),
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: 24),

            // Contacto de emergencia
            const Text(
              'CONTACTO DE EMERGENCIA',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            TextField(
              controller: _contactoEmergenciaNombreController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contactoEmergenciaApellidoController,
              decoration: const InputDecoration(labelText: 'Apellido'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contactoEmergenciaTelefonoController,
              decoration: const InputDecoration(labelText: 'Teléfono'),
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: 24),

            // Observaciones
            const Text(
              'OBSERVACIONES',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            TextField(
              controller: _observacionesController,
              decoration: const InputDecoration(
                hintText: 'Datos importantes, alergias, notas médicas, etc.',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),

            const SizedBox(height: 24),

            // Lesiones
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'HISTORIAL DE LESIONES',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.red),
                  onPressed: _showAddLesionDialog,
                ),
              ],
            ),
            const Divider(),
            
            if (_student.lesiones.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: Text('Sin lesiones registradas')),
              )
            else
              ..._student.lesiones.asMap().entries.map((entry) {
                final index = entry.key;
                final lesion = entry.value;
                return Card(
                  color: lesion.altaMedica ? Colors.green[50] : Colors.red[50],
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: Icon(
                      lesion.altaMedica ? Icons.check_circle : Icons.warning,
                      color: lesion.altaMedica ? Colors.green : Colors.red,
                    ),
                    title: Text(
                      lesion.titulo,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(_formatDate(lesion.fecha)),
                    trailing: lesion.altaMedica
                        ? const Chip(
                            label: Text('ALTA', style: TextStyle(fontSize: 10)),
                            backgroundColor: Colors.green,
                          )
                        : ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _student.marcarAltaMedica(index);
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: const Text('Marcar Alta'),
                          ),
                  ),
                );
              }).toList(),

            const SizedBox(height: 24),

            // Clases inscritas
            const Text(
              'CLASES INSCRITAS',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            
            if (_student.classIds.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: Text('No inscrito en ninguna clase')),
              )
            else
              ..._student.classIds.map((classId) {
                final schedule = _dbService.getSchedule(classId);
                if (schedule == null) return const SizedBox.shrink();

                final now = DateTime.now();
                final asistencias = _student.getAsistenciasPorClase(classId, now.month, now.year);
                final totalClases = schedule.calculateTotalClasses(now.month, now.year, _student.creationDate);

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(schedule.nombre),
                    subtitle: Text('Asistencias: $asistencias/$totalClases'),
                    trailing: Text(
                      '$asistencias/$totalClases',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),

            const SizedBox(height: 24),

            // Premios
            const Text(
              'MEDALLAS Y PREMIOS',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MedalCount(icon: Icons.emoji_events, color: Colors.amber, count: _student.medallas['oro'] ?? 0, label: 'Oro'),
                _MedalCount(icon: Icons.emoji_events, color: Colors.grey, count: _student.medallas['plata'] ?? 0, label: 'Plata'),
                _MedalCount(icon: Icons.emoji_events, color: Colors.brown, count: _student.medallas['bronce'] ?? 0, label: 'Bronce'),
                _MedalCount(icon: Icons.favorite, color: Colors.red, count: _student.medallas['corazon'] ?? 0, label: 'Corazón'),
              ],
            ),

            const SizedBox(height: 16),

            Card(
              color: Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Colors.orange, size: 32),
                    const SizedBox(width: 12),
                    Text(
                      '${_student.stars} Estrellas',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _MedalCount extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int count;
  final String label;

  const _MedalCount({
    required this.icon,
    required this.color,
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}