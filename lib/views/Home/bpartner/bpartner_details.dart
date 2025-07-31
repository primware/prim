import 'package:flutter/material.dart';
import 'package:primware/shared/custom_container.dart';
import 'package:primware/shared/custom_spacer.dart';
import '../../../shared/button.widget.dart';
import '../../../shared/custom_dropdown.dart';
import '../../../shared/shimmer_list.dart';
import '../../../shared/textfield.widget.dart';
import '../../../theme/colors.dart';
import 'bpartner_funtions.dart';

class BPartnerDetailPage extends StatefulWidget {
  final Map<String, dynamic> bpartner;

  const BPartnerDetailPage({super.key, required this.bpartner});

  @override
  State<BPartnerDetailPage> createState() => _BPartnerDetailPageState();
}

class _BPartnerDetailPageState extends State<BPartnerDetailPage> {
  TextEditingController nameController = TextEditingController();
  TextEditingController taxController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  TextEditingController emailController = TextEditingController();

  bool isValid = false,
      isLoading = false,
      _isTaxTypeLoading = true,
      _isGroupLoading = true;

  int? selectedTaxTypeID, selectedBPartnerGroupID;

  List<Map<String, dynamic>> taxTypes = [], bPartnerGroups = [];

  @override
  void initState() {
    super.initState();
    _loadTaxType();
    _loadBPartnerGroups();

    // Precargar datos del tercero
    nameController.text = widget.bpartner['name'] ?? '';
    taxController.text = widget.bpartner['TaxID'] ?? '';
    locationController.text = widget.bpartner['location'] ?? '';
    emailController.text = widget.bpartner['email'] ?? '';
    locationController.text = widget.bpartner['locationName'] ?? '';

    selectedTaxTypeID = widget.bpartner['LCO_TaxIdType_ID'];
    selectedBPartnerGroupID = widget.bpartner['C_BP_Group_ID'];

    nameController.addListener(_isFormValid);
    emailController.addListener(_isFormValid);
    taxController.addListener(_isFormValid);
    locationController.addListener(_isFormValid);
  }

  Future<void> _loadTaxType() async {
    final fetchedTaxTypes = await getCTaxTypeID(context);
    if (fetchedTaxTypes != null) {
      setState(() {
        taxTypes = fetchedTaxTypes;
        _isTaxTypeLoading = false;
      });
    }
  }

  Future<void> _loadBPartnerGroups() async {
    final fetchedGroups = await getCBPGroup(context);
    if (fetchedGroups != null) {
      setState(() {
        bPartnerGroups = fetchedGroups;
        _isGroupLoading = false;
        _isFormValid();
      });
    }
  }

  void _isFormValid() {
    setState(() {
      isValid = nameController.text.isNotEmpty &&
          locationController.text.isNotEmpty &&
          selectedTaxTypeID != null &&
          selectedBPartnerGroupID != null;
    });
  }

  bool isValidEmail(String email) {
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  @override
  void dispose() {
    nameController.removeListener(_isFormValid);
    locationController.removeListener(_isFormValid);
    super.dispose();
  }

  Future<void> _updateBPartner() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: const Text('Actualizar cliente'),
          content:
              const Text('¿Está seguro de que desea actualizar el cliente?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Confirmar',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.surface),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => isLoading = true);

    final result = await putBPartner(
      id: widget.bpartner['id'],
      name: nameController.text,
      location: locationController.text,
      taxID: taxController.text,
      cBPartnerGroupID: selectedBPartnerGroupID!,
      email: emailController.text,
      cTaxTypeID: selectedTaxTypeID!,
      context: context,
      userID: widget.bpartner['AD_User_ID'],
      locationID: widget.bpartner['C_BPartner_Location_ID'],
    );

    setState(() => isLoading = false);

    if (result['success'] == true) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(
              child: Text(result['message'] ?? 'Error al actualizar cliente')),
          backgroundColor: ColorTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Detalle cliente'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: CustomContainer(
                  child: Column(
                children: [
                  TextfieldTheme(
                    controlador: nameController,
                    texto: 'Nombre *',
                    colorEmpty:
                        nameController.text.isEmpty ? ColorTheme.error : null,
                    inputType: TextInputType.name,
                  ),
                  const SizedBox(height: CustomSpacer.medium),
                  _isTaxTypeLoading
                      ? ShimmerList(count: 1)
                      : SearchableDropdown<int>(
                          value: selectedTaxTypeID,
                          options: taxTypes,
                          showSearchBox: false,
                          labelText: 'Persona *',
                          onChanged: (int? newValue) {
                            setState(() {
                              selectedTaxTypeID = newValue;
                              _isFormValid();
                            });
                          },
                        ),
                  const SizedBox(height: CustomSpacer.medium),
                  _isGroupLoading
                      ? ShimmerList(count: 1)
                      : SearchableDropdown<int>(
                          value: selectedBPartnerGroupID,
                          options: bPartnerGroups,
                          showSearchBox: false,
                          labelText: 'Grupo *',
                          onChanged: (int? newValue) {
                            setState(() {
                              selectedBPartnerGroupID = newValue;
                              _isFormValid();
                            });
                          },
                        ),
                  const SizedBox(height: CustomSpacer.medium),
                  TextfieldTheme(
                    controlador: taxController,
                    texto: 'Nro. de identificación',
                    inputType: TextInputType.text,
                  ),
                  const SizedBox(height: CustomSpacer.medium),
                  TextfieldTheme(
                    controlador: emailController,
                    texto: 'Correo electrónico',
                    colorEmpty: !isValidEmail(emailController.text)
                        ? ColorTheme.error
                        : null,
                    inputType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: CustomSpacer.medium),
                  TextfieldTheme(
                    controlador: locationController,
                    texto: 'Dirección *',
                    colorEmpty: locationController.text.isEmpty
                        ? ColorTheme.error
                        : null,
                    inputType: TextInputType.name,
                  ),
                  const SizedBox(height: CustomSpacer.xlarge),
                  if (!isLoading) ...[
                    ButtonSecondary(
                      fullWidth: true,
                      texto: 'Cancelar',
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: CustomSpacer.medium)
                  ],
                  Container(
                    child: isValid
                        ? isLoading
                            ? ButtonLoading(fullWidth: true)
                            : ButtonPrimary(
                                fullWidth: true,
                                texto: 'Actualizar',
                                onPressed: _updateBPartner,
                              )
                        : null,
                  )
                ],
              )),
            ),
          ),
        ));
  }
}
