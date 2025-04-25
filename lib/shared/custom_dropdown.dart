import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/fonts.dart';

class SearchableDropdown<T> extends StatelessWidget {
  final T? value;
  final List<Map<String, dynamic>> options;
  final String labelText;
  final void Function(T?)? onChanged;
  final bool isEnabled;

  const SearchableDropdown({
    super.key,
    required this.value,
    required this.options,
    required this.labelText,
    required this.onChanged,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownSearch<Map<String, dynamic>>(
      enabled: isEnabled,
      selectedItem: options.firstWhere(
        (item) => item['id'] == value,
        orElse: () => {},
      ),
      items: (String filter, LoadProps? props) async {
        if (filter.isEmpty) {
          return options;
        } else {
          return options
              .where((item) => item['name']
                  .toString()
                  .toLowerCase()
                  .contains(filter.toLowerCase()))
              .toList();
        }
      },
      itemAsString: (item) => item['name'],
      compareFn: (item, selectedValue) => item['id'] == selectedValue,
      dropdownBuilder: (context, selectedItem) {
        return Text(
          selectedItem?['name'] ?? '',
          style: FontsTheme.h5(),
        );
      },
      decoratorProps: DropDownDecoratorProps(
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: FontsTheme.h5(),
          contentPadding: const EdgeInsets.all(16),
          filled: true,
          fillColor: ColorTheme.textDark,
          border: OutlineInputBorder(
            borderSide: BorderSide(color: ColorTheme.accentLight),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      popupProps: const PopupProps.menu(
        showSearchBox: true,
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            hintText: "Buscar...",
            contentPadding: EdgeInsets.all(12),
          ),
        ),
      ),
      onChanged: (item) => onChanged?.call(item?['id']),
    );
  }
}
