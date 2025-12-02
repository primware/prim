import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:primware/shared/custom_container.dart';
import 'package:primware/shared/custom_spacer.dart';
import '../../../API/lpa_config.dart';
import '../../../shared/button.widget.dart';
import '../../../shared/custom_dropdown.dart';
import '../../../shared/footer.dart';
import '../../../shared/shimmer_list.dart';
import '../../../shared/custom_textfield.dart';
import '../../../shared/toast_message.dart';
import 'bpartner_funtions.dart';
import '../../../localization/app_locale.dart';

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
  TextEditingController dvController = TextEditingController();
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

    // Precargar datos del tercero
    nameController.text = widget.bpartner['name'] ?? '';
    taxController.text = widget.bpartner['TaxID'] ?? '';
    locationController.text = widget.bpartner['location'] ?? '';
    emailController.text = widget.bpartner['email'] ?? '';
    locationController.text = widget.bpartner['locationName'] ?? '';
    dvController.text = widget.bpartner['dv'] ?? '';
    selectectCustomerTypeID =
        int.parse(widget.bpartner['TipoClienteFE'] ?? '02');
    //? Consumidor final por defecto
    selectedTaxTypeID = widget.bpartner['LCO_TaxIdType_ID'];
    selectedBPartnerGroupID = widget.bpartner['C_BP_Group_ID'];

    nameController.addListener(_isFormValid);
    emailController.addListener(_isFormValid);
    taxController.addListener(_isFormValid);
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
          selectedBPartnerGroupID != null &&
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
    locationController.removeListener(_isFormValid);
    dvController.removeListener(_isFormValid);
    super.dispose();
  }

  Future<void> _updateBPartner() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text(AppLocale.updateCustomer.getString(context)),
          content: Text(AppLocale.confirmUpdateCustomer.getString(context)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocale.cancel.getString(context)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                AppLocale.confirm.getString(context),
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
      dv: dvController.text,
      customerType: '0$selectectCustomerTypeID',
      context: context,
      userID: widget.bpartner['AD_User_ID'],
      locationID: widget.bpartner['C_BPartner_Location_ID'],
    );

    setState(() => isLoading = false);

    if (result['success'] == true) {
      Navigator.pop(context, {
        'created': true,
        'bpartner': nameController.text,
      });
    } else {
      ToastMessage.show(
        context: context,
        message: result['message'] ??
            AppLocale.errorUpdateCustomer.getString(context),
        type: ToastType.failure,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(AppLocale.customerDetail.getString(context)),
          centerTitle: true,
          leading: IconButton(
              onPressed: () => Navigator.pop(context, {
                    'created': false,
                  }),
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
                  _isTaxTypeLoading
                      ? ShimmerList(count: 1)
                      : SearchableDropdown<int>(
                          value: selectedTaxTypeID,
                          options: taxTypes,
                          showSearchBox: false,
                          labelText: AppLocale.personTypeReq.getString(context),
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
                          labelText: AppLocale.groupReq.getString(context),
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
