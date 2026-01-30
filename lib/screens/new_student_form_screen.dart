import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/student.dart';
import '../models/class_schedule.dart';
import '../services/database_service.dart';
import 'dart:typed_data';

class NewStudentFormScreen extends StatefulWidget {
  const NewStudentFormScreen({super.key});

  @override
  State<NewStudentFormScreen> createState() => _NewStudentFormScreenState();
}

class _NewStudentFormScreenState extends State<NewStudentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _dniController = TextEditingController();

  List<int>? _photoBytes;
  DateTime? _birthDate;
  List<ClassSchedule> _availableSchedules = [];
  Set<String> _selectedClassIds = {};

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    final schedules = DatabaseService().getAllSchedules();
    setState(() {
      _availableSchedules = schedules;
      _selectedClassIds = {};
    });
  }

Future<void> _pickImage() async {
  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

  if (image != null) {
    final bytes = await image.readAsBytes();
    setState(() {
      _photoBytes = bytes;
    });
  }
}
  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  Future<void> _saveStudent() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_birthDate == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La fecha de nacimiento es obligatoria')),
      );
      return;
    }

 final newStudent = Student(
  nombre: _nombreController.text.trim(),
  apellido: _apellidoController.text.trim(),
  dni: _dniController.text.trim(),
  fechaNacimiento: _birthDate,
  photoBytes: _photoBytes, // CAMBIADO
  classIds: _selectedClassIds.toList(),
  creationDate: DateTime.now(),
  isArchived: false,
  stars: 0,
  attendanceByClass: {},
);

    try {
      await DatabaseService().saveStudent(newStudent);
      if (!mounted) return;
      Navigator.of(context).pop(newStudent.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${newStudent.nombreCompleto} inscrito correctamente.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar alumno: $e')),
      );
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _dniController.dispose();
    super.dispose();
  }

Widget _buildPhotoPicker() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Foto del Alumno', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: _pickImage,
        icon: const Icon(Icons.camera_alt),
        label: Text(_photoBytes == null ? 'Seleccionar Foto de Galería' : 'Cambiar Foto'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
      if (_photoBytes != null)
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Center(
            child: CircleAvatar(
              radius: 50,
              backgroundImage: MemoryImage(Uint8List.fromList(_photoBytes!)),
            ),
          ),
        ),
    ],
  );
}

  Widget _buildClassSelection() {
    if (_availableSchedules.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Inscribir en Clases Iniciales', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Center(child: Text('No hay clases disponibles. Crea una clase primero.')),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Inscribir en Clases Iniciales', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          children: _availableSchedules.map((schedule) {
            return FilterChip(
              label: Text(schedule.nombre),
              selected: _selectedClassIds.contains(schedule.id),
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    _selectedClassIds.add(schedule.id);
                  } else {
                    _selectedClassIds.remove(schedule.id);
                  }
                });
              },
              showCheckmark: true,
              labelStyle: TextStyle(
                color: _selectedClassIds.contains(schedule.id) 
                    ? Theme.of(context).colorScheme.onPrimary 
                    : Theme.of(context).colorScheme.onSurface,
              ),
              selectedColor: Theme.of(context).colorScheme.primary,
              checkmarkColor: Theme.of(context).colorScheme.onPrimary,
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alta de Nuevo Alumno'),
        backgroundColor: colorScheme.errorContainer,
        foregroundColor: colorScheme.onErrorContainer,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: <Widget>[
            _buildPhotoPicker(),
            const Divider(height: 32),

            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre es obligatorio.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _apellidoController,
              decoration: const InputDecoration(
                labelText: 'Apellido *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El apellido es obligatorio.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _dniController,
              decoration: const InputDecoration(
                labelText: 'DNI',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            InkWell(
              onTap: _selectBirthDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fecha de Nacimiento *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _birthDate == null
                      ? 'Seleccionar fecha'
                      : DateFormat('dd/MM/yyyy').format(_birthDate!),
                ),
              ),
            ),

            const Divider(height: 32),

            _buildClassSelection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveStudent,
        icon: const Icon(Icons.save),
        label: const Text('INSCRIBIR ALUMNO'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}