import 'package:flutter/material.dart';
import '../models/class_schedule.dart';
import '../services/database_service.dart';

class ClassCreationScreen extends StatefulWidget {
  const ClassCreationScreen({super.key});

  @override
  State<ClassCreationScreen> createState() => _ClassCreationScreenState();
}

class _ClassCreationScreenState extends State<ClassCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();
  bool _isSaving = false;

  void _saveClass() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      final className = _nameController.text.trim();
      
      try {
        // 1. Crear el modelo con solo el nombre. DiasDeSemana y StudentIds serán vacíos por defecto.
        final newSchedule = ClassSchedule(nombre: className);
        
        // 2. Guardar en la base de datos
        await _dbService.saveSchedule(newSchedule);

        // 3. Notificar éxito y volver a la lista
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Clase "$className" creada exitosamente.')),
          );
          Navigator.of(context).pop(true); // Usamos 'true' para indicar que hubo un cambio y forzar refresh
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar la clase: $e')),
          );
        }
        print('Error saving class: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Nueva Clase'),
        backgroundColor: colorScheme.primaryContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la Clase',
                  hintText: 'Ej: Muay Thai Principiantes 18:00',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre de la clase no puede estar vacío.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              // Placeholder para añadir días de semana, que se manejará después
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Días de Semana'),
                subtitle: const Text('Configuración avanzada pendiente (Todo #4.1)'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Configuración de días pendiente.')),
                  );
                },
              ),
              
              const Spacer(),

              ElevatedButton(
                onPressed: _isSaving ? null : _saveClass,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50), // Botón ancho
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Guardar Clase', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}