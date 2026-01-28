import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math';
// Nota: Se comentó la dependencia de 'intl' ya que no se usó en la lógica de la UI.
// import 'package:intl/intl.dart';

// --- MOCK DE MODELO Y SERVICIO ---
// NOTA IMPORTANTE: Como el modelo de Hive en lib/models/student.dart se modificó,
// este código asume que se ejecutará 'flutter packages pub run build_runner build --delete-conflicting-outputs'
// y que la clase Student importada tendrá la estructura solicitada (dni, fechaNacimiento, esCompetidor, edad, categoria).
// En la aplicación final, debes usar: import 'package:dojo_app/models/student.dart';
class Student {
  final String id;
  final String nombre;
  final String? photoPath;
  final String dni;
  final DateTime? fechaNacimiento;
  final bool esCompetidor;
  final int stars;
  final String classId; // Usado para simular filtros de clase si fuera necesario

  // Mock Getters (deberían venir del modelo real)
  int get edad {
    if (fechaNacimiento == null) return 0;
    var age = DateTime.now().year - fechaNacimiento!.year;
    if (DateTime.now().month < fechaNacimiento!.month || 
        (DateTime.now().month == fechaNacimiento!.month && DateTime.now().day < fechaNacimiento!.day)) {
      age--;
    }
    return age;
  }

  String get categoria {
    if (edad < 12) return "Inicial";
    if (edad >= 12 && edad <= 17) return "Juvenil";
    return "Adulto";
  }
  
  // Lógica de asistencia simulada para estadísticas
  int getAsistenciasPorClase(String classId, int month, int year) {
    // Simulación: si es el alumno S001, devolvemos un valor alto si estamos en un mes específico
    if (id == 'S001' && month == 1 && year == 2026) return 15;
    if (id == 'S003' && month == 1 && year == 2026) return 18;
    return Random().nextInt(20); // Random value otherwise
  }

  Student({
    required this.id,
    required this.nombre,
    this.photoPath,
    required this.dni,
    this.fechaNacimiento,
    this.esCompetidor = false,
    this.stars = 0,
    this.classId = '',
  });
}

// Lista de Alumnos Mockeados (Basado en la fecha actual: 2026-01-24)
final List<Student> _mockAllStudents = [
  Student(id: 'S001', nombre: 'Sofía Torres', dni: '12345678', fechaNacimiento: DateTime(2015, 5, 10), esCompetidor: true, stars: 5, classId: 'KICK1'), // Inicial, Competidora (10 años)
  Student(id: 'S002', nombre: 'Mateo Giménez', dni: '12345679', fechaNacimiento: DateTime(2010, 1, 15), esCompetidor: false, stars: 12, classId: 'MUAY1'), // Juvenil (16 años)
  Student(id: 'S003', nombre: 'Juan Perez', dni: '12345680', fechaNacimiento: DateTime(2000, 11, 20), esCompetidor: true, stars: 20, classId: 'KICK1'), // Adulto, Competidor (25 años)
  Student(id: 'S004', nombre: 'Luna Díaz', dni: '12345681', fechaNacimiento: DateTime(2018, 2, 1), esCompetidor: false, stars: 3, classId: 'KICK1'), // Inicial (8 años)
  Student(id: 'S005', nombre: 'Carlos Ruiz', dni: '12345682', fechaNacimiento: DateTime(2007, 7, 4), esCompetidor: false, stars: 8, classId: 'MUAY2'), // Juvenil (18 años, justo en el límite, depende de la hora, pero asumamos Adulto si es >= 18) -> 18 años, es Adulto
];
// --- FIN MOCK ---


