import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart'; // <--- ESTO ES LO QUE FALTABA

// Tus modelos y adaptadores
import 'models/student.dart';
import 'models/class_schedule.dart';
import 'theme/app_theme.dart';
// import 'screens/schedule_management_screen.dart'; // Ya no es necesario importar directamente aquí, ya que HomeScreen navega a él
import 'screens/home_screen.dart'; // IMPORTAR LA NUEVA HOME SCREEN
// Sigue siendo necesario para la navegación interna
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. PRIMERO: Inicializar Hive y registrar los "traductores" (Adapters)
  await Hive.initFlutter();
  Hive.registerAdapter(ClassScheduleAdapter());
  Hive.registerAdapter(StudentAdapter());
  
  // 2. SEGUNDO: Ahora sí podemos abrir la base de datos
  final dbService = DatabaseService();
  await dbService.initialize();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Lógica de horario inicial
  ClassSchedule initialSchedule;
  final allSchedules = dbService.getAllSchedules();

  if (allSchedules.isNotEmpty) {
    initialSchedule = allSchedules.first;
  } else {
    initialSchedule = ClassSchedule(
      nombre: 'Horario Principal',
      diasDeSemana: [1, 2, 3, 4, 5], 
      fechasCanceladas: [],
    );
    await dbService.saveSchedule(initialSchedule);
  }

  runApp(DojoApp(dbService: dbService, initialSchedule: initialSchedule));
}

class DojoApp extends StatelessWidget {
  final DatabaseService dbService;
  final ClassSchedule initialSchedule;

  const DojoApp({
    super.key,
    required this.dbService,
    required this.initialSchedule,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestión Dojo',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: HomeScreen(), // CAMBIADO: Ahora apunta a HomeScreen
    );
  }
}
