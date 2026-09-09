import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import '../../../localization/app_locale.dart';
import '../../../shared/custom_app_menu.dart';
import '../../../shared/format_date.dart';
import '../../../shared/footer.dart';
import 'held_ticket.dart';
import 'my_order_new.dart';
import 'order_funtions.dart';

class HeldTicketPage extends StatefulWidget {
  const HeldTicketPage({super.key});

  @override
  State<HeldTicketPage> createState() => _HeldTicketPageState();
}

class _HeldTicketPageState extends State<HeldTicketPage> {
  late Future<List<HeldTicket>> _tickets;
  Map<String, String> _paymentNames = {};

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _tickets = _loadTickets();
  }

  Future<List<HeldTicket>> _loadTickets() async {
    final tickets = await HeldTicketStore.instance.load();
    final methods = await fetchPaymentMethods();
    _paymentNames = {for (final method in methods) method['id'].toString(): (method['name'] ?? method['identifier'] ?? '').toString()};
    return tickets;
  }

  Future<void> _delete(HeldTicket ticket) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Theme.of(dialogContext).cardColor,
        title: Column(
          children: [
            const Icon(Icons.warning_amber_rounded, size: 45, color: Colors.redAccent),
            const SizedBox(height: 10),
            Text(
              AppLocale.deleteHeldTicket.getString(dialogContext),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocale.deleteHeldTicketMessage.getString(dialogContext),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocale.deleteCannotBeUndone.getString(dialogContext),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(AppLocale.no.getString(dialogContext))),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(AppLocale.yes.getString(dialogContext)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await HeldTicketStore.instance.delete(ticket.id);
    if (mounted) setState(_reload);
  }

  Future<void> _resume(HeldTicket ticket) async {
    await HeldTicketStore.instance.activeOrderSaver?.call();
    if (!mounted) return;
    final storedTickets = await HeldTicketStore.instance.load();
    final currentTicket = storedTickets.firstWhere((item) => item.id == ticket.id, orElse: () => ticket);
    if (!mounted) return;
    final data = currentTicket.data;
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => OrderNewPage(
          isRefund: data['isRefund'] == true,
          doctypeID: data['doctypeID'] as int?,
          orderName: data['orderName']?.toString(),
          sourceOrderId: data['sourceOrderId'] as int?,
          docSubTypeSO: data['docSubTypeSO']?.toString(),
          heldTicket: currentTicket,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocale.heldTickets.getString(context))),
      drawer: const MenuDrawer(),
      bottomNavigationBar: const CustomFooter(),
      body: FutureBuilder<List<HeldTicket>>(
        future: _tickets,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(AppLocale.heldTicketsLoadError.getString(context)));
          }
          final tickets = snapshot.data ?? const <HeldTicket>[];
          if (tickets.isEmpty) {
            return Center(child: Text(AppLocale.noHeldTickets.getString(context)));
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: tickets.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final ticket = tickets[index];
                  final data = ticket.data;
                  final lines = data['invoiceLines'] is List ? data['invoiceLines'] as List : const [];
                  final operation = data['orderName']?.toString().trim();
                  final title = operation?.isNotEmpty == true
                      ? operation!
                      : (data['isRefund'] == true ? AppLocale.creditNote.getString(context) : AppLocale.newOrder.getString(context));
                  final customer = data['customerName']?.toString().trim();
                  final total = (data['total'] as num?)?.toDouble() ?? 0;
                  final paymentDetails = data['paymentDetails'] is List
                      ? data['paymentDetails'] as List
                      : data['payments'] is Map
                      ? (data['payments'] as Map).entries
                            .where((entry) => (double.tryParse(entry.value?.toString().replaceAll(',', '.') ?? '') ?? 0) != 0)
                            .map(
                              (entry) => {
                                'name': _paymentNames[entry.key.toString()] ?? AppLocale.paymentMethod.getString(context),
                                'amount': entry.value,
                              },
                            )
                            .toList()
                      : const [];
                  final colorScheme = Theme.of(context).colorScheme;
                  return Card(
                    elevation: 2,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      backgroundColor: colorScheme.primary.withOpacity(0.025),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      iconColor: colorScheme.primary,
                      collapsedIconColor: colorScheme.primary,
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(
                                context,
                              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: colorScheme.primary),
                            ),
                          ),
                          IconButton(
                            tooltip: AppLocale.deleteHeldTicket.getString(context),
                            visualDensity: VisualDensity.compact,
                            color: colorScheme.error,
                            onPressed: () => _delete(ticket),
                            icon: const Icon(Icons.delete_outline),
                          ),
                          const SizedBox(width: 4),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                            ),
                            onPressed: () => _resume(ticket),
                            child: Text(
                              AppLocale.resumeHeldTicket.getString(context),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (customer?.isNotEmpty == true)
                              Text(customer!, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 7),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                _InfoBadge(
                                  icon: Icons.inventory_2_outlined,
                                  text: AppLocale.heldTicketProducts.getString(context).replaceAll('{count}', lines.length.toString()),
                                  color: colorScheme.primary,
                                ),
                                _InfoBadge(
                                  icon: Icons.attach_money_rounded,
                                  text: '${AppLocale.total.getString(context)}: \$${total.toStringAsFixed(2)}',
                                  color: Colors.green.shade700,
                                ),
                                _InfoBadge(
                                  icon: Icons.schedule_rounded,
                                  text: formatDateUI(ticket.updatedAt.toIso8601String()),
                                  color: colorScheme.secondary,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      children: [
                        const Divider(height: 1),
                        if (lines.isNotEmpty)
                          _TicketSection(
                            color: colorScheme.primary,
                            title: AppLocale.products.getString(context),
                            icon: Icons.inventory_2_outlined,
                            children: lines
                                .whereType<Map>()
                                .map(
                                  (line) => ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                                    title: Text(
                                      (line['name'] ?? line['Name'] ?? AppLocale.product.getString(context)).toString(),
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '× ${line['quantity'] ?? line['Quantity'] ?? 0}',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colorScheme.primary),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        if (paymentDetails.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _TicketSection(
                            color: Colors.green.shade700,
                            title: AppLocale.paymentMethods.getString(context),
                            icon: Icons.payments_outlined,
                            children: paymentDetails
                                .whereType<Map>()
                                .map(
                                  (payment) => ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                                    title: Text(
                                      (payment['name'] ?? AppLocale.paymentMethod.getString(context)).toString(),
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    trailing: Text(
                                      '\$${payment['amount'] ?? '0.00'}',
                                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.green.shade700),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _TicketSection extends StatelessWidget {
  const _TicketSection({required this.color, required this.title, required this.icon, required this.children});

  final Color color;
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 21, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
