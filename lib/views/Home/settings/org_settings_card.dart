import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../../API/endpoint.dart';
import '../../../API/token.api.dart';
import '../../../API/pos.api.dart';
import '../dashboard/dashboard_funtions.dart';
import '../../../shared/button.widget.dart';
import '../../../shared/custom_container.dart';
import '../../../shared/custom_textfield.dart';
import '../../../shared/toast_message.dart';

class OrgSettingsCard extends StatefulWidget {
  const OrgSettingsCard({super.key});

  @override
  State<OrgSettingsCard> createState() => _OrgSettingsCardState();
}

class _OrgSettingsCardState extends State<OrgSettingsCard> {
  // --- CONTROLADORES ORIGINALES (AD_Org) ---
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  // --- NUEVOS CONTROLADORES (AD_OrgInfo) ---
  final TextEditingController taxIdController = TextEditingController();
  final TextEditingController dvController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  String? selectedWarehouse; // Se mantiene para futuros usos

  bool isLoading = false;
  bool isImageLoading = false;
  bool _hasUnsavedChanges = false;
  Uint8List? _localLogoBytes;

  double _logoScale = 1.0;
  double _saveScale = 1.0;
  double _undoScale = 1.0;

  int? _adOrgId;
  int? _adOrgInfoId;
  int? _cLocationId;

  @override
  void initState() {
    super.initState();
    _localLogoBytes = POSPrinter.logo;

    _loadOrganizationData();

    nameController.addListener(_onFieldChanged);
    descController.addListener(_onFieldChanged);
    codeController.addListener(_onFieldChanged);
    locationController.addListener(_onFieldChanged);

    taxIdController.addListener(_onFieldChanged);
    dvController.addListener(_onFieldChanged);
    phoneController.addListener(_onFieldChanged);
    emailController.addListener(_onFieldChanged);
  }