class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  // Filtros de Categoría
  final List<String> _categories = ['Inicial', 'Juvenil', 'Adulto', 'Competidor'];
  String? _selectedFilter;

  // Lista de Alumnos (debería venir del DatabaseService)
  List<Student> _allStudents = [];
  List<Student> _filteredStudents = [];

  @override
  void initState() {
    super.initState();
    // SIMULACIÓN: Cargar datos
    _allStudents = _mockAllStudents;
    _applyFilter(_selectedFilter);
  }

  void _applyFilter(String? filter) {
    setState(() {
      _selectedFilter = filter;
      _filteredStudents = _allStudents.where((student) {
        // Si no hay filtro, mostrar todos
        if (filter == null) return true;

        switch (filter) {
          case 'Inicial':
            return student.categoria == 'Inicial';
          case 'Juvenil':
            return student.categoria == 'Juvenil';
          case 'Adulto':
            return student.categoria == 'Adulto';
          case 'Competidor':
            return student.esCompetidor;
          default:
            return true;
        }
      }).toList();
    });
  }

  // Widget para la Tarjeta de Alumno
  Widget _buildStudentCard(Student student) {
    final isCompetitor = student.esCompetidor;
    final categoria = student.categoria;
    final edad = student.edad;
    
    // Lógica de colores para la categoría
    Color categoriaColor;
    switch(categoria) {
      case 'Inicial':
        categoriaColor = Colors.green.shade700;
        break;
      case 'Juvenil':
        categoriaColor = Colors.orange.shade700;
        break;
      case 'Adulto':
        categoriaColor = Colors.red.shade700;
        break;
      default:
        categoriaColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      elevation: 2,
      child: ListTile(
        // 1. Foto (Avatar)
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: student.photoPath != null
              ? Image.file(File(student.photoPath!), fit: BoxFit.cover) // Asumiendo manejo de File
              : Icon(Icons.person, size: 30, color: Theme.of(context).colorScheme.onPrimaryContainer),
        ),
        
        title: Text(
          student.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        
        // Subtitle con información clave
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ID del alumno (texto pequeño)
            Text('ID: ${student.id}', style: const TextStyle(fontSize: 11.0)),
            
            // Chips de categoría/estado
            Wrap(
              spacing: 6.0,
              runSpacing: 2.0,
              children: [
                // Chip de Categoría
                _buildStatusChip(
                  label: '$categoria ($edad)',
                  backgroundColor: categoriaColor,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                // Chip de Competidor
                if (isCompetitor)
                  _buildStatusChip(
                    label: 'COMPETIDOR',
                    backgroundColor: Colors.purple.shade700,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
              ],
            ),
          ],
        ),
        
        // Navegación a detalle/edición
        onTap: () {
          // TODO: Navegar a student_edit_screen.dart con student.id
          print('Navegando a editar alumno ID: ${student.id}');
          // Ejemplo: Navigator.of(context).push(MaterialPageRoute(builder: (_) => StudentEditScreen(studentId: student.id)));
        },
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  Widget _buildStatusChip({required String label, required Color backgroundColor, required Color foregroundColor}) {
    return Chip(
      label: Text(label),
      labelStyle: TextStyle(fontSize: 10, color: foregroundColor, fontWeight: FontWeight.bold),
      backgroundColor: backgroundColor,
      elevation: 1,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: -4),
    );
  }

  // Widget para los Chips de Filtro
  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 4.0,
        children: [
          // Chip para limpiar filtro
          ChoiceChip(
            label: const Text('Todos'),
            selected: _selectedFilter == null,
            onSelected: (selected) {
              if (selected) _applyFilter(null);
            },
            labelStyle: TextStyle(color: _selectedFilter == null ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onPrimaryContainer),
            selectedColor: Theme.of(context).colorScheme.primary,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          
          // Filtros por Categoría
          ..._categories.map((category) => ChoiceChip(
            label: Text(category),
            selected: _selectedFilter == category,
            onSelected: (selected) {
              if (selected) {
                _applyFilter(category);
              } else if (_selectedFilter == category) {
                _applyFilter(null); // Deseleccionar si es el mismo
              }
            },
            labelStyle: TextStyle(color: _selectedFilter == category ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface),
            selectedColor: Theme.of(context).colorScheme.primary,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Alumnos'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Abrir búsqueda por nombre/DNI
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              // TODO: Navegar a crear nuevo alumno (new_student_form_screen.dart)
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          _buildFilterChips(),
          Expanded(
            child: _filteredStudents.isEmpty
                ? Center(
                    child: Text(
                      _selectedFilter == null
                          ? 'No hay alumnos registrados.'
                          : 'No hay alumnos en la categoría "$_selectedFilter".',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = _filteredStudents[index];
                      return _buildStudentCard(student);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
// NOTA: Para que este código funcione, debe estar envuelto en un MaterialApp/Scaffold y se requiere
// importar la librería 'intl' en pubspec.yaml para el formateo de fechas (si se usa), y la clase Student
// debe ser importada desde lib/models/student.dart en lugar de la definición mockeada.
// Además, se requiere el paquete 'file_picker' o similar para manejar student.photoPath si se carga desde el disco.
// Importaciones necesarias que DEBES verificar en tu proyecto:
// import 'package:dojo_app/models/student.dart';
// import 'dart:io'; // Para File
// import 'package:intl/intl.dart'; // Para formateo
// import 'package:provider/provider.dart'; // Si se usa manejo de estado
// Si no usas 'intl', puedes remover el formateo de fechas o reemplazarlo con lógica simple.
