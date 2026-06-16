import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../../API/pos.api.dart';
import '../../../localization/app_locale.dart';
import '../../../shared/button.widget.dart';
import '../../../shared/custom_container.dart';
import '../../../shared/custom_dropdown.dart';
import '../../../shared/custom_textfield.dart';
import '../../../shared/footer.dart';
import '../../../shared/toast_message.dart';
import 'pos_printer_functions.dart';
import 'settings_funtions.dart';
class OrgSettingsPage extends StatelessWidget {
  const OrgSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocale.orgProfileTitle.getString(context).replaceAll('\n', ' '))),
      body: const SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Center(
            child: Padding(padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16), child: OrgSettingsCard()),
          ),
        ),
      ),
      bottomNavigationBar: const CustomFooter(),
    );
  }
}

class OrgSettingsCard extends StatefulWidget {
  const OrgSettingsCard({super.key});

  @override
  State<OrgSettingsCard> createState() => _OrgSettingsCardState();
}

class _OrgSettingsCardState extends State<OrgSettingsCard> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController taxIdController = TextEditingController();
  final TextEditingController dvController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  final TextEditingController header1Controller = TextEditingController();
  final TextEditingController header2Controller = TextEditingController();
  final TextEditingController header3Controller = TextEditingController();
  final TextEditingController header4Controller = TextEditingController();
  final TextEditingController footer1Controller = TextEditingController();
  final TextEditingController footer2Controller = TextEditingController();
  final TextEditingController footer3Controller = TextEditingController();
  final TextEditingController footer4Controller = TextEditingController();
  final TextEditingController printerConfigDisplayController = TextEditingController();

  List<Map<String, dynamic>> _countries = [];
  List<Map<String, dynamic>> _cities = [];
  int? _selectedCountryId;
  int? _selectedCityId;
  String _currentCityName = '';

  bool isLoading = true;
  bool _hasUnsavedChanges = false;
  Uint8List? _localLogoBytes;

  double _logoScale = 1.0;
  double _saveScale = 1.0;

  int? _adOrgId;
  int? _cLocationId;
  int? _printerConfigId;

  bool get _isRucValid => taxIdController.text.trim().isNotEmpty;
  bool get _canSave => !isLoading && _hasUnsavedChanges && _isRucValid;

  @override
  void initState() {
    super.initState();
    _localLogoBytes = POSPrinter.logo;
    _addFieldListeners();
    _loadInitialData();
  }

  void _addFieldListeners() {
    for (final controller in [
      nameController, taxIdController, dvController, phoneController, emailController, addressController,
      header1Controller, header2Controller, header3Controller, header4Controller,
      footer1Controller, footer2Controller, footer3Controller, footer4Controller,
    ]) {
      controller.addListener(_onFieldChanged);
    }
  }

  Future<void> _loadInitialData() async {
    setState(() => isLoading = true);

    final countries = await fetchCountries(context: context);
    if (!mounted) return;
    _countries = countries;

    final settings = await fetchOrganizationSettings(context: context);
    if (!mounted) return;

    if (settings != null) {
      _applyOrganizationSettings(settings);
      if (_selectedCountryId != null) {
        _cities = await fetchCities(context: context, countryId: _selectedCountryId!);
        if (!mounted) return;
      }
    }

    if (POS.isPOS && POS.cPosID != null) {
      final printerConfig = await fetchPOSPrinterConfig(context: context, posId: POS.cPosID!);
      if (!mounted) return;
      if (printerConfig != null) {
        _printerConfigId = printerConfig['id'] as int?;
        header1Controller.text = printerConfig['Header1']?.toString() ?? '';
        header2Controller.text = printerConfig['Header2']?.toString() ?? '';
        header3Controller.text = printerConfig['Header3']?.toString() ?? '';
        header4Controller.text = printerConfig['Header4']?.toString() ?? '';
        footer1Controller.text = printerConfig['Footer1']?.toString() ?? '';
        footer2Controller.text = printerConfig['Footer2']?.toString() ?? '';
        footer3Controller.text = printerConfig['Footer3']?.toString() ?? '';
        footer4Controller.text = printerConfig['Footer4']?.toString() ?? '';
        printerConfigDisplayController.text = 'Configuración cargada';
      }
    }

    setState(() {
      isLoading = false;
      _hasUnsavedChanges = false;
    });
  }

  void _applyOrganizationSettings(Map<String, dynamic> settings) {
    _adOrgId = settings['adOrgId'] as int?;
    _cLocationId = settings['cLocationId'] as int?;
    _selectedCountryId = settings['countryId'] as int?;
    _selectedCityId = settings['cityId'] as int?;
    _currentCityName = settings['cityName']?.toString() ?? '';

    nameController.text = settings['name']?.toString() ?? '';
    taxIdController.text = settings['taxId']?.toString() ?? '';
    dvController.text = settings['dv']?.toString() ?? '';
    phoneController.text = settings['phone']?.toString() ?? '';
    emailController.text = settings['email']?.toString() ?? '';
    addressController.text = settings['address1']?.toString() ?? '';
    locationController.text = settings['visualAddress']?.toString() ?? '';
  }

  void _onFieldChanged() {
    if (isLoading) return;
    setState(() => _hasUnsavedChanges = true);
  }

  @override
  void dispose() {
    nameController.dispose();
    locationController.dispose();
    taxIdController.dispose();
    dvController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    header1Controller.dispose();
    header2Controller.dispose();
    header3Controller.dispose();
    header4Controller.dispose();
    footer1Controller.dispose();
    footer2Controller.dispose();
    footer3Controller.dispose();
    footer4Controller.dispose();
    printerConfigDisplayController.dispose();
    super.dispose();
  }

  bool get _canCropImage {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<ImageSource?> _resolveLogoImageSource() async {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
      return showModalBottomSheet<ImageSource>(
        context: context,
        builder: (context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: Text(AppLocale.logoTakePhoto.getString(context)),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: Text(AppLocale.logoSelectImage.getString(context)),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          );
        },
      );
    }

    return ImageSource.gallery;
  }

  Future<void> _pickAndCropImage() async {
    final source = await _resolveLogoImageSource();
    if (source == null) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(source: source, imageQuality: 80);
    if (image == null) return;

    if (!_canCropImage) {
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        _localLogoBytes = bytes;
        _hasUnsavedChanges = true;
      });
      return;
    }

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: image.path,
      aspectRatio: const CropAspectRatio(ratioX: 3, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: AppLocale.adjustLogo.getString(context),
          toolbarColor: Theme.of(context).primaryColor,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.ratio16x9,
          lockAspectRatio: true,
          aspectRatioPresets: const [CropAspectRatioPreset.ratio16x9, CropAspectRatioPreset.ratio4x3],
        ),
        IOSUiSettings(
          title: AppLocale.adjustLogo.getString(context),
          aspectRatioLockEnabled: true,
          doneButtonTitle: AppLocale.done.getString(context),
          cancelButtonTitle: AppLocale.cancel.getString(context),
          aspectRatioPresets: const [CropAspectRatioPreset.ratio16x9, CropAspectRatioPreset.ratio4x3],
        ),
      ],
    );

    if (croppedFile == null) return;
    final bytes = await croppedFile.readAsBytes();
    if (!mounted) return;

    setState(() {
      _localLogoBytes = bytes;
      _hasUnsavedChanges = true;
    });
  }

  void _showLocationDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
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
                    SearchableDropdown<int>(
                      value: _selectedCountryId,
                      options: _countries,
                      labelText: AppLocale.country.getString(context),
                      onChanged: (newValue) async {
                        setStateDialog(() {
                          _selectedCountryId = newValue;
                          _selectedCityId = null;
                          _currentCityName = '';
                          _cities = [];
                        });
                        setState(() => _hasUnsavedChanges = true);
                        if (newValue != null) {
                          final cities = await fetchCities(context: this.context, countryId: newValue);
                          if (!mounted) return;
                          setState(() => _cities = cities);
                          setStateDialog(() {});
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    SearchableDropdown<int>(
                      value: _selectedCityId,
                      options: _cities,
                      labelText: AppLocale.city.getString(context),
                      onChanged: (newValue) {
                        setStateDialog(() {
                          _selectedCityId = newValue;
                          Map<String, dynamic>? selectedCity;
                          for (final city in _cities) {
                            if (city['id'] == newValue) {
                              selectedCity = city;
                              break;
                            }
                          }
                          _currentCityName = selectedCity?['name']?.toString() ?? '';
                        });
                        setState(() => _hasUnsavedChanges = true);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextfieldTheme(
                      controlador: addressController,
                      texto: AppLocale.address1.getString(context),
                      icono: Icons.streetview_outlined,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(AppLocale.cancel.getString(context), style: TextStyle(color: Colors.grey.shade600)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    setState(() {
                      locationController.text = addressController.text.trim().isNotEmpty
                          ? addressController.text.trim()
                          : AppLocale.addressUpdated.getString(context);
                      _hasUnsavedChanges = true;
                    });
                    Navigator.of(dialogContext).pop();
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

  void _showPrinterConfigDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.print_outlined, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Expanded(child: Text(AppLocale.posPrinterConfig.getString(context))),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextfieldTheme(controlador: header1Controller, texto: '${AppLocale.headerText.getString(context)} 1', icono: Icons.title),
                const SizedBox(height: 16),
                TextfieldTheme(controlador: header2Controller, texto: '${AppLocale.headerText.getString(context)} 2', icono: Icons.title),
                const SizedBox(height: 16),
                TextfieldTheme(controlador: header3Controller, texto: '${AppLocale.headerText.getString(context)} 3', icono: Icons.title),
                const SizedBox(height: 16),
                TextfieldTheme(controlador: header4Controller, texto: '${AppLocale.headerText.getString(context)} 4', icono: Icons.title),
                const SizedBox(height: 16),
                TextfieldTheme(controlador: footer1Controller, texto: '${AppLocale.footerText.getString(context)} 1', icono: Icons.text_snippet_outlined),
                const SizedBox(height: 16),
                TextfieldTheme(controlador: footer2Controller, texto: '${AppLocale.footerText.getString(context)} 2', icono: Icons.text_snippet_outlined),
                const SizedBox(height: 16),
                TextfieldTheme(controlador: footer3Controller, texto: '${AppLocale.footerText.getString(context)} 3', icono: Icons.text_snippet_outlined),
                const SizedBox(height: 16),
                TextfieldTheme(controlador: footer4Controller, texto: '${AppLocale.footerText.getString(context)} 4', icono: Icons.text_snippet_outlined),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                setState(() => _hasUnsavedChanges = true);
                printerConfigDisplayController.text = 'Configuración actualizada';
                Navigator.of(dialogContext).pop();
              },
              child: Text(AppLocale.accept.getString(context), style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveOrganization() async {
    if (!_isRucValid) {
      ToastMessage.show(
        context: context,
        message: '${AppLocale.identificationNumber.getString(context)}: ${AppLocale.requiredField.getString(context)}',
        type: ToastType.warning,
      );
      return;
    }

    setState(() => isLoading = true);
    var success = true;

    final hasLogoChange = _localLogoBytes != null && !listEquals(_localLogoBytes, POSPrinter.logo);
    if (hasLogoChange) {
      final logoOk = await updateOrgLogo(fileBytes: _localLogoBytes!, context: context);
      if (!mounted) return;
      if (logoOk) {
        POSPrinter.logo = _localLogoBytes;
        POSPrinter.isLogoSet = true;
      } else {
        success = false;
        ToastMessage.show(context: context, message: AppLocale.errorUploadingLogo.getString(context), type: ToastType.failure);
      }
    }

    final settingsOk = await saveOrganizationSettings(
      context: context,
      adOrgId: _adOrgId,
      cLocationId: _cLocationId,
      name: nameController.text,
      taxId: taxIdController.text,
      dv: dvController.text,
      phone: phoneController.text,
      email: emailController.text,
      countryId: _selectedCountryId,
      cityId: _selectedCityId,
      cityName: _currentCityName,
      address1: addressController.text,
    );
    if (!mounted) return;

    success = success && settingsOk;

    if (POS.isPOS && POS.cPosID != null && success) {
      final printerOk = await savePOSPrinterConfig(
        context: context,
        posId: POS.cPosID!,
        configId: _printerConfigId,
        header1: header1Controller.text.trim(),
        header2: header2Controller.text.trim(),
        header3: header3Controller.text.trim(),
        header4: header4Controller.text.trim(),
        footer1: footer1Controller.text.trim(),
        footer2: footer2Controller.text.trim(),
        footer3: footer3Controller.text.trim(),
        footer4: footer4Controller.text.trim(),
      );
      if (!mounted) return;
      success = success && printerOk;
    }

    if (success) {
      POSPrinter.headerName = nameController.text.trim();
      POSPrinter.headerTaxID = taxIdController.text.trim();
      POSPrinter.headerDV = dvController.text.trim();
      POSPrinter.headerPhone = phoneController.text.trim();
      POSPrinter.headerEmail = emailController.text.trim();

      final refreshedSettings = await fetchOrganizationSettings(context: context);
      if (!mounted) return;
      if (refreshedSettings != null) {
        _applyOrganizationSettings(refreshedSettings);
      }
    }

    setState(() {
      isLoading = false;
      if (success) _hasUnsavedChanges = false;
    });

    ToastMessage.show(
      context: context,
      message: success ? AppLocale.settingsSavedSuccess.getString(context) : AppLocale.settingsSaveError.getString(context),
      type: success ? ToastType.success : ToastType.failure,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomContainer(
      maxWidthContainer: 560,
      padding: 0,
      child: Column(
        children: [
          if (isLoading)
            SizedBox(
              width: 550,
              child: LinearProgressIndicator(
                minHeight: 3,
                backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.secondary),
                borderRadius: BorderRadius.circular(50),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppLocale.logoSelectImage.getString(context),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTapDown: isLoading ? null : (_) => setState(() => _logoScale = 0.92),
                  onTapUp: isLoading
                      ? null
                      : (_) {
                          Future.delayed(const Duration(milliseconds: 100), () {
                            if (mounted) setState(() => _logoScale = 1.0);
                          });
                        },
                  onTapCancel: () => setState(() => _logoScale = 1.0),
                  onTap: isLoading ? null : _pickAndCropImage,
                  child: AnimatedScale(
                    scale: _logoScale,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    child: AspectRatio(
                      aspectRatio: 3 / 1,
                      child: Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.25), width: 1.5),
                            ),
                            child: Opacity(
                              opacity: isLoading ? 0.3 : 1.0,
                              child: _localLogoBytes == null
                                  ? Center(
                                      child: Icon(
                                        Icons.storefront_rounded,
                                        size: 56,
                                        color: Theme.of(context).primaryColor.withOpacity(0.45),
                                      ),
                                    )
                                  : Image.memory(_localLogoBytes!, width: double.infinity, height: double.infinity, fit: BoxFit.contain),
                            ),
                          ),
                          if (isLoading) const Positioned.fill(child: Center(child: CircularProgressIndicator())),
                          if (!isLoading)
                            Positioned(
                              right: 12,
                              bottom: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  borderRadius: BorderRadius.circular(999),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 4))],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      AppLocale.logoSelectImage.getString(context),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 520;
                    final children = [
                      TextfieldTheme(controlador: nameController, texto: AppLocale.orgName.getString(context), icono: Icons.corporate_fare),
                      TextfieldTheme(
                        controlador: taxIdController,
                        texto: '${AppLocale.identificationNumber.getString(context)} *',
                        icono: Icons.badge_outlined,
                        colorEmpty: taxIdController.text.trim().isEmpty,
                      ),
                    ];

                    if (!isWide) {
                      return Column(children: [children[0], const SizedBox(height: 16), children[1]]);
                    }

                    return Row(
                      children: [
                        Expanded(child: children[0]),
                        const SizedBox(width: 16),
                        Expanded(child: children[1]),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 520;
                    final children = [
                      TextfieldTheme(controlador: dvController, texto: AppLocale.dv.getString(context), icono: Icons.pin_outlined),
                      TextfieldTheme(
                        controlador: phoneController,
                        texto: AppLocale.mobilePhone.getString(context),
                        icono: Icons.phone_android_outlined,
                        inputType: TextInputType.phone,
                      ),
                    ];

                    if (!isWide) {
                      return Column(children: [children[0], const SizedBox(height: 16), children[1]]);
                    }

                    return Row(
                      children: [
                        Expanded(child: children[0]),
                        const SizedBox(width: 16),
                        Expanded(child: children[1]),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextfieldTheme(
                  controlador: emailController,
                  texto: AppLocale.email.getString(context),
                  icono: Icons.email_outlined,
                  inputType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: isLoading ? null : _showLocationDialog,
                  child: AbsorbPointer(
                    child: TextfieldTheme(
                      controlador: locationController,
                      texto: AppLocale.locationLabel.getString(context),
                      icono: Icons.location_on_outlined,
                      inputType: TextInputType.streetAddress,
                    ),
                  ),
                ),
                if (POS.isPOS) ...[
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: isLoading ? null : _showPrinterConfigDialog,
                    child: AbsorbPointer(
                      child: TextfieldTheme(
                        controlador: printerConfigDisplayController,
                        texto: AppLocale.posPrinterConfig.getString(context),
                        icono: Icons.print_outlined,
                        inputType: TextInputType.text,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTapDown: _canSave ? (_) => setState(() => _saveScale = 0.95) : null,
                    onTapUp: _canSave
                        ? (_) {
                            Future.delayed(const Duration(milliseconds: 100), () {
                              if (mounted) {
                                setState(() => _saveScale = 1.0);
                              }
                            });
                          }
                        : null,
                    onTapCancel: () => setState(() => _saveScale = 1.0),
                    child: AnimatedScale(
                      scale: _saveScale,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      child: ButtonPrimary(texto: AppLocale.saveChanges.getString(context), onPressed: _canSave ? _saveOrganization : null),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
