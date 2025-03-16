import 'package:flutter/material.dart';
import 'package:navithesia_beta/constants/app_constants.dart';
import 'package:navithesia_beta/screens/admin/database_editor_screen.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Tools')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Database Management', style: AppTextStyles.headline3),
            const SizedBox(height: 16),
            _buildAdminCard(
              context: context,
              title: 'Clinical Experience Database Editor',
              description:
                  'Add, edit, or remove surgical cases in the clinical experience database.',
              icon: Icons.edit_document,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DatabaseEditorScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),
            Text('App Settings', style: AppTextStyles.headline3),
            const SizedBox(height: 16),
            _buildAdminCard(
              context: context,
              title: 'Reset App Data',
              description:
                  'Warning: This will clear all user data and reset the app to its initial state.',
              icon: Icons.refresh,
              isDestructive: true,
              onTap: () {
                _showResetConfirmation(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      color: isDestructive ? Colors.red.shade50 : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                icon,
                size: 32,
                color: isDestructive ? Colors.red : AppColors.primaryColor,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                          isDestructive
                              ? AppTextStyles.subtitle1.copyWith(
                                color: Colors.red,
                              )
                              : AppTextStyles.subtitle1,
                    ),
                    const SizedBox(height: 4),
                    Text(description, style: AppTextStyles.bodyText2),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isDestructive ? Colors.red.shade300 : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Reset App Data?'),
            content: const Text(
              'This will permanently delete all your data including cases, time entries, and settings. This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  // TODO: Implement the reset functionality
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('App data has been reset')),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Reset'),
              ),
            ],
          ),
    );
  }
}
