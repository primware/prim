import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:primware/API/lpa_config.dart';
import 'package:primware/shared/custom_container.dart';
import 'package:primware/shared/custom_spacer.dart';
import '../../../shared/button.widget.dart';
import '../../../shared/custom_dropdown.dart';
import '../../../shared/footer.dart';
import '../../../shared/shimmer_list.dart';
import '../../../shared/custom_textfield.dart';
import '../../../theme/colors.dart';
import '../../../localization/app_locale.dart';
import 'bpartner_funtions.dart';

class BPartnerNewPage extends StatefulWidget {
  final String? bpartnerName;

  const BPartnerNewPage({super.key, this.bpartnerName});

  @override
  State<BPartnerNewPage> createState() => _BPartnerNewPageState();
}

class _BPartnerNewPageState extends State<BPartnerNewPage> {
  TextEditingController nameController = TextEditingController();
  TextEditingController taxController = TextEditingController();
  TextEditingController dvController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  TextEditingController emailController = TextEditingController();

  bool isValid = false,
      isLoading = false,
      _isTaxTypeLoading = true,
      _isGroupLoading = true,
      _taxTypeError = false;

  int? selectedTaxTypeID, selectedBPartnerGroupID, selectectCustomerTypeID;

  List<Map<String, dynamic>> taxTypes = [],
      bPartnerGroups = [],
      customerTypeOptions = TipoClienteFE.options;

  @override
  void initState() {
    super.initState();
    _loadTaxType();
    _loadBPartnerGroups();
    if (widget.bpartnerName != null) {
      nameController.text = widget.bpartnerName!;
    }

    selectectCustomerTypeID = 02; //? Consumidor final

    nameController.addListener(_isFormValid);
    locationController.addListener(_isFormValid);
    dvController.addListener(_isFormValid);
  }

  Future<void> _loadTaxType() async {
    final fetchedTaxTypes = await getCTaxTypeID(context) ?? [];
    /*if (fetchedTaxTypes != null) {
      setState(() {
        taxTypes = fetchedTaxTypes;
        _isTaxTypeLoading = false;
      });
    }*/
    setState(() {
      taxTypes = fetchedTaxTypes;
      _isTaxTypeLoading = false;
      _taxTypeError = taxTypes.isEmpty;
    });
  }

  Future<void> _loadBPartnerGroups() async {
    final fetchedGroups = await getCBPGroup(context) ?? [];
    /*if (fetchedGroups != null) {
      setState(() {
        bPartnerGroups = fetchedGroups;
        _isGroupLoading = false;
      });
    }*/
    setState(() {
      bPartnerGroups = fetchedGroups;
      _isGroupLoading = false;
    });
  }

  void clearPartnerFields() {
    nameController.clear();
    locationController.clear();
    taxController.clear();
    emailController.clear();
    dvController.clear();
  }

