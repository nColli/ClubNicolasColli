import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Espacios', style: textTheme.titleMedium),
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.fieldBorder),
          ),
          child: Text(
            'Panel Central',
            style: textTheme.headlineMedium?.copyWith(
              color: AppColors.neonYellow,
            ),
          ),
        ),
      ),
    );
  }
}