  Future<void> _loadOrganizationData() async {
    setState(() => isLoading = true);

    try {
      print("========== INICIO CARGA DE ORGANIZACIÓN ==========");
      final orgUrl = EndPoints.adOrgInfo.replaceAll('AD_OrgInfo', 'AD_Org');

      final orgResp = await get(Uri.parse('$orgUrl?\$filter=AD_Org_ID eq ${Token.organitation}'), headers: {'Content-Type': 'application/json', 'Authorization': Token.auth!});

      if (orgResp.statusCode == 200) {
        final data = jsonDecode(utf8.decode(orgResp.bodyBytes));
        if (data['records'] != null && data['records'].isNotEmpty) {
          final record = data['records'][0];
          _adOrgId = record['id']; // ID principal (ej. 1000001)

          setState(() {
            nameController.text = record['Name'] ?? '';
            codeController.text = record['Value'] ?? '';
            descController.text = record['Description'] ?? '';
          });
        }
      }

      final infoResp = await get(Uri.parse('${EndPoints.adOrgInfo}?\$filter=AD_Org_ID eq ${Token.organitation}'), headers: {'Content-Type': 'application/json', 'Authorization': Token.auth!});

      if (infoResp.statusCode == 200) {
        final data = jsonDecode(utf8.decode(infoResp.bodyBytes));
        if (data['records'] != null && data['records'].isNotEmpty) {
          final record = data['records'][0];

          setState(() {
            // Asignamos los datos directamente como strings
            taxIdController.text = record['TaxID']?.toString() ?? '';
            dvController.text = record['dv']?.toString() ?? '';
            phoneController.text = record['Phone2']?.toString() ?? '';
            emailController.text = record['EMail']?.toString() ?? '';

            if (record['C_Location_ID'] != null) {
              _cLocationId = record['C_Location_ID']['id'];
              locationController.text = record['C_Location_ID']['identifier'] ?? '';
            }
          });
        }
      }
      print("========== FIN CARGA DE ORGANIZACIÓN ==========");
    } catch (e) {
      print("Excepción cargando organización: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          _hasUnsavedChanges = false;
        });
      }
    }
  }

  String _extractStringValue(dynamic value) {
    if (value == null) return '';
    if (value is Map) {
      return value['identifier']?.toString() ?? value['id']?.toString() ?? '';
    }
    return value.toString();
  }

  void _onFieldChanged() {
    if (!_hasUnsavedChanges && !isLoading) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  void _undoChanges() {
    setState(() {
      _localLogoBytes = POSPrinter.logo;
      _hasUnsavedChanges = false;
    });
    _loadOrganizationData();
  }

  @override
  void dispose() {
    nameController.dispose();
    descController.dispose();
    codeController.dispose();
    locationController.dispose();
    taxIdController.dispose();
    dvController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _pickAndCropImage() async {
    final ImagePicker picker = ImagePicker();

    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (image == null) return;

    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: image.path,
      aspectRatioPresets: [CropAspectRatioPreset.square],
      uiSettings: [
        AndroidUiSettings(toolbarTitle: 'Ajustar Logo', toolbarColor: Theme.of(context).primaryColor, toolbarWidgetColor: Colors.white, initAspectRatio: CropAspectRatioPreset.square, lockAspectRatio: true),
        IOSUiSettings(title: 'Ajustar Logo', aspectRatioLockEnabled: true, doneButtonTitle: 'Listo', cancelButtonTitle: 'Cancelar'),
      ],
    );

    if (croppedFile == null) return;

    final Uint8List bytes = await croppedFile.readAsBytes();

    setState(() {
      _localLogoBytes = bytes;
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _saveOrganization() async {
    setState(() => isLoading = true);
    bool success = true;

    print("========== INICIO GUARDADO ==========");

    // 1. Guardar LOGO
    if (_localLogoBytes != null && _localLogoBytes != POSPrinter.logo) {
      print("-> Actualizando Logo...");
      final bool logoOk = await updateOrgLogo(_localLogoBytes!, context);
      if (logoOk) {
        POSPrinter.logo = _localLogoBytes;
        POSPrinter.isLogoSet = true;
      } else {
        success = false;
        if (mounted) ToastMessage.show(context: context, message: 'Error al subir el logo', type: ToastType.failure);
      }
    }

    if (_adOrgId != null) {
      final orgUrl = EndPoints.adOrgInfo.replaceAll('AD_OrgInfo', 'AD_Org');
      final bodyText = jsonEncode({"Name": nameController.text.trim(), "Value": codeController.text.trim(), "Description": descController.text.trim()});

      try {
        final putResp = await put(Uri.parse('$orgUrl/$_adOrgId'), headers: {'Content-Type': 'application/json', 'Authorization': Token.auth!}, body: bodyText);
        if (putResp.statusCode != 200 && putResp.statusCode != 204) {
          print("<- Body Error AD_Org: ${putResp.body}");
          success = false;
        }
      } catch (e) {
        success = false;
      }
    }

    if (_adOrgId != null) {
      final bodyInfo = jsonEncode({"TaxID": taxIdController.text.trim(), "dv": dvController.text.trim(), "Phone2": phoneController.text.trim(), "EMail": emailController.text.trim()});

      print("-> Actualizando Info PUT: ${EndPoints.adOrgInfo}/$_adOrgId");
      print("-> Body Info: $bodyInfo");

      try {
        final infoResp = await put(Uri.parse('${EndPoints.adOrgInfo}/$_adOrgId'), headers: {'Content-Type': 'application/json', 'Authorization': Token.auth!}, body: bodyInfo);
        print("<- Status AD_OrgInfo PUT: ${infoResp.statusCode}");
        if (infoResp.statusCode != 200 && infoResp.statusCode != 204) {
          print("<- Body Error AD_OrgInfo: ${infoResp.body}");
          success = false;
        }
      } catch (e) {
        print("Excepción actualizando Info: $e");
        success = false;
      }
    }

    print("-> Valor TextField Localización: ${locationController.text}");

    print("========== FIN GUARDADO ==========");

    setState(() {
      isLoading = false;
      if (success) _hasUnsavedChanges = false;
    });

    if (mounted) {
      if (success) {
        ToastMessage.show(context: context, message: 'Ajustes guardados exitosamente', type: ToastType.success);
      } else {
        ToastMessage.show(context: context, message: 'Ocurrió un error al guardar', type: ToastType.failure);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomContainer(
      maxWidthContainer: 500,
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Column(
          children: [
            if (isLoading)
              LinearProgressIndicator(
                minHeight: 3, // Más delgada
                backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.secondary), // Verde oscuro del tema
              ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Icon(Icons.business_outlined, color: Theme.of(context).primaryColor, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        'Perfil de la\nOrganización',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  GestureDetector(
                    onTapDown: isImageLoading ? null : (_) => setState(() => _logoScale = 0.92),
                    onTapUp: isImageLoading
                        ? null
                        : (_) {
                            Future.delayed(const Duration(milliseconds: 100), () {
                              if (mounted) setState(() => _logoScale = 1.0);
                            });
                          },
                    onTapCancel: () => setState(() => _logoScale = 1.0),
                    onTap: isImageLoading ? null : _pickAndCropImage,
                    child: AnimatedScale(
                      scale: _logoScale,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.5), width: 2),
                            ),
                            child: Opacity(
                              opacity: isImageLoading ? 0.3 : 1.0,
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: Theme.of(context).cardColor,
                                backgroundImage: _localLogoBytes != null ? MemoryImage(_localLogoBytes!) : null,
                                child: _localLogoBytes == null ? Icon(Icons.storefront_rounded, size: 50, color: Theme.of(context).primaryColor.withOpacity(0.5)) : null,
                              ),
                            ),
                          ),
                          if (isImageLoading) const Positioned.fill(child: Center(child: CircularProgressIndicator())),
                          if (!isImageLoading)
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Theme.of(context).colorScheme.surface, width: 3),
                              ),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            ),
                        ],
                      ),
                    ),
                  ),
                  //TODO TRADUCIR
                  const SizedBox(height: 32),

                  TextfieldTheme(controlador: nameController, texto: 'Nombre de la Organización', icono: Icons.corporate_fare),
                  const SizedBox(height: 16),
                  TextfieldTheme(controlador: descController, texto: 'Descripción', icono: Icons.description_outlined),
                  const SizedBox(height: 16),
                  TextfieldTheme(controlador: codeController, texto: 'Código', icono: Icons.code_rounded),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),

                  TextfieldTheme(controlador: taxIdController, texto: 'Número de Identificación', icono: Icons.badge_outlined),
                  const SizedBox(height: 16),
                  TextfieldTheme(controlador: dvController, texto: 'Dígito Verificador (DV)', icono: Icons.pin_outlined),
                  const SizedBox(height: 16),
                  TextfieldTheme(controlador: phoneController, texto: 'Teléfono Móvil', icono: Icons.phone_android_outlined, inputType: TextInputType.phone),
                  const SizedBox(height: 16),
                  TextfieldTheme(controlador: emailController, texto: 'Email', icono: Icons.email_outlined, inputType: TextInputType.emailAddress),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),

                  /* // --- LOCALIZACIÓN Y ALMACÉN ---
                  
                  TextfieldTheme(
                    controlador: locationController,
                    texto: 'Dirección / Localización',
                    icono: Icons.location_on_outlined,
                    inputType: TextInputType.streetAddress, 
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text('Seleccionar Almacén (Warehouse)'),
                        value: selectedWarehouse,
                        icon: Icon(Icons.warehouse_outlined, color: Theme.of(context).primaryColor),
                        items: ['Almacén Central', 'Bodega 2'].map((String value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            selectedWarehouse = newValue;
                            _hasUnsavedChanges = true; 
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  */
                  Row(
                    children: [
                      if (_hasUnsavedChanges && !isLoading) ...[
                        Expanded(
                          flex: 1,
                          child: GestureDetector(
                            onTapDown: (_) => setState(() => _undoScale = 0.92),
                            onTapUp: (_) {
                              Future.delayed(const Duration(milliseconds: 100), () {
                                if (mounted) setState(() => _undoScale = 1.0);
                              });
                            },
                            onTapCancel: () => setState(() => _undoScale = 1.0),
                            onTap: _undoChanges,
                            child: AnimatedScale(
                              scale: _undoScale,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red.shade300),
                                ),
                                child: Icon(Icons.restore, color: Colors.red.shade400),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],

                      Expanded(
                        flex: 3,
                        child: isLoading
                            ? const ButtonLoading()
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  final bool isButtonEnabled = _hasUnsavedChanges;
                                  final bool isNarrow = constraints.maxWidth < 160;
                                  final double borderRadius = isNarrow ? 25 : 12;

                                  return GestureDetector(
                                    onTapDown: isButtonEnabled ? (_) => setState(() => _saveScale = 0.95) : null,
                                    onTapUp: isButtonEnabled
                                        ? (_) {
                                            Future.delayed(const Duration(milliseconds: 100), () {
                                              if (mounted) setState(() => _saveScale = 1.0);
                                            });
                                          }
                                        : null,
                                    onTapCancel: () => setState(() => _saveScale = 1.0),
                                    onTap: isButtonEnabled ? _saveOrganization : null,
                                    child: AnimatedScale(
                                      scale: _saveScale,
                                      duration: const Duration(milliseconds: 200),
                                      curve: Curves.easeOutCubic,
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        height: 50,
                                        decoration: BoxDecoration(color: isButtonEnabled ? Theme.of(context).primaryColor : Colors.grey.shade300, borderRadius: BorderRadius.circular(borderRadius)),
                                        alignment: Alignment.center,
                                        child: AnimatedCrossFade(
                                          duration: const Duration(milliseconds: 250),
                                          firstChild: const Icon(Icons.save_outlined, color: Colors.white, size: 24),
                                          secondChild: const Text(
                                            'Guardar Cambios',
                                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                          ),
                                          crossFadeState: isNarrow ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
