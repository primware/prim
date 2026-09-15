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
import 'bpartner_details.dart';
import 'bpartner_new.dart';
import 'bpartner_repository.dart';
import '../../../shared/custom_pagination.dart';
import 'bpartner_sync_controller.dart';

class BPartnerListPage extends StatefulWidget {
  const BPartnerListPage({super.key});

  @override
  State<BPartnerListPage> createState() => _BPartnerListPageState();
}

class _BPartnerListPageState extends State<BPartnerListPage> {
  List<Map<String, dynamic>> _bpartners = [];
  int _currentPage = 0;
  int _rowCount = 0;
  bool _isLoading = true;
  bool isSearchLoading = false;
  String searchQuery = '';
  TextEditingController searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    BPartnerRepository.instance.addListener(_onRepositoryChanged);
    _fetchBPartners();
  }

  @override
  void dispose() {
    BPartnerRepository.instance.removeListener(_onRepositoryChanged);
    _debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _onRepositoryChanged() async {
    final page = await BPartnerRepository.instance.readCachedPage(searchTerm: searchController.text.trim(), pageIndex: _currentPage);
    if (!mounted || page == null) return;
    setState(() {
      _bpartners = page.records;
      _rowCount = page.rowCount;
    });
  }

  Future<void> _fetchBPartners() async {
    setState(() => _isLoading = true);
    final result = await BPartnerRepository.instance.getCustomers(context: context);
    if (!mounted) return;
    setState(() {
      _bpartners = result.records;
      _rowCount = result.rowCount;
      _currentPage = result.pageIndex;
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

  Future<void> _loadBPartner({bool showLoadingIndicator = false, int page = 0}) async {
    if (showLoadingIndicator) {
      setState(() {
        isSearchLoading = true;
      });
    }
    final result = await BPartnerRepository.instance.getCustomers(
      context: context,
      searchTerm: searchController.text.trim(),
      pageIndex: page,
    );
    if (!mounted) return;
    setState(() {
      _bpartners = result.records;
      _rowCount = result.rowCount;
      _currentPage = page;
      _isLoading = false;
      isSearchLoading = false;
    });
  }

  int get _totalPages => _rowCount == 0 ? 1 : (_rowCount / bPartnerPageSize).ceil();

  List<Map<String, dynamic>> _getFilteredPartners() {
    return _bpartners.where((bp) => bp['name'].toString().toLowerCase().contains(searchQuery.toLowerCase())).toList();
  }

  Widget _buildPartnerCard(Map<String, dynamic> record) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => BPartnerDetailPage(bpartner: record)));
        if (result != null && result['created'] == true) {
          searchController.text = result['bpartner'];
          _loadBPartner(showLoadingIndicator: true);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
          border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.1)),
        ),
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
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          record['TaxID'] ?? 'Sin ID',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (record['dv'] != null)
                        Text('DV: ${record['dv']}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardPage()));
        return Future.value(false);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(AppLocale.customers.getString(context))),
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
          child: Center(
            child: CustomContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextfieldTheme(
                          texto: AppLocale.searchCustomer.getString(context),
                          controlador: searchController,
                          pista: AppLocale.taxIDOrName.getString(context),
                          onSubmitted: (_) => _loadBPartner(showLoadingIndicator: true),
                        ),
                      ),
                      const SizedBox(width: CustomSpacer.small),
                      Container(
                        height: 55,
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).floatingActionButtonTheme.backgroundColor ?? Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.search,
                            color:
                                Theme.of(context).floatingActionButtonTheme.foregroundColor ??
                                Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                          onPressed: () => _loadBPartner(showLoadingIndicator: true),
                        ),
                      ),
                      const SizedBox(width: CustomSpacer.small),
                      IconButton.filledTonal(
                        tooltip: AppLocale.syncCustomers.getString(context),
                        onPressed: BPartnerSyncController.instance.isRunning
                            ? null
                            : () => BPartnerSyncController.instance.start(context: context),
                        icon: const Icon(Icons.sync),
                      ),
                    ],
                  ),

                  if (isSearchLoading) ...[const SizedBox(height: CustomSpacer.small), const LinearProgressIndicator()],

                  AnimatedBuilder(
                    animation: BPartnerSyncController.instance,
                    builder: (context, _) {
                      final sync = BPartnerSyncController.instance;
                      if (!sync.isRunning && sync.error == null) return const SizedBox.shrink();
                      return Card(
                        margin: const EdgeInsets.only(top: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      AppLocale.syncingCustomers.getString(context),
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  Text('${sync.processed} / ${sync.total}'),
                                  IconButton(
                                    tooltip: AppLocale.stop.getString(context),
                                    onPressed: sync.isStopping ? null : sync.stop,
                                    color: Theme.of(context).colorScheme.error,
                                    icon: const Icon(Icons.stop_circle_outlined),
                                  ),
                                ],
                              ),
                              LinearProgressIndicator(value: sync.total > 0 ? sync.progress : null),
                              if (sync.error != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    AppLocale.customerSyncError.getString(context),
                                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: CustomSpacer.medium),

                  Expanded(
                    child: _isLoading
                        ? ShimmerList(separation: CustomSpacer.medium)
                        : _getFilteredPartners().isEmpty
                        ? Center(
                            child: Text(
                              AppLocale.noProductsFound.getString(context),
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: _getFilteredPartners().length + 1,
                            itemBuilder: (context, index) {
                              if (index == _getFilteredPartners().length) {
                                return CustomPagination(
                                  currentPage: _currentPage,
                                  totalPages: _totalPages,
                                  onPrevious: _currentPage > 0 && !isSearchLoading
                                      ? () => _loadBPartner(showLoadingIndicator: true, page: _currentPage - 1)
                                      : null,
                                  onNext: _currentPage + 1 < _totalPages && !isSearchLoading
                                      ? () => _loadBPartner(showLoadingIndicator: true, page: _currentPage + 1)
                                      : null,
                                );
                              }
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
    );
  }
}
