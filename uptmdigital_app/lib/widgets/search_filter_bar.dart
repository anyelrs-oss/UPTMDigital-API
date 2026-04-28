import 'package:flutter/material.dart';
import 'package:uptmdigital_app/theme.dart';

/// Widget reutilizable: barra de búsqueda con chips de filtro.
/// Se usa en pantallas de listado (Estudiantes, Profesores, Asignaturas, Usuarios).
class SearchFilterBar extends StatelessWidget {
  final String hintText;
  final ValueChanged<String> onSearchChanged;
  final List<FilterChipData> filters;
  final Widget? trailing;

  const SearchFilterBar({
    super.key,
    this.hintText = "Buscar...",
    required this.onSearchChanged,
    this.filters = const [],
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
              suffixIcon: trailing,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        // Filter chips
        if (filters.isNotEmpty)
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = filters[index];
                return FilterChip(
                  label: Text(filter.label),
                  selected: filter.isSelected,
                  onSelected: filter.onSelected,
                  selectedColor: AppTheme.secondary.withOpacity(0.2),
                  checkmarkColor: AppTheme.primary,
                  labelStyle: TextStyle(
                    color: filter.isSelected ? AppTheme.primary : Colors.grey[700],
                    fontWeight: filter.isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: filter.isSelected ? AppTheme.primary : Colors.grey[300]!,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class FilterChipData {
  final String label;
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  const FilterChipData({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });
}
