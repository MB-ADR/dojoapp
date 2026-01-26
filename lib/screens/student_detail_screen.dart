import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/student.dart';
import '../models/class_schedule.dart';
import '../services/database_service.dart';
 
class StudentDetailScreen extends StatefulWidget {
  final Student? student;
  final ClassSchedule? schedule;

  const StudentDetailScreen({
    super.key,
    required this.student,
    this.schedule,
  });
 
  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}
 
class _StudentDetailScreenState extends State<StudentDetailScreen> {
  final DatabaseService _dbService = DatabaseService();
  late Student _student;
  
  late TextEditingController _nombreController;
  late TextEditingController _dniController;
  late TextEditingController _weightKgController;
  late TextEditingController _heightCmController;
  late TextEditingController _padreNombreController;
  late TextEditingController _padreTelController;
  late TextEditingController _madreNombreController;
  late TextEditingController _madreTelController;
  late TextEditingController _obsController;
  DateTime? _fechaNacimiento; // Variable local corregida
 
  @override
  void initState() {
    super.initState();
    
    if (widget.student == null) {
      // CORRECCIÓN: dni es obligatorio, inicializamos vacío
      _student = Student(
        nombre: 'ALUMNO NUEVO TEMPORAL', 
        dni: '', 
        isArchived: false
      );
    } else {
      _student = widget.student!;
    }
 
    _nombreController = TextEditingController(text: _student.nombre);
    _dniController = TextEditingController(text: _student.dni);
    _weightKgController = TextEditingController(text: _student.weightKg?.toString() ?? '');
    _heightCmController = TextEditingController(text: _student.heightCm?.toString() ?? '');
    _padreNombreController = TextEditingController(text: _student.padreNombre ?? '');
    _padreTelController = TextEditingController(text: _student.padreTel ?? '');
    _madreNombreController = TextEditingController(text: _student.madreNombre ?? '');
    _madreTelController = TextEditingController(text: _student.madreTel ?? '');
    _obsController = TextEditingController(text: _student.observaciones ?? '');
    
    // CORRECCIÓN: Usar fechaNacimiento del modelo
    _fechaNacimiento = _student.fechaNacimiento;
  }
 
  @override
  void dispose() {
    _nombreController.dispose();
    _dniController.dispose();
    _weightKgController.dispose();
    _heightCmController.dispose();
    _padreNombreController.dispose();
    _padreTelController.dispose();
    _madreNombreController.dispose();
    _madreTelController.dispose();
    _obsController.dispose();
    super.dispose();
  }
 
  Future<void> _tomarFoto() async {
    if (_student.isArchived) return;
    
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? foto = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1000,
      );
 
      if (foto == null) return;
 
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String fileName = 'student_${_student.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final File savedImage = await File(foto.path).copy('${appDir.path}/$fileName');
 
