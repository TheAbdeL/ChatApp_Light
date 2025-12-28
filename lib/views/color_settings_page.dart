import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/color_provider.dart';
import '../utils/constants.dart';

class ColorSettingsPage extends StatelessWidget {
  const ColorSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Couleurs personnalisées'),
      ),
      body: Consumer<ColorProvider>(
        builder: (context, colorProvider, child) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choisissez votre couleur préférée',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: colorProvider.availableColors.length,
                    itemBuilder: (context, index) {
                      Color color = colorProvider.availableColors[index];
                      bool isSelected = color.value == colorProvider.primaryColor.value;

                      return GestureDetector(
                        onTap: () {
                          colorProvider.changeColor(color);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: isSelected
                              ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 40,
                          )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Aperçu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorProvider.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.chat, color: Colors.white, size: 32),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Aperçu de la couleur',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}