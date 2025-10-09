import 'package:flutter/material.dart';
import '../config/unique_themes.dart';

/// Селектор уникальных тем
class UniqueThemeSelector extends StatelessWidget {
  final String currentPalette;
  final ValueChanged<String> onPaletteChanged;

  const UniqueThemeSelector({
    super.key,
    required this.currentPalette,
    required this.onPaletteChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: UniqueQuikxThemes.colorPalettes.length,
        itemBuilder: (context, index) {
          final paletteName = UniqueQuikxThemes.colorPalettes.keys.elementAt(index);
          final colors = UniqueQuikxThemes.colorPalettes[paletteName]!;
          final isSelected = paletteName == currentPalette;

          return GestureDetector(
            onTap: () => onPaletteChanged(paletteName),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors),
                borderRadius: BorderRadius.circular(16),
                border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
              ),
              child: Center(
                child: Text(
                  paletteName.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