      setState(() {
        _student.photoPath = savedImage.path;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar/guardar foto: $e')),
        );
      }
    }
  }
  
  Future<void> _selectDate(BuildContext context) async {
    if (_student.isArchived) return;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _fechaNacimiento) {
      setState(() {
        _fechaNacimiento = picked;
      });
    }
  }
 
  Future<void> _guardarYSalir() async {
    if (_nombreController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre es obligatorio')),
      );
      return;
    }
    if (_fechaNacimiento == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La fecha de nacimiento es obligatoria.')),
      );
      return;
    }
 
    _student.nombre = _nombreController.text.trim();
    // CORRECCIÓN: dni ahora es String no nullable
    _student.dni = _dniController.text.trim();
    
    // CORRECCIÓN: Asignar a fechaNacimiento
    _student.fechaNacimiento = _fechaNacimiento;
    
    _student.weightKg = double.tryParse(_weightKgController.text.trim());
    _student.heightCm = int.tryParse(_heightCmController.text.trim());
    _student.padreNombre = _padreNombreController.text.isEmpty ? null : _padreNombreController.text;
    _student.padreTel = _padreTelController.text.isEmpty ? null : _padreTelController.text;
    _student.madreNombre = _madreNombreController.text.isEmpty ? null : _madreNombreController.text;
    _student.madreTel = _madreTelController.text.trim().isEmpty ? null : _madreTelController.text;
    _student.observaciones = _obsController.text.isEmpty ? null : _obsController.text;
 
    await _dbService.saveStudent(_student);
 
    if (mounted) Navigator.pop(context, _student);
  }
 
  Future<void> _toggleArchivar() async {
    final esArchivado = _student.isArchived;
    final accion = esArchivado ? 'RE-ACTIVAR' : 'ARCHIVAR';
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$accion Alumno'),
        content: Text('¿Estás seguro de que deseas ${accion.toLowerCase()} a ${_student.nombre}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(accion, style: TextStyle(color: esArchivado ? Colors.green : Colors.red)),
          ),
        ],
      ),
    );
 
    if (confirm == true) {
      _student.isArchived = !esArchivado;
      await _dbService.saveStudent(_student);
      setState(() {});
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Alumno ${esArchivado ? 'reactivado' : 'archivado'} correctamente')),
        );
      }
    }
  }
 
  void _marcarAsistencia() async {
    if (_student.isArchived) return;
 
    if (widget.schedule == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No se identificó la clase para marcar asistencia.')),
      );
      return;
    }
 
    if (!widget.schedule!.esHoyDiaDeClase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hoy no es día de clase para este horario.')),
      );
      return;
    }
 
    setState(() {
      _student.toggleAsistenciaHoy(widget.schedule!.id);
    });
    
    await _dbService.saveStudent(_student);
  }
 
  void _cambiarEstrellas(int delta) {
    if (_student.isArchived) return;
    setState(() {
      int nuevas = _student.stars + delta;
      if (nuevas < 0) nuevas = 0;
      _student.stars = nuevas;
    });
    _dbService.saveStudent(_student);
  }
 
  // Helpers
  String _formatearFecha(DateTime dt) => DateFormat('dd/MM/yyyy').format(dt);
  
  String _mesActual(int month) {
    const meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    if (month < 1 || month > 12) return '-';
    return meses[month - 1];
  }
 
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final colorScheme = Theme.of(context).colorScheme;
    
    final String currentClassId = widget.schedule?.id ?? (_student.classIds.isNotEmpty ? _student.classIds.first : '');

    final int asistencias = currentClassId.isNotEmpty
        ? _student.getAsistenciasPorClase(currentClassId, now.month, now.year)
        : 0;
        
    final bool presenteHoy = currentClassId.isNotEmpty 
        ? _student.fuePresenteHoy(currentClassId)
        : false;
 
    final int totalClases = currentClassId.isNotEmpty 
        ? (widget.schedule?.calculateTotalClasses(now.month, now.year, _student.creationDate) ?? 0)
        : 0;
 
    final bool esDiaClase = currentClassId.isNotEmpty ? widget.schedule?.esHoyDiaDeClase() ?? false : false;
    final bool modoLectura = _student.isArchived;
 
    final List<String> historialDeEstaClase = _student.attendanceByClass[currentClassId] ?? [];
    
    final bool canInteractWithAttendance = widget.schedule != null && !modoLectura;
 
    return Scaffold(
      appBar: AppBar(
        title: Text(modoLectura ? '${_student.nombre} (Archivado)' : 'Perfil de ${_student.nombre}'),
        actions: [
          IconButton(
            icon: Icon(modoLectura ? Icons.restore_from_trash : Icons.archive, color: modoLectura ? Colors.green : Colors.red),
            onPressed: _toggleArchivar,
          ),
          if (!modoLectura)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _guardarYSalir,
            )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _tomarFoto,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _student.photoPath != null 
                        ? FileImage(File(_student.photoPath!)) as ImageProvider 
                        : null,
                    child: _student.photoPath == null 
                        ? const Icon(Icons.camera_alt, size: 40, color: Colors.grey) 
                        : null,
                  ),
                  if (!modoLectura)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, color: Colors.white, size: 20),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (!modoLectura) const Text('Toca para cambiar foto', style: TextStyle(color: Colors.grey, fontSize: 12)),
            
            const SizedBox(height: 24),
 
            // NOMBRE
            _buildTextField(
              controller: _nombreController,
              enabled: !modoLectura,
              label: 'Nombre y Apellido',
              prefixIcon: const Icon(Icons.person),
              border: const OutlineInputBorder(),
            ),
            const SizedBox(height: 20),
            
            // DNI, PESO, ALTURA, FECHA NACIMIENTO
            _buildDniField(enabled: !modoLectura),
            const SizedBox(height: 12),
            _buildBirthDateSelector(context, _fechaNacimiento, _selectDate, modoLectura, colorScheme),
            const SizedBox(height: 12),
            _buildStatsFields(
                enabled: !modoLectura, 
                weightController: _weightKgController, 
                heightController: _heightCmController
            ),
            const SizedBox(height: 20),
            
            _buildDatosParentales('PADRE', _padreNombreController, _padreTelController, modoLectura),
            const SizedBox(height: 16),
            _buildDatosParentales('MADRE', _madreNombreController, _madreTelController, modoLectura),
 
            const SizedBox(height: 20),
            _buildTextField(
              controller: _obsController,
              maxLines: 3,
              enabled: !modoLectura,
              label: 'Observaciones',
              border: const OutlineInputBorder(),
            ),
 
            const Divider(height: 40),
 
            // ASISTENCIA (Solo visible si hay horario asignado)
            if (widget.schedule != null)
              Card(
                color: esDiaClase ? (presenteHoy ? Colors.green[50] : Colors.blue[50]) : Colors.grey[100],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text('Asistencias (${widget.schedule!.nombre}) - ${_mesActual(now.month)}', 
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text('$asistencias / $totalClases', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                          ElevatedButton.icon(
                            onPressed: (esDiaClase && canInteractWithAttendance) ? _marcarAsistencia : null,
                            icon: Icon(presenteHoy ? Icons.cancel : Icons.check_circle),
                            label: Text(
                              !esDiaClase ? 'SIN CLASE' : (presenteHoy ? 'ANULAR' : 'PRESENTE')
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: presenteHoy ? Colors.red : Colors.green,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey,
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
 
            const SizedBox(height: 20),
 
            // ESTRELLAS
            Card(
              color: Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('Estrellas (Méritos)', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!modoLectura)
                          IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => _cambiarEstrellas(-1)),
                        const SizedBox(width: 20),
                        Text('${_student.stars}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.orange)),
                        const SizedBox(width: 20),
                        if (!modoLectura)
                          IconButton(icon: const Icon(Icons.add_circle, color: Colors.green), onPressed: () => _cambiarEstrellas(1)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      children: List.generate(
                        _student.stars > 15 ? 15 : _student.stars, 
                        (index) => const Icon(Icons.star, color: Colors.orange, size: 20)
                      ) + (_student.stars > 15 ? [const Icon(Icons.add, size: 16)] : []),
                    )
                  ],
                ),
              ),
            ),
 
            const SizedBox(height: 20),
            
            // HISTORIAL (Solo fechas de esta clase)
            if (historialDeEstaClase.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Historial en ${widget.schedule?.nombre ?? 'Clase'}:', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  // Invertimos para ver las más recientes primero y tomamos 5
                  ...historialDeEstaClase.reversed.take(5).map((dateStr) => 
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.history, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(_formatearFecha(DateTime.parse(dateStr))),
                        ],
                      ),
                    )
                  ),
                ],
              ),
              
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
 
  Widget _buildDatosParentales(String titulo, TextEditingController ctrlNombre, TextEditingController ctrlTel, bool disabled) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text('DATOS $titulo', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            _buildTextField(
              controller: ctrlNombre,
              enabled: !disabled,
              label: 'Nombre $titulo',
              prefixIcon: const Icon(Icons.person),
              border: const OutlineInputBorder(),
            ),
            const SizedBox(height: 8),
            _buildTextField(
              controller: ctrlTel,
              enabled: !disabled,
              keyboardType: TextInputType.phone,
              label: 'Teléfono $titulo',
              prefixIcon: const Icon(Icons.phone),
              border: const OutlineInputBorder(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDniField({required bool enabled}) {
    return _buildTextField(
      controller: _dniController,
      label: 'DNI / Documento',
      keyboardType: TextInputType.number,
      enabled: enabled,
    );
  }
  
  Widget _buildBirthDateSelector(BuildContext context, DateTime? date, Future<void> Function(BuildContext) onTap, bool disabled, ColorScheme colorScheme) {
    return InkWell(
      onTap: disabled ? null : () => onTap(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Fecha de Nacimiento (*)',
          border: const OutlineInputBorder(),
          suffixIcon: Icon(Icons.calendar_today, color: disabled ? Colors.grey : colorScheme.primary),
          enabled: !disabled,
        ),
        child: Text(
          date == null
              ? 'Seleccionar fecha'
              : DateFormat('dd/MM/yyyy').format(date),
          style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyLarge!.color),
        ),
      ),
    );
  }
 
  Widget _buildStatsFields({required bool enabled, required TextEditingController weightController, required TextEditingController heightController}) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _buildTextField(
              controller: weightController,
              label: 'Peso (Kg)',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              enabled: enabled,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: _buildTextField(
              controller: heightController,
              label: 'Altura (Cm)',
              keyboardType: TextInputType.number,
              enabled: enabled,
            ),
          ),
        ),
      ],
    );
  }
 
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool enabled = true,
    Widget? prefixIcon,
    OutlineInputBorder? border,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: prefixIcon,
          border: border ?? const OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator ?? (value) => null,
      ),
    );
  }
}