  void _isFormValid() {
    setState(() {
      bool hasDV =
          (selectectCustomerTypeID == 1 && dvController.text.isNotEmpty) ||
              selectectCustomerTypeID != 1;

      isValid = nameController.text.isNotEmpty &&
          locationController.text.isNotEmpty &&
          selectedTaxTypeID != null &&
          selectedBPartnerGroupID != null &&
          selectectCustomerTypeID != null &&
          hasDV &&
          !_taxTypeError;
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
    emailController.removeListener(_isFormValid);
    taxController.removeListener(_isFormValid);
    locationController.removeListener(_isFormValid);
    dvController.removeListener(_isFormValid);

    super.dispose();
  }

  Future<void> _createBPartner() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text(AppLocale.createCustomer.getString(context)),
          content: Text(AppLocale.confirmCreateCustomer.getString(context)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocale.cancel.getString(context)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                AppLocale.confirm.getString(context),
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

    final result = await postBPartner(
      name: nameController.text,
      location: locationController.text,
      taxID: taxController.text,
      cBPartnerGroupID: selectedBPartnerGroupID!,
      email: emailController.text,
      cTaxTypeID: selectedTaxTypeID!,
      dv: dvController.text,
      customerType: '0$selectectCustomerTypeID',
      context: context,
    );

    setState(() => isLoading = false);

    if (result['success'] == true) {
      clearPartnerFields();
      Navigator.pop(context, {
        'created': true,
        'bpartner': result['bpartner'],
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(
              child: Text(result['message'] ??
                  AppLocale.errorCreateCustomer.getString(context))),
          backgroundColor: ColorTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            AppLocale.newCustomer.getString(context),
          ),
          leading: IconButton(
              onPressed: () => Navigator.pop(context, false),
              icon: Icon(Icons.arrow_back)),
        ),
        bottomNavigationBar: CustomFooter(),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: CustomContainer(
                  child: Column(
                children: [
                  SearchableDropdown<int>(
                    value: selectectCustomerTypeID,
                    options: customerTypeOptions,
                    showSearchBox: false,
                    labelText: AppLocale.customerType.getString(context),
                    onChanged: (int? newValue) {
                      setState(() {
                        selectectCustomerTypeID = newValue;
                        _isFormValid();
                      });
                    },
                  ),
                  const SizedBox(height: CustomSpacer.medium),
                  TextfieldTheme(
                    controlador: nameController,
                    texto: AppLocale.nameReq.getString(context),
                    colorEmpty: nameController.text.isEmpty,
                    inputType: TextInputType.name,
                  ),

                  const SizedBox(height: CustomSpacer.medium),
                  _isGroupLoading
                      ? ShimmerList(
                          count: 1,
                        )
                      : SearchableDropdown<int>(
                          value: selectedBPartnerGroupID,
                          options: bPartnerGroups,
                          showSearchBox: false,
                          labelText: AppLocale.groupReq.getString(context),
                          onChanged: (int? newValue) {
                            setState(() {
                              selectedBPartnerGroupID = newValue;
                              _isFormValid();
                            });
                          },
                        ),
                  const SizedBox(height: CustomSpacer.medium),
                  _isTaxTypeLoading
                      ? ShimmerList(
                          count: 1,
                        )
                      : (taxTypes != []) //? Si no hay tipos de persona
                          ? SearchableDropdown<int>(
                              value: selectedTaxTypeID,
                              options: taxTypes,
                              showSearchBox: false,
                              labelText:
                                  AppLocale.personTypeReq.getString(context),
                              onChanged: (int? newValue) {
                                setState(() {
                                  selectedTaxTypeID = newValue;
                                  _isFormValid();
                                });
                              },
                            )
                          : const SizedBox(),
                  // Mensaje de error si taxTypes está vacío
                  /*if (_taxTypeError && !_isTaxTypeLoading)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                              child: Text(
                                AppLocale.noTaxTypesAvailable.getString(context),
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),*/
                  const SizedBox(height: CustomSpacer.medium),
                  TextfieldTheme(
                    controlador: taxController,
                    texto: AppLocale.taxId.getString(context),
                    inputType: TextInputType.text,
                  ),
                  const SizedBox(height: CustomSpacer.medium),
                  TextfieldTheme(
                    controlador: dvController,
                    texto:
                        '${AppLocale.dv.getString(context)}${selectectCustomerTypeID == 1 ? ' *' : ''}',
                    colorEmpty: selectectCustomerTypeID == 1 &&
                        dvController.text.isEmpty,
                    inputType: TextInputType.text,
                  ),
                  const SizedBox(height: CustomSpacer.medium),
                  TextfieldTheme(
                    controlador: emailController,
                    texto: AppLocale.email.getString(context),
                    colorEmpty: !isValidEmail(emailController.text),
                    inputType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: CustomSpacer.medium),
                  TextfieldTheme(
                    controlador: locationController,
                    texto: AppLocale.addressReq.getString(context),
                    colorEmpty: locationController.text.isEmpty,
                    inputType: TextInputType.name,
                  ),
                  const SizedBox(height: CustomSpacer.xlarge),
                  if (!isLoading) ...[
                    ButtonSecondary(
                      fullWidth: true,
                      texto: AppLocale.cancel.getString(context),
                      onPressed: () {
                        clearPartnerFields();
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
                                texto: AppLocale.save.getString(context),
                                onPressed: _createBPartner,
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
