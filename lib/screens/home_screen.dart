import 'package:flutter/material.dart';
import 'students_master_screen.dart';
import 'classes_list_screen.dart';
import 'awards_screen.dart';
import 'competitors_screen.dart';
import '../services/database_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _dbService = DatabaseService();
  String _birthdayMessage = '';

  @override
  void initState() {
    super.initState();
    _checkBirthdays();
  }

  void _checkBirthdays() {
    final studentsWithBirthday = _dbService.getStudentsWithBirthdayTomorrow();
    if (studentsWithBirthday.isNotEmpty) {
      final names = studentsWithBirthday.map((s) => s.nombreCompleto).join(', ');
      setState(() {
        _birthdayMessage = '🎂 Cumpleaños mañana: $names';
      });
    }
  }

  void _navigateToStudents() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const StudentsMasterScreen()),
    );
  }

  void _navigateToClasses() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ClassesListScreen()),
    );
  }

  void _navigateToAwards() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AwardsScreen()),
    );
  }

  void _navigateToCompetitors() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CompetitorsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Dojo'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Mensaje de cumpleaños
          if (_birthdayMessage.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade300, width: 2),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cake, color: Colors.orange, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _birthdayMessage,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Grid de 4 cards principales
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                children: [
                  _DashboardCard(
                    icon: Icons.people,
                    title: '🎓 Gestionar\nAlumnos',
                    color: Colors.blue,
                    onTap: _navigateToStudents,
                  ),
                  _DashboardCard(
                    icon: Icons.calendar_month,
                    title: '📅 Horarios\ny Clases',
                    color: Colors.green,
                    onTap: _navigateToClasses,
                  ),
                  _DashboardCard(
                    icon: Icons.emoji_events,
                    title: '🏆 Premios\ny Ranking',
                    color: Colors.orange,
                    onTap: _navigateToAwards,
                  ),
                  _DashboardCard(
                    icon: Icons.sports_martial_arts,
                    title: '🥊 Competidores',
                    color: Colors.red,
                    onTap: _navigateToCompetitors,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.7),
                color,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 56.0, color: Colors.white),
              const SizedBox(height: 12.0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}