import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../models/student.dart';
import '../services/database_service.dart';
import 'student_full_profile_screen.dart';

class AwardsScreen extends StatefulWidget {
  const AwardsScreen({super.key});

  @override
  State<AwardsScreen> createState() => _AwardsScreenState();
}

class _AwardsScreenState extends State<AwardsScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<Student> _participantes = [];
  List<Student> _podioOro = [];
  List<Student> _podioPlata = [];
  List<Student> _podioBronce = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPodio();
  }

  Future<void> _loadPodio() async {
    setState(() => _isLoading = true);

    try {
      final allStudents = await _dbService.getAllStudents();
      
      // Filtrar solo participantes (>= 1 estrella)
      final participantes = allStudents
          .where((s) => s.stars >= 1)
          .toList();

      // Ordenar por estrellas (descendente)
      participantes.sort((a, b) => b.stars.compareTo(a.stars));

      // Calcular podio con empates
      List<Student> oro = [];
      List<Student> plata = [];
      List<Student> bronce = [];

      if (participantes.isNotEmpty) {
        final maxStars = participantes.first.stars;
        
        // Oro: todos con el máximo de estrellas
        oro = participantes.where((s) => s.stars == maxStars).toList();
        
        // Plata: siguiente grupo después del oro
        final remaining = participantes.where((s) => s.stars < maxStars).toList();
        if (remaining.isNotEmpty) {
          final plataStars = remaining.first.stars;
          plata = remaining.where((s) => s.stars == plataStars).toList();
          
          // Bronce: siguiente grupo después de plata
          final remainingBronce = remaining.where((s) => s.stars < plataStars).toList();
          if (remainingBronce.isNotEmpty) {
            final bronceStars = remainingBronce.first.stars;
            bronce = remainingBronce.where((s) => s.stars == bronceStars).toList();
          }
        }
      }

      setState(() {
        _participantes = participantes;
        _podioOro = oro;
        _podioPlata = plata;
        _podioBronce = bronce;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar podio: $e')),
        );
      }
    }
  }

  void _navigateToProfile(Student student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentFullProfileScreen(student: student),
      ),
    ).then((_) => _loadPodio());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏆 Premios y Ranking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPodio,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _participantes.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emoji_events, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No hay participantes aún',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Los alumnos con 1+ estrellas aparecerán aquí',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPodio,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Podio
                      _buildPodio(),
                      const SizedBox(height: 32),

                      // Todos los participantes
                      const Text(
                        'Todos los Participantes',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const Divider(),
                      ..._participantes.asMap().entries.map((entry) {
                        final index = entry.key;
                        final student = entry.value;
                        return _buildParticipantTile(student, index + 1);
                      }),
                    ],
                  ),
                ),
    );
  }

  Widget _buildPodio() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              '🥇 PODIO ACTUAL 🥇',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Podio visual
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Plata (izquierda, más bajo)
                if (_podioPlata.isNotEmpty)
                  Expanded(
                    child: _buildPodioColumn(
                      _podioPlata,
                      'PLATA',
                      Colors.grey,
                      120,
                    ),
                  ),

                // Oro (centro, más alto)
                if (_podioOro.isNotEmpty)
                  Expanded(
                    child: _buildPodioColumn(
                      _podioOro,
                      'ORO',
                      Colors.amber,
                      160,
                    ),
                  ),

                // Bronce (derecha, más bajo)
                if (_podioBronce.isNotEmpty)
                  Expanded(
                    child: _buildPodioColumn(
                      _podioBronce,
                      'BRONCE',
                      Colors.brown,
                      100,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPodioColumn(List<Student> students, String label, Color color, double height) {
    return Column(
      children: [
        ...students.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: GestureDetector(
            onTap: () => _navigateToProfile(s),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: color,
                  backgroundImage: s.photoBytes != null
                      ? MemoryImage(Uint8List.fromList(s.photoBytes!))
                      : null,
                  child: s.photoBytes == null
                      ? Text(
                          s.nombre[0].toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 4),
                Text(
                  s.nombre,
                  style: const TextStyle(fontSize: 10),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '⭐ ${s.stars}',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        )),
        Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantTile(Student student, int position) {
    Color? medalColor;
    IconData? medalIcon;

    if (_podioOro.contains(student)) {
      medalColor = Colors.amber;
      medalIcon = Icons.emoji_events;
    } else if (_podioPlata.contains(student)) {
      medalColor = Colors.grey;
      medalIcon = Icons.emoji_events;
    } else if (_podioBronce.contains(student)) {
      medalColor = Colors.brown;
      medalIcon = Icons.emoji_events;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (medalIcon != null)
              Icon(medalIcon, color: medalColor, size: 24)
            else
              SizedBox(
                width: 24,
                child: Text(
                  '$position°',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 20,
              backgroundImage: student.photoBytes != null
                  ? MemoryImage(Uint8List.fromList(student.photoBytes!))
                  : null,
              child: student.photoBytes == null
                  ? Text(student.nombre[0].toUpperCase())
                  : null,
            ),
          ],
        ),
        title: Text(student.nombreCompleto),
        subtitle: Text('${student.edad} años • ${student.categoriaBusqueda}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, color: Colors.orange, size: 20),
            const SizedBox(width: 4),
            Text(
              '${student.stars}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        onTap: () => _navigateToProfile(student),
      ),
    );
  }
}