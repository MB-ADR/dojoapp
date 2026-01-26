import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dojo_app/models/student.dart';
import 'package:dojo_app/services/database_service.dart';
import 'package:dojo_app/screens/student_detail_screen.dart';
import 'package:dojo_app/screens/new_student_form_screen.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final DatabaseService _dbService = DatabaseService();
  
   // Filtros de Categoría y Búsqueda
  final List<String> _ageCategories = ['Inicial', 'Juvenil', 'Adulto'];
  final List<String> _competitorTags = ['Competidor', 'No Competidor'];
  String? _selectedCategoryFilter;
  String? _selectedCompetitorFilter;

  // Listas de Alumnos
  List<Student> _allStudents = [];
  List<Student> _filteredStudents = [];
  bool _isLoading = true;
  
  get _selectedFilter => null;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    final students = await _dbService.getAllStudents();
    
    if (mounted) {
      setState(() {
        // Ordenar alfabéticamente por nombre por defecto
        students.sort((a, b) => a.nombre.compareTo(b.nombre));
        _allStudents = students;
        _isLoading = false;
        _applyFilters(_selectedFilter);
      });
    }
  }

   void _applyFilters([String? ignore]) {
     setState(() {
       _filteredStudents = _allStudents.where((student) {
         // 1. Filtrar por Categoría de Edad
         final ageMatch = _selectedCategoryFilter == null ||
                          student.categoriaBusqueda == _selectedCategoryFilter;
         
         // 2. Filtrar por Competidor/No Competidor
         bool competitorMatch;
         if (_selectedCompetitorFilter == null) {
           competitorMatch = true;
         } else if (_selectedCompetitorFilter == 'Competidor') {
           competitorMatch = student.searchableTags.contains('Competidor');
         } else { // 'No Competidor'
           competitorMatch = student.searchableTags.contains('No Competidor');
         }

         // 3. Filtrar por Tags (Añadir lógica de búsqueda de tags si es necesario,
         // por ahora solo implementamos los filtros solicitados)
         
         return ageMatch && competitorMatch;
       }).toList();
       
       // Asegurarse de que si no hay filtros aplicados, se muestren todos
       if (_selectedCategoryFilter == null && _selectedCompetitorFilter == null) {
         _filteredStudents = List.from(_allStudents);
       }
     });
   }

  // Navegación para crear alumno
  void _navToCreateStudent() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NewStudentFormScreen()),
    );
    // Al volver, recargamos la lista
    _loadStudents();
  }

  // Navegación para editar/ver alumno
  void _navToStudentDetail(Student student) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentDetailScreen(student: student),
      ),
    );
    // Al volver, recargamos la lista por si hubo cambios
    _loadStudents();
  }

   Widget _buildStudentCard(Student student) {
     final bool isCompetitorTag = student.searchableTags.contains('Competidor');
     final categoria = student.categoriaBusqueda; // Usa el nuevo getter
     final edad = student.edad;
     final bool hasPhoto = student.photoPath != null && student.photoPath!.isNotEmpty;
     
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

     // Obtener otras etiquetas de búsqueda (excluyendo las de estado)
     final otherTags = student.searchableTags
        .where((tag) => tag != 'Competidor' && tag != 'No Competidor')
        .toList();
     
     return Card(
       margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
       elevation: 2,
       child: ListTile(
         leading: CircleAvatar(
           radius: 25,
           backgroundColor: Theme.of(context).colorScheme.primaryContainer,
           backgroundImage: hasPhoto ? FileImage(File(student.photoPath!)) : null,
           child: !hasPhoto
               ? Icon(Icons.person, size: 25, color: Theme.of(context).colorScheme.onPrimaryContainer)
               : null,
         ),
         
         title: Text(
           student.nombre,
           style: const TextStyle(fontWeight: FontWeight.bold),
         ),
         
         subtitle: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             if (student.dni.isNotEmpty)
               Text('DNI: ${student.dni}', style: const TextStyle(fontSize: 11.0)),
             
             const SizedBox(height: 4),
             Wrap(
               spacing: 6.0,
               runSpacing: 2.0,
               children: [
                 _buildStatusChip(
                   label: '$categoria ($edad)',
                   backgroundColor: categoriaColor,
                   foregroundColor: Colors.white,
                 ),
                 if (isCompetitorTag)
                   _buildStatusChip(
                     label: 'COMPETIDOR',
                     backgroundColor: Colors.purple.shade700,
                     foregroundColor: Colors.white,
                   ),
                 if (student.isArchived)
                   _buildStatusChip(
                     label: 'ARCHIVADO',
                     backgroundColor: Colors.grey,
                     foregroundColor: Colors.white,
                   ),
                 // Mostrar etiquetas de búsqueda personalizadas aquí (si las hay)
                 ...otherTags.map((tag) => _buildStatusChip(
                       label: tag.toUpperCase(),
                       backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                       foregroundColor: Theme.of(context).colorScheme.onTertiaryContainer,
                     )),
               ],
             ),
           ],
         ),
         
         onTap: () => _navToStudentDetail(student),
         trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
       ),
     );
   }

  Widget _buildStatusChip({required String label, required Color backgroundColor, required Color foregroundColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: foregroundColor, fontWeight: FontWeight.bold),
      ),
    );
  }

   Widget _buildFilterChips() {
     return Padding(
       padding: const EdgeInsets.all(8.0),
       child: SingleChildScrollView(
         scrollDirection: Axis.horizontal,
         child: Row(
           children: [
             // Botón para resetear todos los filtros
             Padding(
               padding: const EdgeInsets.only(right: 8.0),
               child: FilterChip(
                 label: const Text('Todos'),
                 selected: _selectedCategoryFilter == null && _selectedCompetitorFilter == null,
                 onSelected: (selected) {
                   _selectedCategoryFilter = null;
                   _selectedCompetitorFilter = null;
                   _applyFilters(null);
                 },
               ),
             ),
             
             // Filtros de Categoría de Edad
             ..._ageCategories.map((category) => Padding(
               padding: const EdgeInsets.only(right: 8.0),
               child: FilterChip(
                 label: Text(category),
                 selected: _selectedCategoryFilter == category,
                 onSelected: (selected) {
                   _selectedCategoryFilter = selected ? category : null;
                   _applyFilters(null);
                 },
                 selectedColor: Theme.of(context).colorScheme.primaryContainer,
               ),
             )),
             
             // Separador visual (opcional, para agrupar)
             const Padding(
               padding: EdgeInsets.only(left: 16.0, right: 8.0),
               child: VerticalDivider(thickness: 1, indent: 10, endIndent: 10),
             ),

             // Filtros de Competidor
             ..._competitorTags.map((tag) => Padding(
               padding: const EdgeInsets.only(right: 8.0),
               child: FilterChip(
                 label: Text(tag.toUpperCase()),
                 selected: _selectedCompetitorFilter == tag,
                 onSelected: (selected) {
                   _selectedCompetitorFilter = selected ? tag : null;
                   _applyFilters(null);
                 },
                 selectedColor: Theme.of(context).colorScheme.secondaryContainer,
               ),
             )),

             // TODO: Implementar un campo de búsqueda de texto libre para `searchableTags`
           ],
         ),
       ),
     );
   }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Alumnos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStudents,
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _navToCreateStudent,
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          _buildFilterChips(),
          Expanded(
             child: _isLoading
               ? const Center(child: CircularProgressIndicator())
               : _filteredStudents.isEmpty
                   ? Center(
                       child: Text(
                         (_selectedCategoryFilter == null && _selectedCompetitorFilter == null)
                             ? 'No hay alumnos registrados.'
                             : 'No se encontraron alumnos con los filtros aplicados.',
                         style: TextStyle(color: Colors.grey[600]),
                       ),
                     )
                   : ListView.builder(
                      itemCount: _filteredStudents.length,
                      itemBuilder: (context, index) {
                        return _buildStudentCard(_filteredStudents[index]);
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navToCreateStudent,
        child: const Icon(Icons.add),
      ),
    );
  }
}