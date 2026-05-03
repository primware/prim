import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
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
import '../../../localization/app_locale.dart';

class OrgSettingsCard extends StatefulWidget {
  const OrgSettingsCard({super.key});

  @override
  State<OrgSettingsCard> createState() => _OrgSettingsCardState();
}

class _OrgSettingsCardState extends State<OrgSettingsCard> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  final TextEditingController taxIdController = TextEditingController();
  final TextEditingController dvController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  final TextEditingController addressController = TextEditingController();
  final TextEditingController address2Controller = TextEditingController();
  final TextEditingController address3Controller = TextEditingController();
  final TextEditingController address4Controller = TextEditingController();
  final TextEditingController zipController = TextEditingController();

  List<dynamic> _countries = [];
  List<dynamic> _cities = [];
  int? _selectedCountryId;
  int? _selectedCityId;
  String _currentCityName = '';

  String? selectedWarehouse;

  bool isLoading = false;
  bool isImageLoading = false;
  bool _hasUnsavedChanges = false;
  Uint8List? _localLogoBytes;

  double _logoScale = 1.0;
  double _saveScale = 1.0;
  double _undoScale = 1.0;

  int? _adOrgId;
  int? _cLocationId;

  @override
  void initState() {
    super.initState();
    _localLogoBytes = POSPrinter.logo;

    _loadOrganizationData();
    _loadCountries();

    nameController.addListener(_onFieldChanged);
    descController.addListener(_onFieldChanged);
    codeController.addListener(_onFieldChanged);

    taxIdController.addListener(_onFieldChanged);
    dvController.addListener(_onFieldChanged);
    phoneController.addListener(_onFieldChanged);
    emailController.addListener(_onFieldChanged);

    addressController.addListener(_onFieldChanged);
    address2Controller.addListener(_onFieldChanged);
    address3Controller.addListener(_onFieldChanged);
    address4Controller.addListener(_onFieldChanged);
    zipController.addListener(_onFieldChanged);
  }

  Future<void> _loadCountries() async {
    try {
      final url = EndPoints.model('C_Country');
      final resp = await get(Uri.parse(url), headers: {'Content-Type': 'application/json', 'Authorization': Token.auth!});
      if (resp.statusCode == 200) {
        final data = jsonDecode(utf8.decode(resp.bodyBytes));
        setState(() => _countries = data['records'] ?? []);
      }
    } catch (e) {
      print("Error cargando países: $e");
    }
  }

  Future<void> _loadCities(int countryId) async {
    try {
      final url = EndPoints.model('C_City');
      final resp = await get(Uri.parse('$url?\$filter=C_Country_ID eq $countryId'), headers: {'Content-Type': 'application/json', 'Authorization': Token.auth!});
      if (resp.statusCode == 200) {
        final data = jsonDecode(utf8.decode(resp.bodyBytes));
        setState(() => _cities = data['records'] ?? []);
      }
    } catch (e) {
      print("Error cargando ciudades: $e");
    }
  }

  Future<void> _loadOrganizationData() async {
    setState(() => isLoading = true);

    try {
      print("========== INICIO CARGA DE ORGANIZACIÓN ==========");
      final orgUrl = EndPoints.model('AD_Org');

      final orgResp = await get(Uri.parse('$orgUrl?\$filter=AD_Org_ID eq ${Token.organitation}'), headers: {'Content-Type': 'application/json', 'Authorization': Token.auth!});

      if (orgResp.statusCode == 200) {
        final data = jsonDecode(utf8.decode(orgResp.bodyBytes));
        if (data['records'] != null && data['records'].isNotEmpty) {
          final record = data['records'][0];
          _adOrgId = record['id'];

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
            taxIdController.text = record['TaxID']?.toString() ?? '';
            dvController.text = record['dv']?.toString() ?? '';
            phoneController.text = record['Phone2']?.toString() ?? '';
            emailController.text = record['EMail']?.toString() ?? '';
          });

          if (record['C_Location_ID'] != null) {
            _cLocationId = record['C_Location_ID']['id'];

            final locUrl = EndPoints.model('C_Location');
            final locResp = await get(Uri.parse('$locUrl/$_cLocationId'), headers: {'Content-Type': 'application/json', 'Authorization': Token.auth!});

            if (locResp.statusCode == 200) {
              final locData = jsonDecode(utf8.decode(locResp.bodyBytes));

              setState(() {
                _selectedCountryId = locData['C_Country_ID']?['id'];
                if (_selectedCountryId != null) {
                  _loadCities(_selectedCountryId!);
                }

                _selectedCityId = locData['C_City_ID']?['id'];
                _currentCityName = locData['City']?.toString() ?? '';

                addressController.text = locData['Address1']?.toString() ?? '';
                address2Controller.text = locData['Address2']?.toString() ?? '';
                address3Controller.text = locData['Address3']?.toString() ?? '';
                address4Controller.text = locData['Address4']?.toString() ?? '';
                zipController.text = locData['Postal']?.toString() ?? '';

                String visualAddress = locData['identifier'] ?? '';
                if (visualAddress.trim().replaceAll(',', '').isEmpty) {
                  visualAddress = addressController.text.trim();
                }
                locationController.text = visualAddress;
              });
            }
          }
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

    addressController.dispose();
    address2Controller.dispose();
    address3Controller.dispose();
    address4Controller.dispose();
    zipController.dispose();
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
        AndroidUiSettings(toolbarTitle: AppLocale.adjustLogo.getString(context), toolbarColor: Theme.of(context).primaryColor, toolbarWidgetColor: Colors.white, initAspectRatio: CropAspectRatioPreset.square, lockAspectRatio: true),
        IOSUiSettings(title: AppLocale.adjustLogo.getString(context), aspectRatioLockEnabled: true, doneButtonTitle: AppLocale.done.getString(context), cancelButtonTitle: AppLocale.cancel.getString(context)),
      ],
    );

    if (croppedFile == null) return;
    final Uint8List bytes = await croppedFile.readAsBytes();

    setState(() {
      _localLogoBytes = bytes;
      _hasUnsavedChanges = true;
    });
  }

  void _showLocationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(Icons.location_on, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text(AppLocale.editAddress.getString(context)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // DROPDOWN PAÍS
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          hint: Text(AppLocale.country.getString(context)),
                          value: _countries.any((c) => c['id'] == _selectedCountryId) ? _selectedCountryId : null,
                          items: _countries.map((country) {
                            return DropdownMenuItem<int>(value: country['id'], child: Text(country['Name'] ?? country['identifier'] ?? AppLocale.unknown.getString(context)));
                          }).toList(),
                          onChanged: (newValue) {
                            setStateDialog(() {
                              _selectedCountryId = newValue;
                              _selectedCityId = null;
                              _currentCityName = '';
                              _cities = [];
                            });
                            this.setState(() => _hasUnsavedChanges = true);
                            if (newValue != null) {
                              _loadCities(newValue).then((_) => setStateDialog(() {}));
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // DROPDOWN CIUDAD
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          hint: Text(AppLocale.city.getString(context)),
                          value: _cities.any((c) => c['id'] == _selectedCityId) ? _selectedCityId : null,
                          items: _cities.map((city) {
                            return DropdownMenuItem<int>(value: city['id'], child: Text(city['Name'] ?? city['identifier'] ?? AppLocale.unknown.getString(context)));
                          }).toList(),
                          onChanged: (newValue) {
                            setStateDialog(() {
                              _selectedCityId = newValue;
                              var cityObj;
                              for (var c in _cities) {
                                if (c['id'] == newValue) {
                                  cityObj = c;
                                  break;
                                }
                              }
                              if (cityObj != null) {
                                _currentCityName = cityObj['Name']?.toString() ?? cityObj['identifier']?.toString() ?? '';
                              }
                            });
                            this.setState(() => _hasUnsavedChanges = true);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // CÓDIGO POSTAL
                    TextField(
                      controller: zipController,
                      decoration: InputDecoration(
                        labelText: AppLocale.zipCode.getString(context),
                        prefixIcon: const Icon(Icons.markunread_mailbox_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: addressController,
                      decoration: InputDecoration(
                        labelText: AppLocale.address1.getString(context),
                        prefixIcon: const Icon(Icons.streetview_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: address2Controller,
                      decoration: InputDecoration(
                        labelText: AppLocale.address2.getString(context),
                        prefixIcon: const Icon(Icons.map_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: address3Controller,
                      decoration: InputDecoration(
                        labelText: AppLocale.address3.getString(context),
                        prefixIcon: const Icon(Icons.map_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: address4Controller,
                      decoration: InputDecoration(
                        labelText: AppLocale.address4.getString(context),
                        prefixIcon: const Icon(Icons.map_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(AppLocale.cancel.getString(context), style: TextStyle(color: Colors.grey.shade600)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    setState(() {
                      locationController.text = addressController.text.isNotEmpty ? addressController.text : AppLocale.addressUpdated.getString(context);
                    });
                    Navigator.of(context).pop();
                  },
                  child: Text(AppLocale.accept.getString(context), style: const TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveOrganization() async {
    setState(() => isLoading = true);
    bool success = true;

    print("========== INICIO GUARDADO ==========");

    if (_localLogoBytes != null && _localLogoBytes != POSPrinter.logo) {
      final bool logoOk = await updateOrgLogo(_localLogoBytes!, context);
      if (logoOk) {
        POSPrinter.logo = _localLogoBytes;
        POSPrinter.isLogoSet = true;
      } else {
        success = false;
        if (mounted) ToastMessage.show(context: context, message: AppLocale.errorUploadingLogo.getString(context), type: ToastType.failure);
      }
    }

    if (_adOrgId != null) {
      final orgUrl = EndPoints.model('AD_Org');
      final bodyText = jsonEncode({"Name": nameController.text.trim(), "Value": codeController.text.trim(), "Description": descController.text.trim()});

      try {
        final putResp = await put(Uri.parse('$orgUrl/$_adOrgId'), headers: {'Content-Type': 'application/json', 'Authorization': Token.auth!}, body: bodyText);
        if (putResp.statusCode != 200 && putResp.statusCode != 204) success = false;
      } catch (e) {
        success = false;
      }
    }

    if (_adOrgId != null) {
      final bodyInfo = jsonEncode({"TaxID": taxIdController.text.trim(), "dv": dvController.text.trim(), "Phone2": phoneController.text.trim(), "EMail": emailController.text.trim()});

      try {
        final infoResp = await put(Uri.parse('${EndPoints.adOrgInfo}/$_adOrgId'), headers: {'Content-Type': 'application/json', 'Authorization': Token.auth!}, body: bodyInfo);
        if (infoResp.statusCode != 200 && infoResp.statusCode != 204) success = false;
      } catch (e) {
        success = false;
      }
    }

    if (_cLocationId != null) {
      final locUrl = EndPoints.model('C_Location');

      final bodyLoc = jsonEncode({
        if (_selectedCountryId != null) "C_Country_ID": {"id": _selectedCountryId},
        if (_selectedCityId != null) "C_City_ID": {"id": _selectedCityId},
        "City": _currentCityName.trim(),
        "Address1": addressController.text.trim(),
        "Address2": address2Controller.text.trim(),
        "Address3": address3Controller.text.trim(),
        "Address4": address4Controller.text.trim(),
        "Postal": zipController.text.trim(),
      });

      print("-> Actualizando C_Location PUT: $locUrl/$_cLocationId");
      try {
        final locResp = await put(Uri.parse('$locUrl/$_cLocationId'), headers: {'Content-Type': 'application/json', 'Authorization': Token.auth!}, body: bodyLoc);
        print("<- Status C_Location PUT: ${locResp.statusCode}");
        if (locResp.statusCode != 200 && locResp.statusCode != 204) {
          success = false;
          print("<- Error C_Location: ${locResp.body}");
        }
      } catch (e) {
        success = false;
        print("<- Excepción en C_Location: $e");
      }
    }

    print("========== FIN GUARDADO ==========");

    setState(() {
      isLoading = false;
      if (success) _hasUnsavedChanges = false;
    });

    if (mounted) {
      if (success) {
        ToastMessage.show(context: context, message: AppLocale.settingsSavedSuccess.getString(context), type: ToastType.success);
      } else {
        ToastMessage.show(context: context, message: AppLocale.settingsSaveError.getString(context), type: ToastType.failure);
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
            if (isLoading) LinearProgressIndicator(minHeight: 3, backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1), valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.secondary)),

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
                        AppLocale.orgProfileTitle.getString(context),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // --- LOGO ---
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

                  const SizedBox(height: 32),

                  TextfieldTheme(controlador: nameController, texto: AppLocale.orgName.getString(context), icono: Icons.corporate_fare),
                  const SizedBox(height: 16),
                  TextfieldTheme(controlador: descController, texto: AppLocale.description.getString(context), icono: Icons.description_outlined),
                  const SizedBox(height: 16),
                  TextfieldTheme(controlador: codeController, texto: AppLocale.code.getString(context), icono: Icons.code_rounded),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),

                  TextfieldTheme(controlador: taxIdController, texto: AppLocale.identificationNumber.getString(context), icono: Icons.badge_outlined),
                  const SizedBox(height: 16),
                  TextfieldTheme(controlador: dvController, texto: AppLocale.dv.getString(context), icono: Icons.pin_outlined),
                  const SizedBox(height: 16),
                  TextfieldTheme(controlador: phoneController, texto: AppLocale.mobilePhone.getString(context), icono: Icons.phone_android_outlined, inputType: TextInputType.phone),
                  const SizedBox(height: 16),
                  TextfieldTheme(controlador: emailController, texto: AppLocale.email.getString(context), icono: Icons.email_outlined, inputType: TextInputType.emailAddress),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),

                  GestureDetector(
                    onTap: _showLocationDialog,
                    child: AbsorbPointer(
                      child: TextfieldTheme(controlador: locationController, texto: AppLocale.locationLabel.getString(context), icono: Icons.location_on_outlined, inputType: TextInputType.streetAddress),
                    ),
                  ),

                  const SizedBox(height: 32),

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
                                          secondChild: Text(
                                            AppLocale.saveChanges.getString(context),
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
