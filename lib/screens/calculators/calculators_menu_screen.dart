import 'package:flutter/material.dart';
import 'cgpa_calculator_screen.dart';
import 'sgpa_calculator_screen.dart';
import 'percentage_calculator_screen.dart';
import 'calculator_history_screen.dart';

class CalculatorsMenuScreen extends StatelessWidget {
  const CalculatorsMenuScreen({super.key});

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculators'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildMenuCard(
              context,
              title: 'CGPA Calculator',
              subtitle: 'Calculate overall CGPA from semester SGPAs',
              icon: Icons.calculate,
              color: Colors.blue,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CgpaCalculatorScreen()),
              ),
            ),
            _buildMenuCard(
              context,
              title: 'SGPA Calculator',
              subtitle: 'Calculate SGPA from subject grades',
              icon: Icons.functions,
              color: Colors.green,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SgpaCalculatorScreen()),
              ),
            ),
            _buildMenuCard(
              context,
              title: 'Percentage Calculator',
              subtitle: 'Convert CGPA to Percentage (JNTUK Standard)',
              icon: Icons.percent,
              color: Colors.purple,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PercentageCalculatorScreen(),
                ),
              ),
            ),
            _buildMenuCard(
              context,
              title: 'History',
              subtitle: 'View your past calculations',
              icon: Icons.history,
              color: Colors.orange,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const CalculatorHistoryScreen(category: 'Academic'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
