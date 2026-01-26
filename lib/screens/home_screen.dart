import 'package:flutter/material.dart';
import 'package:dojo_app/models/class_schedule.dart'; // Importar el modelo necesario
import 'classes_list_screen.dart'; // NUEVA IMPORTACIÓN

// Clase para representar una pantalla de placeholder simple
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Contenido para $title (Placeholder)',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  // CONSTRUCTOR NO CONSTANTE para permitir inicialización de campos no constantes
  HomeScreen({super.key}); 

  // Función dummy para el callback onSave, ya que no queremos persistir nada todavía.
  void _dummyOnSave(ClassSchedule schedule) {
    // En un entorno real, esto guardaría los datos.
    debugPrint('Schedule data received (mock save): ${schedule.nombre}');
  }

  // Instancia dummy de ClassSchedule para satisfacer el constructor.
  final ClassSchedule _dummySchedule = ClassSchedule(
    nombre: "Horarios Generales",
    diasDeSemana: [1, 2, 3, 4, 5], // Lunes a Viernes como default
    fechasCanceladas: [],
    studentIds: [],
  );

  
  void _navigateToClassesList(BuildContext context) {
    // Navega a la nueva lista de clases.
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ClassesListScreen(),
      ),
    );
  }

  void _showPlaceholder(BuildContext context, String title) {
    // Navega a una pantalla de placeholder
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => PlaceholderScreen(title: title)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Usamos GridView.count para un layout de tarjetas grande y bonito.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Dojo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          children: <Widget>[
            _DashboardButton(
              icon: Icons.people,
              title: '🎓 Gestionar Alumnos',
              onTap: () => _showPlaceholder(context, 'Gestionar Alumnos'), // Usa lambda para pasar context
            ),
            _DashboardButton(
              icon: Icons.calendar_month,
              title: '📅 Horarios y Clases',
              onTap: () => _navigateToClassesList(context), // CAMBIADO: Ahora apunta a ClassesListScreen
            ),
            _DashboardButton(
              icon: Icons.emoji_events, // Ícono corregido
              title: '🏆 Ranking / Podio',
              onTap: () => _showPlaceholder(context, 'Ranking / Podio'), // Usa lambda para pasar context
            ),
          ],
        ),
      ),
    );
  }
}

// Helper Widget para mantener la UI limpia y usar const
class _DashboardButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap; // Espera un VoidCallback (sin argumentos)

  const _DashboardButton({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: onTap, 
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, size: 48.0, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8.0),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}