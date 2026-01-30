import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/student.dart';
import '../services/database_service.dart';
import 'student_full_profile_screen.dart';
import 'new_student_form_screen.dart';

class StudentsMasterScreen extends StatefulWidget {
  const StudentsMasterScreen({super.key});

  @override
  State<StudentsMasterScreen> createState() => _StudentsMasterScreenState();
}

class _StudentsMasterScreenState extends State<StudentsMasterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // ignore: unused_field
  final DatabaseService _dbService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigateToNewStudent() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NewStudentFormScreen()),
    );
    // Si se creó un alumno, refrescar la pantalla
    if (result != null) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Alumnos'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'INICIAL'),
            Tab(text: 'JUVENIL'),
            Tab(text: 'ADULTO'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {}); // Forzar rebuild de todas las tabs
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _navigateToNewStudent,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        // Corrección aplicada: Se eliminó 'const' aquí para permitir widgets con estado
        children: [
          _StudentCategoryList(categoria: 'Inicial'),
          _StudentCategoryList(categoria: 'Juvenil'),
          _StudentCategoryList(categoria: 'Adulto'),
        ],
      ),
    );
  }
}

class _StudentCategoryList extends StatefulWidget {
  final String categoria;

  const _StudentCategoryList({required this.categoria});

  @override
  State<_StudentCategoryList> createState() => _StudentCategoryListState();
}

class _StudentCategoryListState extends State<_StudentCategoryList>
    with AutomaticKeepAliveClientMixin {
  final DatabaseService _dbService = DatabaseService();
  List<Student> _students = [];
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void didUpdateWidget(_StudentCategoryList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recargar si cambia la configuración del widget padre
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    final students = await _dbService.getStudentsByCategoria(widget.categoria);
    // Ordenar alfabéticamente
    students.sort((a, b) => a.nombreCompleto.compareTo(b.nombreCompleto));
    if (mounted) {
      setState(() {
        _students = students;
        _isLoading = false;
      });
    }
  }

  void _navigateToProfile(Student student) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentFullProfileScreen(student: student),
      ),
    );
    _loadStudents(); // Refrescar después de editar/ver perfil
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Necesario para AutomaticKeepAliveClientMixin

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Estructura principal: Header + Lista (o mensaje de vacío)
    return Column(
      children: [
        // Header de categoría
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Categoría ${widget.categoria}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              Text(
                '${_students.length} alumno${_students.length != 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),

        // Lista de alumnos o Mensaje de vacío
        Expanded(
          child: _students.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No hay alumnos en categoría ${widget.categoria}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _students.length,
                  itemBuilder: (context, index) {
                    final student = _students[index];
                    return _StudentTile(
                      student: student,
                      onTap: () => _navigateToProfile(student),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _StudentTile extends StatelessWidget {
  final Student student;
  final VoidCallback onTap;

  const _StudentTile({
    required this.student,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        student.photoBytes != null && student.photoBytes!.isNotEmpty;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          backgroundImage: hasPhoto
              ? MemoryImage(Uint8List.fromList(student.photoBytes!))
              : null,
          child: !hasPhoto
              ? Text(
                  student.nombre.isNotEmpty ? student.nombre[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                )
              : null,
        ),
        title: Text(
          student.nombreCompleto,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${student.edad} años • ${student.categoriaBusqueda}'),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.star, size: 14, color: Colors.orange),
                const SizedBox(width: 4),
                Text('${student.stars} estrellas'),
                const SizedBox(width: 12),
                const Icon(Icons.emoji_events, size: 14, color: Colors.amber),
                const SizedBox(width: 4),
                Text('${student.totalMedallas} medallas'),
              ],
            ),
            if (student.tieneLesionesPendientes)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.warning, size: 14, color: Colors.red[700]),
                    const SizedBox(width: 4),
                    Text(
                      'Lesión pendiente',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}