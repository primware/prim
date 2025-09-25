import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';

class SearchableDropdown<T> extends StatelessWidget {
  final String idKey;
  final String nameKey;
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
    this.idKey = 'id',
    this.nameKey = 'name',
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? _selected = (value == null)
        ? null
        : (() {
            final idx = options.indexWhere((item) => item[idKey] == value);
            if (idx == -1) return null;
            return options[idx];
          })();
    return DropdownSearch<Map<String, dynamic>>(
      enabled: isEnabled,
      selectedItem: _selected,
      items: (String filter, LoadProps? props) async {
        if (filter.isEmpty) {
          return options;
        } else {
          return options
              .where((item) => item[nameKey]
                  .toString()
                  .toLowerCase()
                  .contains(filter.toLowerCase()))
              .toList();
        }
      },
      itemAsString: (item) =>
          displayItem != null ? displayItem!(item) : item[nameKey],
      compareFn: (item, selectedItem) => item[idKey] == selectedItem?[idKey],
      dropdownBuilder: (context, selectedItem) {
        return Text(
          displayItem != null
              ? displayItem!(selectedItem ?? {})
              : selectedItem?[nameKey] ?? '',
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
              displayItem != null ? displayItem!(item) : item[nameKey],
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
      onChanged: (item) =>
          onChanged?.call(item == null ? null : item[idKey] as T?),
    );
  }
}

class DropdownCustom<T> extends StatelessWidget {
  final T? value;
  final List<Map<String, dynamic>> options;
  final String labelText;
  final void Function(T?)? onChanged;
  final bool isEnabled;
  final String Function(Map<String, dynamic>)? displayItem;

  const DropdownCustom({
    super.key,
    required this.value,
    required this.options,
    required this.labelText,
    required this.onChanged,
    this.isEnabled = true,
    this.displayItem,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      items: options.map((item) {
        final text = displayItem != null
            ? displayItem!(item)
            : (item['name'] ?? '').toString();
        final id = item['id'] as T?;
        return DropdownMenuItem<T>(
          value: id,
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: isEnabled ? onChanged : null,
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
      style: Theme.of(context).textTheme.bodyMedium,
      dropdownColor: Theme.of(context).cardColor,
    );
  }
}
