import 'dart:async';
import 'package:flutter/material.dart';
import 'package:searchfield/searchfield.dart';

import 'custom_spacer.dart';

class CustomSearchField extends StatefulWidget {
  final List<Map<String, dynamic>> options;
  final String labelText, searchBy;
  final String? searchByText;
  final void Function(Map<String, dynamic>)? onItemSelected;
  final Future<List<Map<String, dynamic>>> Function(String)? onSearch;
  final Widget Function(Map<String, dynamic>)? itemBuilder;
  final bool enabled;
  final TextEditingController? controller;
  final bool showCreateButtonIfNotFound;
  final void Function(String)? onCreate;
  final void Function(String)? onChanged;

  const CustomSearchField({
    super.key,
    required this.options,
    required this.labelText,
    this.controller,
    this.onItemSelected,
    this.searchBy = 'id',
    this.searchByText,
    this.onSearch,
    this.itemBuilder,
    this.enabled = true,
    this.showCreateButtonIfNotFound = false,
    this.onCreate,
    this.onChanged,
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
    _controller.removeListener(_handleTextChange);
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleTextChange);
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

      if (suggestions.isEmpty && widget.showCreateButtonIfNotFound) {
        suggestions.add(
          SearchFieldListItem<Map<String, dynamic>>(
            _controller.text,
            item: {},
            child: GestureDetector(
              onTap: () {
                if (widget.onCreate != null) {
                  widget.onCreate!(_controller.text);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add_circle_outline,
                        color: Colors.blueAccent),
                    const SizedBox(width: CustomSpacer.small),
                    Center(
                      child: Text(
                        'Crear ${widget.labelText} "${_controller.text}"',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.blueAccent,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      completer.complete(suggestions);
    });

    return completer.future;
  }

  Widget _defaultItemBuilder(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      child: Text(
        '${item['name'] ?? ''}',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  void _handleTextChange() {
    if (widget.onChanged != null) {
      widget.onChanged!(_controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SearchField<Map<String, dynamic>>(
      controller: _controller,
      enabled: widget.enabled,
      onSuggestionTap: (SearchFieldListItem<Map<String, dynamic>> item) {
        if (widget.onItemSelected != null && item.item!.isNotEmpty) {
          widget.onItemSelected!(item.item!);
          _controller.text = item.searchKey;
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
        hoverColor: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        selectionColor: Theme.of(context).cardColor,
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
      hint: 'Buscar por nombre o ${widget.searchByText ?? widget.searchBy}...',
    );
  }
}
