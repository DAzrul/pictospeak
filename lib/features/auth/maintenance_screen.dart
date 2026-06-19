import 'package:flutter/material.dart';

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.indigo,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.build_circle_rounded, size: 120, color: Colors.amber),
              SizedBox(height: 30),
              Text(
                "SISTEM SEDANG DISELENGGARA",
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 15),
              Text(
                "SuperAdmin sedang mengemaskini sistem untuk pengalaman yang lebih baik. Sila cuba sebentar lagi.",
                style: TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}