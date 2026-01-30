import 'package:flutter/material.dart';
import '../models/class_schedule.dart';
import '../services/database_service.dart';

const List<String> diasSemana = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

class ClassCreationScreen extends StatefulWidget {
  const ClassCreationScreen({super.key});
 
  @override
  State<ClassCreationScreen> createState() => _ClassCreationScreenState();
}

class _ClassCreationScreenState extends State<ClassCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _dbService = DatabaseService();
  bool _isSaving = false;

  // Controllers y valores
  final TextEditingController _disciplinaController = TextEditingController();
  final TextEditingController _horarioController = TextEditingController();
  String _categoriaSeleccionada = 'Adulto';
  final Set<int> _diasSeleccionados = {};

  void _toggleDay(int dayValue) {
    setState(() {
      if (_diasSeleccionados.contains(dayValue)) {
        _diasSeleccionados.remove(dayValue);
      } else {
        _diasSeleccionados.add(dayValue);
      }
    });
  }

  Future<void> _saveClass() async {
    if (_formKey.currentState!.validate()) {
      if (_diasSeleccionados.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debes seleccionar al menos un día de la semana')),
        );
        return;
      }

      setState(() => _isSaving = true);

      try {
        final newSchedule = ClassSchedule(
          disciplina: _disciplinaController.text.trim(),
          horario: _horarioController.text.trim(),
          categoria: _categoriaSeleccionada,
          diasDeSemana: _diasSeleccionados.toList()..sort(),
        );

        await _dbService.saveSchedule(newSchedule);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Clase "${newSchedule.nombre}" creada exitosamente')),
          );
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar la clase: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  @override
  void dispose() {
    _disciplinaController.dispose();
    _horarioController.dispose();
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Disciplina
            TextFormField(
              controller: _disciplinaController,
              decoration: const InputDecoration(
                labelText: 'Disciplina *',
                hintText: 'Ej: Kick Boxing, Muay Thai',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.sports_martial_arts),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'La disciplina es obligatoria';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Horario
            TextFormField(
              controller: _horarioController,
              decoration: const InputDecoration(
                labelText: 'Horario *',
                hintText: 'Ej: 17:15, 18:00',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.access_time),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El horario es obligatorio';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Categoría
            const Text(
              'Categoría *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Inicial', label: Text('Inicial')),
                ButtonSegment(value: 'Juvenil', label: Text('Juvenil')),
                ButtonSegment(value: 'Adulto', label: Text('Adulto')),
              ],
              selected: {_categoriaSeleccionada},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _categoriaSeleccionada = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 24),

            // Días de la semana
            const Text(
              'Días de Clase *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: diasSemana.length,
              itemBuilder: (context, index) {
                final dayValue = index + 1;
                final isSelected = _diasSeleccionados.contains(dayValue);
                return GestureDetector(
                  onTap: () => _toggleDay(dayValue),
                  child: Card(
                    elevation: isSelected ? 4 : 1,
                    color: isSelected ? colorScheme.primary : Colors.grey[200],
                    child: Center(
                      child: Text(
                        diasSemana[index],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Preview del nombre
            if (_disciplinaController.text.isNotEmpty && _horarioController.text.isNotEmpty)
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vista previa:',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_disciplinaController.text.trim()} - ${_horarioController.text.trim()} - $_categoriaSeleccionada',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_diasSeleccionados.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Días: ${(_diasSeleccionados.toList()..sort()).map((d) => diasSemana[d - 1]).join(', ')}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _saveClass,
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.save),
        label: Text(_isSaving ? 'Guardando...' : 'CREAR CLASE'),
        backgroundColor: _isSaving ? Colors.grey : colorScheme.primary,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}