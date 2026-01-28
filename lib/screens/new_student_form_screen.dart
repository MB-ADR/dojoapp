import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dojo_app/models/student.dart';
import 'package:dojo_app/models/class_schedule.dart';
import 'package:dojo_app/services/database_service.dart';

class NewStudentFormScreen extends StatefulWidget {
  const NewStudentFormScreen({super.key});

  @override
  State<NewStudentFormScreen> createState() => _NewStudentFormScreenState();
}

class _NewStudentFormScreenState extends State<NewStudentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _dniController = TextEditingController();
  final TextEditingController _edadController = TextEditingController();
  final TextEditingController _padreNombreController = TextEditingController();
  final TextEditingController _padreTelController = TextEditingController();
  final TextEditingController _madreNombreController = TextEditingController();
  final TextEditingController _madreTelController = TextEditingController();

  String? _photoPath;
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

  void _calculateBirthDateFromAge(int age) {
    if (age <= 0 || age > 100) {
      _birthDate = null;
      return;
    }
    final now = DateTime.now();
    _birthDate = DateTime(now.year - age);
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _photoPath = image.path;
      });
    }
  }

  Future<void> _saveStudent() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    
    final int age = int.tryParse(_edadController.text) ?? 0;
    _calculateBirthDateFromAge(age);

    if (_birthDate == null && age > 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al procesar la edad.')),
      );
      return;
    }

    final newStudent = Student(
  nombre: _nombreController.text,
  apellido: '', // Lo agregarás en el formulario
  dni: _dniController.text.trim(),
  fechaNacimiento: _birthDate,
  nombrePadre: _padreNombreController.text.trim(),
  apellidoPadre: '', // Agregar campo
  telefonoPadre: _padreTelController.text.trim(),
  nombreMadre: _madreNombreController.text.isEmpty ? null : _madreNombreController.text.trim(),
  apellidoMadre: '', // Agregar campo
  telefonoMadre: _madreTelController.text.isEmpty ? null : _madreTelController.text.trim(),
  photoPath: _photoPath,
  classIds: _selectedClassIds.toList(),
  creationDate: DateTime.now(),
  isArchived: false,
  stars: 0,
  attendanceByClass: {},
);

    try {
      await DatabaseService().saveStudent(newStudent);
      if (!mounted) return;
      if (mounted && Navigator.canPop(context)) {
          Navigator.of(context).pop(newStudent.id);
      } else {
          Navigator.of(context).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${newStudent.nombre} inscrito correctamente.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar alumno: $e')),
      );
    }
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
          label: Text(_photoPath == null ? 'Tomar Foto / Seleccionar de Galería' : 'Cambiar Foto'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        if (_photoPath != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.file(
                File(_photoPath!),
                height: 100,
                width: 100,
                fit: BoxFit.cover,
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
          const Center(child: CircularProgressIndicator()),
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
                color: _selectedClassIds.contains(schedule.id) ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
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
                labelText: 'Nombre Completo *',
                border: OutlineInputBorder(),
                icon: Icon(Icons.person),
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
              controller: _dniController,
              decoration: const InputDecoration(
                labelText: 'DNI',
                border: OutlineInputBorder(),
                icon: Icon(Icons.badge),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _edadController,
              decoration: const InputDecoration(
                labelText: 'Edad *',
                border: OutlineInputBorder(),
                icon: Icon(Icons.cake),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'La edad es obligatoria.';
                }
                if (int.tryParse(value.trim()) == null || int.parse(value.trim()) <= 0) {
                  return 'Ingrese una edad válida.';
                }
                return null;
              },
              onChanged: (value) {
                if (value.isNotEmpty) {
                  _calculateBirthDateFromAge(int.tryParse(value.trim()) ?? 0);
                } else {
                  _calculateBirthDateFromAge(0);
                }
              },
            ),
            const Divider(height: 32),

            TextFormField(
              controller: _padreNombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre de Padre/Madre *',
                border: OutlineInputBorder(),
                icon: Icon(Icons.male),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Debe ingresar el nombre de un tutor.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _padreTelController,
              decoration: const InputDecoration(
                labelText: 'Teléfono de Contacto Principal *',
                border: OutlineInputBorder(),
                icon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El teléfono de contacto es obligatorio.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _madreNombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre de Madre/Otro Tutor (Opcional)',
                border: OutlineInputBorder(),
                icon: Icon(Icons.female),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _madreTelController,
              decoration: const InputDecoration(
                labelText: 'Teléfono de Contacto Secundario (Opcional)',
                border: OutlineInputBorder(),
                icon: Icon(Icons.phone_android),
              ),
              keyboardType: TextInputType.phone,
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