import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Modelos y adaptadores
import 'models/student.dart';
import 'models/class_schedule.dart';
import 'models/payment_record.dart';
import 'models/notification_event.dart';
import 'models/lesion.dart'; // NUEVO
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Hive
  await Hive.initFlutter();
  
  // Registrar adaptadores
  Hive.registerAdapter(ClassScheduleAdapter());
  Hive.registerAdapter(StudentAdapter());
  Hive.registerAdapter(PaymentRecordAdapter());
  Hive.registerAdapter(NotificationEventAdapter());
  Hive.registerAdapter(LesionAdapter()); // NUEVO
  
  // Inicializar base de datos
  final dbService = DatabaseService();
  await dbService.initialize();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const DojoApp());
}

class DojoApp extends StatelessWidget {
  const DojoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestión Dojo',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}