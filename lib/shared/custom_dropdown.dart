import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import '../theme/fonts.dart';

class SearchableDropdown<T> extends StatelessWidget {
  final T? value;
  final List<Map<String, dynamic>> options;
  final String labelText;
  final void Function(T?)? onChanged;
  final bool isEnabled, showSearchBox;
  final String Function(Map<String, dynamic>)? displayItem;

  final void Function(String)? onCreate;

  const SearchableDropdown({
    super.key,
    required this.value,
    required this.options,
    required this.labelText,
    required this.onChanged,
    this.isEnabled = true,
    this.onCreate,
    this.displayItem,
    this.showSearchBox = true,
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
      itemAsString: (item) =>
          displayItem != null ? displayItem!(item) : item['name'],
      compareFn: (item, selectedValue) => item['id'] == selectedValue,
      dropdownBuilder: (context, selectedItem) {
        return Text(
          displayItem != null
              ? displayItem!(selectedItem ?? {})
              : selectedItem?['name'] ?? '',
          style: Theme.of(context).textTheme.bodyMedium,
        );
      },
      decoratorProps: DropDownDecoratorProps(
        baseStyle: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: Theme.of(context).textTheme.bodyMedium,
          contentPadding: const EdgeInsets.all(16),
          filled: true,
          fillColor: Theme.of(context).cardColor,
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).primaryColor),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      popupProps: PopupProps.menu(
        showSearchBox: showSearchBox,
        emptyBuilder: (context, searchEntry) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$labelText no encontrado',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (onCreate != null && searchEntry.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    onPressed: () {
                      onCreate!(searchEntry);
                    },
                    child: Text('Crear "$searchEntry"'),
                  ),
                ]
              ],
            ),
          );
        },
        itemBuilder: (context, item, isDisabled, isSelected) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              displayItem != null ? displayItem!(item) : item['name'],
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        },
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            hintText: "Buscar...",
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ),
      onChanged: (item) => onChanged?.call(item?['id']),
    );
  }
}
