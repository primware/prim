import 'dart:async';
import 'package:flutter/material.dart';
import 'package:primware/shared/custom_container.dart';
import '../../../shared/custom_app_menu.dart';
import '../../../shared/custom_spacer.dart';
import '../../../shared/shimmer_list.dart';
import '../../../shared/custom_textfield.dart';
import '../dashboard/dashboard_view.dart';
import '../invoice/invoice_funtions.dart';
import 'bpartner_details.dart';
import 'bpartner_new.dart';

class BPartnerListPage extends StatefulWidget {
  const BPartnerListPage({super.key});

  @override
  State<BPartnerListPage> createState() => _BPartnerListPageState();
}

class _BPartnerListPageState extends State<BPartnerListPage> {
  List<Map<String, dynamic>> _bpartners = [];
  bool _isLoading = true;
  bool isSearchLoading = false;
  // ignore: prefer_final_fields
  String _searchQuery = '';
  TextEditingController searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchBPartners();
  }

  Future<void> _fetchBPartners() async {
    setState(() => _isLoading = true);
    final result = await fetchBPartner(context: context);
    setState(() {
      _bpartners = result;
      _isLoading = false;
    });
  }

  void debouncedLoadBPartner() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    final searchText = searchController.text.trim();
    if (searchText.length < 3 && searchText.isNotEmpty) {
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 800), () {
      _loadBPartner(showLoadingIndicator: true);
    });
  }

  Future<void> _loadBPartner({bool showLoadingIndicator = false}) async {
    if (showLoadingIndicator) {
      setState(() {
        isSearchLoading = true;
      });
    }
    final partners = await fetchBPartner(
      context: context,
      searchTerm: searchController.text.trim(),
    );
    setState(() {
      _bpartners = partners;
      isSearchLoading = false;
    });
  }

  List<Map<String, dynamic>> _getFilteredPartners() {
    return _bpartners
        .where((bp) => bp['name']
            .toString()
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  Widget _buildPartnerList(List<Map<String, dynamic>> records) {
    return Column(
      children: records.map((record) {
        return GestureDetector(
          onTap: () async {
            final refreshed = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BPartnerDetailPage(bpartner: record),
              ),
            );
            if (refreshed == true) {
              debouncedLoadBPartner();
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              title: Text(record['name'],
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.secondary)),
              subtitle: Text(
                  '${record['LCO_TaxIdTypeName']} ${record['TaxID'] ?? ''}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.secondary)),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardPage()),
        );
        return Future.value(false);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Clientes')),
        drawer: MenuDrawer(),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const BPartnerNewPage(),
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
        body: SingleChildScrollView(
          child: Center(
            child: CustomContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isSearchLoading) ...[
                    const SizedBox(height: 4),
                    const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: TextfieldTheme(
                          texto: 'Buscar cliente',
                          controlador: searchController,
                          icono: Icons.search,
                          onChanged: (_) => debouncedLoadBPartner(),
                        ),
                      ),
                      const SizedBox(width: CustomSpacer.small),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _fetchBPartners,
                      ),
                    ],
                  ),
                  const SizedBox(height: CustomSpacer.medium),
                  _isLoading
                      ? ShimmerList(separation: CustomSpacer.medium)
                      : _buildPartnerList(_getFilteredPartners()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
