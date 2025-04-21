import 'package:flutter/material.dart';
import 'fulldoc.dart';
import 'pagebypagedoc.dart';
import 'translation_history.dart'; // You'll need to create this new screen

class TranslationModeScreen extends StatelessWidget {
  const TranslationModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Translation Mode'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Full Document Translation Card
            _buildModeCard(
              context,
              icon: Icons.description,
              title: 'Full Document Translation',
              description: 'Translate the entire document at once',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FullDocumentTranslationScreen(),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Page-by-Page Translation Card
            _buildModeCard(
              context,
              icon: Icons.view_day,
              title: 'Page-by-Page Translation',
              description: 'Translate one page at a time with preview',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PdfTranslationScreen(),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Past Translations Card
            _buildModeCard(
              context,
              icon: Icons.history,
              title: 'Past Translations',
              description: 'View your previously translated documents',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TranslationHistoryScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String description,
        required VoidCallback onTap,
      }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 50,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}