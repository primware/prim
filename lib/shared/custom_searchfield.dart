import 'dart:async';
import 'package:flutter/material.dart';
import 'package:searchfield/searchfield.dart';

class CustomSearchField extends StatefulWidget {
  final List<Map<String, dynamic>> options;
  final String labelText, searchBy;
  final void Function(Map<String, dynamic>)? onItemSelected;
  final Future<List<Map<String, dynamic>>> Function(String)? onSearch;
  final Widget Function(Map<String, dynamic>)? itemBuilder;
  final bool enabled;
  final TextEditingController? controller;

  const CustomSearchField({
    super.key,
    required this.options,
    required this.labelText,
    this.controller,
    this.onItemSelected,
    this.searchBy = 'id',
    this.onSearch,
    this.itemBuilder,
    this.enabled = true,
  });

  @override
  State<CustomSearchField> createState() => _CustomSearchFieldState();
}

class _CustomSearchFieldState extends State<CustomSearchField> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<List<SearchFieldListItem<Map<String, dynamic>>>> _onSearchItems(
      String query) async {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    final completer =
        Completer<List<SearchFieldListItem<Map<String, dynamic>>>>();

    _debounce = Timer(const Duration(milliseconds: 0), () async {
      List<Map<String, dynamic>> results;
      if (widget.onSearch != null) {
        results = await widget.onSearch!(query);
      } else {
        results = widget.options.where((item) {
          final name = (item['name'] ?? '').toString().toLowerCase();
          final customField =
              (item[widget.searchBy] ?? '').toString().toLowerCase();
          return name.contains(query.toLowerCase()) ||
              customField.contains(query.toLowerCase());
        }).toList();
      }

      final suggestions = results.map((item) {
        return SearchFieldListItem<Map<String, dynamic>>(
          (item['name'] ?? '').toString(),
          item: item,
          child: widget.itemBuilder != null
              ? widget.itemBuilder!(item)
              : _defaultItemBuilder(item),
        );
      }).toList();

      completer.complete(suggestions);
    });

    return completer.future;
  }

  Widget _defaultItemBuilder(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${item[widget.searchBy] ?? ''} - ${item['name'] ?? ''} ',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            '\$${item['price'] ?? ''}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SearchField<Map<String, dynamic>>(
      controller: _controller,
      enabled: widget.enabled,
      onSuggestionTap: (SearchFieldListItem<Map<String, dynamic>> item) {
        if (widget.onItemSelected != null) {
          widget.onItemSelected!(item.item!);
        }
      },
      suggestions: widget.options.map((item) {
        return SearchFieldListItem<Map<String, dynamic>>(
          (item['name'] ?? '').toString(),
          item: item,
          child: widget.itemBuilder != null
              ? widget.itemBuilder!(item)
              : _defaultItemBuilder(item),
        );
      }).toList(),
      suggestionsDecoration: SuggestionDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
      ),
      searchInputDecoration: SearchInputDecoration(
        labelText: widget.labelText,
        labelStyle: Theme.of(context).textTheme.bodyMedium,
        contentPadding: const EdgeInsets.all(16),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      suggestionStyle: Theme.of(context).textTheme.bodyMedium,
      onSearchTextChanged: _onSearchItems,
      hint: 'Buscar por nombre o ${widget.searchBy}...',
    );
  }
}
