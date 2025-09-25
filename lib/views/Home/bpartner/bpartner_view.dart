import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:primware/shared/custom_container.dart';
import '../../../shared/custom_app_menu.dart';
import '../../../shared/custom_spacer.dart';
import '../../../shared/footer.dart';
import '../../../shared/shimmer_list.dart';
import '../../../shared/custom_textfield.dart';
import '../../../localization/app_locale.dart';
import '../dashboard/dashboard_view.dart';
import '../order/order_funtions.dart';
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
              _fetchBPartners();
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
                  style: Theme.of(context).textTheme.bodyLarge),
              subtitle: Text(
                  '${record['LCO_TaxIdTypeName'] ?? ''}  ${record['TaxID'] ?? ''}',
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
        appBar: AppBar(title: Text(AppLocale.customers.getString(context))),
        bottomNavigationBar: CustomFooter(),
        drawer: MenuDrawer(),
        floatingActionButton: FloatingActionButton(
          tooltip: AppLocale.add.getString(context),
          onPressed: () async {
            bool refresh = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const BPartnerNewPage(),
              ),
            );

            if (refresh) {
              _fetchBPartners();
            }
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
                          texto: AppLocale.searchCustomer.getString(context),
                          controlador: searchController,
                          icono: Icons.search,
                          onChanged: (_) => debouncedLoadBPartner(),
                        ),
                      ),
                      const SizedBox(width: CustomSpacer.small),
                      IconButton(
                        tooltip: AppLocale.refresh.getString(context),
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
