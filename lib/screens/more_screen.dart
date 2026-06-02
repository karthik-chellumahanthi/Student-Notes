import 'package:flutter/material.dart';
import 'history_screen.dart';
import 'calculators/calculators_menu_screen.dart';
import 'calculators/scientific_calculator_screen.dart';
import 'calculators/attendance_calculator_screen.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  // Define available sections
  final List<MoreOption> _options = [
    MoreOption(
      id: 0,
      title: 'History',
      icon: Icons.history,
      color: Colors.blue,
      isAvailable: true,
    ),
    MoreOption(
      id: 1,
      title: 'Calculators',
      icon: Icons.calculate,
      color: Colors.orange,
      isAvailable: true,
    ),
    MoreOption(
      id: 4,
      title: 'Scientific Calculator',
      imageAsset: 'assets/images/casio_icon.png',
      color: Colors.blueGrey,
      isAvailable: true,
    ),
    MoreOption(
      id: 5,
      title: 'Attendance Tracker',
      icon: Icons.checklist_rtl,
      color: Colors.teal,
      isAvailable: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'More Options',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: _options
                  .map((option) => _buildOptionBox(option, context))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionBox(MoreOption option, BuildContext context) {
    final isEnabled = option.isAvailable;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled
            ? () {
                _navigateToOption(context, option);
              }
            : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: isEnabled ? option.color : Colors.grey[300],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[300]!, width: 1),
            boxShadow: [
              BoxShadow(
                color: option.color.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (option.imageAsset != null)
                ColorFiltered(
                  colorFilter: const ColorFilter.matrix([
                    0,
                    0,
                    0,
                    0,
                    255,
                    0,
                    0,
                    0,
                    0,
                    255,
                    0,
                    0,
                    0,
                    0,
                    255,
                    0.33,
                    0.33,
                    0.33,
                    0,
                    0,
                  ]),
                  child: Image.asset(
                    option.imageAsset!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.contain,
                  ),
                )
              else if (option.icon != null)
                Icon(option.icon, size: 48, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                option.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToOption(BuildContext context, MoreOption option) {
    Widget targetScreen;

    switch (option.id) {
      case 0:
        targetScreen = const HistoryScreen();
        break;
      case 1:
        targetScreen = const CalculatorsMenuScreen();
        break;
      case 4:
        targetScreen = const ScientificCalculatorScreen();
        break;
      case 5:
        targetScreen = const AttendanceCalculatorScreen();
        break;
      default:
        targetScreen = const Center(child: Text("Unknown Option"));
    }

    if (option.id == 1 || option.id == 4 || option.id == 5) {
      // Screens that have their own app bar, so we just push directly
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => targetScreen),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(option.title),
            backgroundColor: option.color,
            elevation: 0,
          ),
          body: targetScreen,
        ),
      ),
    );
  }
}

class MoreOption {
  final int id;
  final String title;
  final IconData? icon;
  final String? imageAsset;
  final Color color;
  final bool isAvailable;

  MoreOption({
    required this.id,
    required this.title,
    this.icon,
    this.imageAsset,
    required this.color,
    this.isAvailable = true,
  });
}
