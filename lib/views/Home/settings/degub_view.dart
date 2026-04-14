import 'package:flutter/material.dart';
import 'package:primware/API/endpoint.dart';
import 'package:primware/API/pos.api.dart';
import 'package:primware/API/token.api.dart';
import 'package:primware/API/user.api.dart';
import '../../../shared/custom_app_menu.dart';
import '../../../shared/custom_spacer.dart';
import '../../../shared/footer.dart';

class DebugPage extends StatefulWidget {
  const DebugPage({super.key});
  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  Color _getLogLevelColor(String level) {
    level = level.toUpperCase();
    if (level.contains('ERROR')) return Colors.redAccent;
    if (level.contains('WARN')) return Colors.orangeAccent;
    if (level.contains('INFO')) return Colors.greenAccent;
    return Colors.white70;
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12),
            ),
          ),
          Expanded(
            flex: 3, // Toma el 60% del espacio para el valor
            child: SelectableText(value, style: const TextStyle(fontSize: 12, fontFamily: 'Courier')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isProd = Base.prod;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: const MenuDrawer(),
      appBar: AppBar(title: const Text('Consola'), centerTitle: true),
      bottomNavigationBar: const CustomFooter(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- BLOQUE 1: TARJETA DE ESTADO DEL SERVIDOR ---
            Container(
              decoration: BoxDecoration(
                color: isProd ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: (isProd ? Colors.green : Colors.blue).withOpacity(0.3), width: 1.5),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  iconColor: isProd ? Colors.green : Colors.blue,
                  collapsedIconColor: isProd ? Colors.green : Colors.blue,
                  title: Row(
                    children: [
                      Icon(isProd ? Icons.cloud_done : Icons.dns, color: isProd ? Colors.green : Colors.blue),
                      const SizedBox(width: 10),
                      Text(
                        isProd ? 'ENTORNO DE PRODUCCIÓN' : 'ENTORNO DE DESARROLLO',
                        style: TextStyle(fontWeight: FontWeight.bold, color: isProd ? Colors.green : Colors.blue, letterSpacing: 1.1, fontSize: 13),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(Base.baseURL ?? 'URL no disponible', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                  childrenPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const SizedBox(height: 8),

                    _buildInfoRow('Producción:', '${Base.prod}'),
                    _buildInfoRow('URL Base:', '${Base.baseURL}'),
                    const SizedBox(height: 12),

                    _buildInfoRow('POS priceListID:', '${POS.priceListID}'),
                    _buildInfoRow('POS versionID:', '${POS.priceListVersionID}'),
                    _buildInfoRow('POS docTypeID:', '${POS.docTypeID}'),
                    _buildInfoRow('POS templateID:', '${POS.templatePartnerID}'),
                    _buildInfoRow('POS isPOS:', '${POS.isPOS}'),
                    const SizedBox(height: 12),

                    _buildInfoRow('User ID:', '${UserData.id}'),
                    _buildInfoRow('User Rol:', '${UserData.rolName}'),
                    _buildInfoRow('User Client:', '${UserData.clientName}'),
                    _buildInfoRow('User Name:', '${UserData.name}'),
                    _buildInfoRow('User Email:', '${UserData.email}'),
                    const SizedBox(height: 12),

                    _buildInfoRow('Token Auth:', Token.auth ?? 'Sin Token Activo'),
                    _buildInfoRow('Token Client:', '${Token.client}'),
                    _buildInfoRow('Token Rol:', '${Token.rol}'),
                    _buildInfoRow('Token Org:', '${Token.organitation}'),
                    _buildInfoRow('Token WH ID:', '${Token.warehouseID}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // --- BLOQUE 2: CABECERA DE LA TERMINAL ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.terminal, size: 20),
                    const SizedBox(width: 8),
                    Text('Logs del Sistema', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                TextButton.icon(onPressed: () => setState(() => CurrentLogMessage.log.clear()), icon: const Icon(Icons.delete_sweep_outlined, size: 20), label: const Text('Limpiar')),
              ],
            ),

            const SizedBox(height: 12),

            // --- BLOQUE 3: TERMINAL ---
            Container(
              height: MediaQuery.of(context).size.height * 0.55,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E), // Fondo oscuro de consola real
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  reverse: false,
                  itemCount: CurrentLogMessage.log.length,
                  itemBuilder: (context, index) {
                    final entry = CurrentLogMessage.log[index];
                    final ts = (entry['ts'] ?? '').toString();
                    final level = (entry['level'] ?? 'INFO').toString();
                    final message = (entry['message'] ?? '').toString();

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(fontFamily: 'Courier', fontSize: 13, height: 1.4),
                          children: [
                            TextSpan(
                              text: '[$ts] ',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            TextSpan(
                              text: '${level.padRight(5)}: ',
                              style: TextStyle(color: _getLogLevelColor(level), fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: message,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
