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
import '../../../Widgets/GlassDesign.dart';

class BPartnerListPage extends StatefulWidget {
  const BPartnerListPage({super.key});

  @override
  State<BPartnerListPage> createState() => _BPartnerListPageState();
}

class _BPartnerListPageState extends State<BPartnerListPage> {
  List<Map<String, dynamic>> _bpartners = [];
  bool _isLoading = true;
  bool isSearchLoading = false;
  String searchQuery = '';
  TextEditingController searchController = TextEditingController();
  Timer? _debounce;
  double _reloadTurns = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchBPartners();
  }

  Future<void> _fetchBPartners() async {
    setState(() => _isLoading = true);
    final result = await fetchBPartner(context: context);
    if (!mounted) return;
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
    final partners = await fetchBPartner(context: context, searchTerm: searchController.text.trim());
    if (!mounted) return;
    setState(() {
      _bpartners = partners;
      isSearchLoading = false;
    });
  }

  List<Map<String, dynamic>> _getFilteredPartners() {
    return _bpartners.where((bp) => bp['name'].toString().toLowerCase().contains(searchQuery.toLowerCase())).toList();
  }

  Widget _buildPartnerCard(Map<String, dynamic> record) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => BPartnerDetailPage(bpartner: record)));
          if (result != null && result['created'] == true) {
            searchController.text = result['bpartner'];
            _loadBPartner(showLoadingIndicator: true);
          }
        },
        child: GlassContainer(
          padding: const EdgeInsets.all(16),
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                child: Center(child: Icon(Icons.person_outline, color: Theme.of(context).primaryColor, size: 28)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record['name'],
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            record['TaxID'] ?? 'Sin ID',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (record['dv'] != null) Text('DV: ${record['dv']}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                      ],
                    ),
                    if (record['LCO_TaxIdTypeName'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(record['LCO_TaxIdTypeName'], style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10)),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardPage()));
        return Future.value(false);
      },
      child: LightAccentBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,

          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: const GlassContainer(borderRadius: BorderRadius.zero, padding: EdgeInsets.zero, child: SizedBox.expand()),
            title: Text(AppLocale.customers.getString(context), style: const TextStyle(fontWeight: FontWeight.bold)),
            iconTheme: Theme.of(context).iconTheme,
          ),
          bottomNavigationBar: CustomFooter(),
          drawer: MenuDrawer(),
          floatingActionButton: FloatingActionButton(
            tooltip: AppLocale.add.getString(context),
            onPressed: () async {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const BPartnerNewPage()));

              if (result['created'] == true) {
                searchController.text = result['bpartner']?['Name'];
                _loadBPartner(showLoadingIndicator: true);
              }
            },
            child: const Icon(Icons.add),
          ),
          body: SafeArea(
            bottom: false,
            child: Center(
              child: CustomContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: GlassContainer(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextfieldTheme(
                                texto: AppLocale.searchCustomer.getString(context),
                                controlador: searchController,
                                pista: AppLocale.taxIDOrName.getString(context),
                                onSubmitted: (_) => _loadBPartner(showLoadingIndicator: true),
                                onChanged: (val) {
                                  setState(() {
                                    searchQuery = val;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: CustomSpacer.small),
                            Container(
                              height: 55,
                              decoration: BoxDecoration(color: Theme.of(context).primaryColor, borderRadius: BorderRadius.circular(8)),
                              child: IconButton(
                                icon: AnimatedRotation(
                                  turns: _reloadTurns, // Controla el giro
                                  duration: const Duration(milliseconds: 800),
                                  curve: Curves.easeOutExpo, // Giro suave
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    transitionBuilder: (Widget child, Animation<double> animation) {
                                      return ScaleTransition(scale: animation, child: child);
                                    },
                                    child: Icon(searchQuery.isNotEmpty ? Icons.search : Icons.refresh, key: ValueKey<bool>(searchQuery.isNotEmpty), color: Colors.white),
                                  ),
                                ),
                                onPressed: () {
                                  if (searchQuery.isEmpty) {
                                    setState(() {
                                      _reloadTurns += 1.0;
                                    });
                                  }
                                  _loadBPartner(showLoadingIndicator: true);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (isSearchLoading) ...[const SizedBox(height: 16), const LinearProgressIndicator(), const SizedBox(height: 8)],

                    const SizedBox(height: CustomSpacer.medium),

                    Expanded(
                      child: _isLoading
                          ? ShimmerList(separation: CustomSpacer.medium)
                          : _getFilteredPartners().isEmpty
                          ? Center(
                              child: Text(AppLocale.noProductsFound.getString(context), style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey)),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Evita cortes en el cristal
                              physics: const BouncingScrollPhysics(),
                              itemCount: _getFilteredPartners().length,
                              itemBuilder: (context, index) {
                                final record = _getFilteredPartners()[index];
                                return _buildPartnerCard(record);
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
