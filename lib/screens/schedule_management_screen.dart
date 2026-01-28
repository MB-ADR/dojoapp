import 'package:flutter/material.dart';
import '../models/class_schedule.dart';
import 'package:table_calendar/table_calendar.dart';

const List<String> diasSemana = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

class ScheduleManagementScreen extends StatefulWidget {
  final ClassSchedule schedule;
  final Function(ClassSchedule) onSave;

  const ScheduleManagementScreen({
    super.key,
    required this.schedule,
    required this.onSave,
  });

  @override
  State<ScheduleManagementScreen> createState() => _ScheduleManagementScreenState();
}

class _ScheduleManagementScreenState extends State<ScheduleManagementScreen> {
  late ClassSchedule _schedule;
  late List<DateTime> _localCancelledDatesDateTime;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _schedule = ClassSchedule(
      id: widget.schedule.id,
      disciplina: widget.schedule.disciplina,
      horario: widget.schedule.horario,
      categoria: widget.schedule.categoria,
      diasDeSemana: List<int>.from(widget.schedule.diasDeSemana),
      fechasCanceladas: List<String>.from(widget.schedule.fechasCanceladas),
    );
    
    _localCancelledDatesDateTime = _schedule.fechasCanceladas
        .map((dateStr) => DateTime.parse(dateStr))
        .toList();
  }

  void _toggleDayOfWeek(int dayIndex) {
    final dayValue = dayIndex + 1;
    setState(() {
      if (_schedule.diasDeSemana.contains(dayValue)) {
        _schedule.diasDeSemana.remove(dayValue);
      } else {
        _schedule.diasDeSemana.add(dayValue);
      }
      _schedule.diasDeSemana.sort();
    });
  }

  void _toggleCancelledDate(DateTime date) {
    setState(() {
      if (_localCancelledDatesDateTime.any((d) => d.isAtSameMomentAs(date))) {
        _localCancelledDatesDateTime.removeWhere((d) => d.isAtSameMomentAs(date));
        _schedule.removeCancelledDate(date);
      } else {
        _localCancelledDatesDateTime.add(date);
        _schedule.addCancelledDate(date);
      }
      _localCancelledDatesDateTime.sort((a, b) => a.compareTo(b));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar Clase'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              widget.onSave(_schedule);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _schedule.nombre,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Disciplina: ${_schedule.disciplina}'),
                    Text('Horario: ${_schedule.horario}'),
                    Text('Categoría: ${_schedule.categoria}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            const Text(
              'Días de Clase Programados',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.5,
              ),
              itemCount: diasSemana.length,
              itemBuilder: (context, index) {
                final dayValue = index + 1;
                final isSelected = _schedule.diasDeSemana.contains(dayValue);
                return GestureDetector(
                  onTap: () => _toggleDayOfWeek(index),
                  child: Card(
                    color: isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
                    child: Center(
                      child: Text(
                        diasSemana[index],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            const Text(
              'Gestionar Feriados/Cancelaciones',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () => setState(
                    () => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1),
                  ),
                ),
                Text(
                  '${_mesNombre(_selectedMonth.month)} ${_selectedMonth.year}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed: () => setState(
                    () => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Card(
              child: TableCalendar<DateTime>(
                firstDay: DateTime(2020),
                lastDay: DateTime(2030),
                focusedDay: _selectedMonth,
                calendarFormat: CalendarFormat.month,
                selectedDayPredicate: (day) {
                  return _localCancelledDatesDateTime.any((d) => d.isAtSameMomentAs(day));
                },
                onDaySelected: (selectedDay, focusedDay) => _toggleCancelledDate(selectedDay),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                calendarStyle: CalendarStyle(
                  selectedDecoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Colors.blue[300],
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (_localCancelledDatesDateTime.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fechas Canceladas',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ..._localCancelledDatesDateTime.map((date) {
                        return ListTile(
                          dense: true,
                          title: Text(_formatearFecha(date)),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => _toggleCancelledDate(date),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resumen',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Días activos: ${_schedule.diasDeSemana.isEmpty ? 'Ninguno' : _schedule.diasDeSemana.map((i) => diasSemana[i - 1]).join(", ")}',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total clases ${_mesNombre(_selectedMonth.month)}: ${_schedule.calculateTotalClasses(_selectedMonth.month, _selectedMonth.year, null)}',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _mesNombre(int month) {
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return meses[month - 1];
  }

  String _formatearFecha(DateTime dt) {
    return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
  }
}