import 'package:flutter/material.dart';

class CompetitorsScreen extends StatelessWidget {
  const CompetitorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Competidores')),
      body: const Center(
        child: Text(
          'Gestión de Competidores\n(Próximamente)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}