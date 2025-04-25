// import 'dart:convert';
// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:intl/intl.dart';
// import '../../../shared/loadingContainer.dart';
// import '../../../theme/colors.dart';
// import '../../../theme/formatter.dart';
// import 'customer_controllers.dart';
// import 'customer_funtions.dart';

// class CustomerPage extends StatefulWidget {
//   const CustomerPage({super.key});

//   @override
//   State<CustomerPage> createState() => _CustomerPageState();
// }

// class _CustomerPageState extends State<CustomerPage> {
//   bool isLoading = true, isValid = false, isUnderage = false;
//   String? _imageBase64;
//   List<Map<String, dynamic>> salesRepOptions = [];
//   int? selectedSalesRepID;
//   List<Map<String, dynamic>> stateOptions = [];
//   List<Map<String, dynamic>> subStateOptions = [];
//   int? selectedStateID;
//   int? selectedSubStateID;
//   Uint8List? _imageBytes;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _loadOptions();
//       _validateForm();
//     });
//   }

//   Future<void> _loadOptions() async {
//     final salesRep = await fetchSalesRep(context: context);
//     final states = await fetchCustomStateSales(context: context);
//     setState(() {
//       salesRepOptions = salesRep;
//       stateOptions = states;
//       isLoading = false;
//     });
//   }

//   void _updateSubStateOptions(int? stateID) {
//     final selectedState = stateOptions.firstWhere(
//       (state) => state['id'] == stateID,
//       orElse: () => {},
//     );

//     setState(() {
//       subStateOptions = (selectedState.containsKey('subStates') &&
//               selectedState['subStates'] is List)
//           ? List<Map<String, dynamic>>.from(selectedState['subStates'])
//           : [];
//       selectedSubStateID = null;
//     });
//   }

//   bool isValidEmail(String email) {
//     final emailRegex =
//         RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
//     return emailRegex.hasMatch(email);
//   }

//   bool isValidPhone(String phone) {
//     return phone.replaceAll(RegExp(r'\D'), '').length >= 8;
//   }

//   bool _isAdult(DateTime? birthday) {
//     if (birthday == null) return false;

//     final today = DateTime.now();
//     final age = today.year - birthday.year;
//     final isBeforeBirthday = (today.month < birthday.month) ||
//         (today.month == birthday.month && today.day < birthday.day);

//     return age > 18 || (age == 18 && !isBeforeBirthday);
//   }

//   void _fillCustomerFields(Map<String, dynamic> customer) {
//     setState(() {
//       idController.text = customer['value'];
//       taxIdController.text = customer['taxId'];
//       nombreController.text = customer['name'];
//       apellidoController.text = customer['name2'];
//       correoController.text = customer['email'];
//       telefonoController.text = customer['phone'];
//       movilController.text = customer['mobile'];
//       cumpleanosController.text = customer['birthday'];
//       direccionController.text = customer['address'];
//       comentariosController.text = customer['comments'];
//       selectedSalesRepID = customer['salesRep']?['id'];
//       selectedStateID = customer['customState']?['id'];
//       selectedSubStateID = customer['customSubState']?['id'];
//       currentPartnerIDController.text = customer['partnerID'].toString();
//       currentUserIDController.text = customer['userID'].toString();
//       if (customer['AD_Image_ID'] != null) {
//         setState(() {
//           _imageBase64 = customer['AD_Image_ID'];
//           _imageBytes = base64Decode(_imageBase64!);
//         });
//       }

//       _validateForm();
//     });
//   }

//   void _showCustomerSelectionDialog(List<Map<String, dynamic>> customers) {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return Dialog(
//           title: Center(child: const Text("Seleccionar Cliente")),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: customers.map((customer) {
//               return fluent.ListTile(
//                 title: Text("${customer['name']} - ${customer['taxId']}"),
//                 subtitle: Text("Correo: ${customer['email']}"),
//                 onPressed: () {
//                   _fillCustomerFields(customer);
//                   Navigator.pop(context);
//                 },
//               );
//             }).toList(),
//           ),
//           actions: [
//             fluent.Button(
//               child: const Text("Cancelar"),
//               onPressed: () {
//                 Navigator.pop(context);
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Future<void> _searhCustomer() async {
//     clearCustomerControllers();
//     clearCustomerControllers();
//     setState(() {
//       _imageBase64 = null;
//       _imageBytes = null;
//     });
//     if (searchController.text.trim().isEmpty) {
//       showInfoBar(context, "Ingrese un ID o Nro de Identificación para buscar.",
//           severity: fluent.InfoBarSeverity.warning);
//       return;
//     }

//     setState(() {
//       isLoading = true;
//     });

//     List<Map<String, dynamic>> customers =
//         await fetchCustomer(id: searchController.text.trim(), context: context);

//     setState(() {
//       isLoading = false;
//     });

//     if (customers.isEmpty) {
//       showInfoBar(context,
//           "No se encontraron clientes con ese ID o Nro de Identificación.",
//           severity: fluent.InfoBarSeverity.warning);
//     } else if (customers.length == 1) {
//       _fillCustomerFields(customers.first);
//     } else {
//       _showCustomerSelectionDialog(customers);
//     }
//   }

//   void _validateForm() {
//     if (cumpleanosController.text.isNotEmpty) {
//       final birthday =
//           DateFormat('yyyy-MM-dd').parse(cumpleanosController.text, true);
//       isUnderage = !_isAdult(birthday);
//     }

//     setState(() {
//       isValid = nombreController.text.isNotEmpty &&
//           apellidoController.text.isNotEmpty &&
//           isValidEmail(correoController.text) &&
//           isValidPhone(movilController.text) &&
//           taxIdController.text.isNotEmpty &&
//           selectedSalesRepID != null &&
//           selectedStateID != null;
//     });
//   }

//   Future<void> _saveOrUpdateCustomer() async {
//     setState(() {
//       isLoading = true;
//     });

// //? En caso de que el cliente ya exista, se actualiza
//     if (currentPartnerIDController.text.isNotEmpty &&
//         currentUserIDController.text.isNotEmpty) {
//       bool success = await putUpdateCustomer(
//           partnerID: int.parse(currentPartnerIDController.text),
//           userID: int.parse(currentUserIDController.text),
//           salesRep: selectedSalesRepID,
//           state: selectedStateID,
//           substate: selectedSubStateID,
//           base64: _imageBase64,
//           context);

//       if (success) {
//         showInfoBar(
//           context,
//           "Cliente actualizado con éxito",
//           severity: fluent.InfoBarSeverity.success,
//         );
//       }

//       setState(() {
//         isLoading = false;
//       });

//       return;
//     }

// //? En caso de que el cliente no exista, se crea
//     bool userExist = await userExists(correoController.text.trim());
//     if (userExist) {
//       showInfoBar(
//         context,
//         "Ya existe un usuario con ese correo",
//         severity: fluent.InfoBarSeverity.warning,
//       );
//     } else {
//       bool success = await postNewClientUser(
//           salesRep: selectedSalesRepID,
//           state: selectedStateID,
//           substate: selectedSubStateID,
//           base64: _imageBase64,
//           context: context);
//       if (success) {
//         clearCustomerControllers();
//         showInfoBar(
//           context,
//           "Cliente creado con éxito",
//           severity: fluent.InfoBarSeverity.success,
//         );
//       }
//     }

//     setState(() {
//       isLoading = false;
//     });
//   }

//   Future<void> _saveDialog(BuildContext context) async {
//     showDialog(
//       context: context,
//       builder: (_) {
//         return Builder(builder: (dialogContext) {
//           return AlertDialog(
//             title: Text(
//               'Aviso',
//               style: fluent.FluentTheme.of(context).typography.subtitle,
//             ),
//             backgroundColor: fluent.FluentTheme.of(context).cardColor,
//             content: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(
//                   '¿Estás seguro que deseas Guardar Cliente?',
//                   style: fluent.FluentTheme.of(context).typography.body,
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 48),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     BotonDialog(
//                       text: 'Si',
//                       bgcolor: ColorTheme.success,
//                       onPressed: () async {
//                         Navigator.pop(dialogContext);
//                         await _saveOrUpdateCustomer();
//                       },
//                     ),
//                     BotonDialog(
//                       text: 'No',
//                       bgcolor: ColorTheme.error,
//                       onPressed: () => Navigator.pop(dialogContext),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           );
//         });
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: fluent.FluentTheme.of(context).scaffoldBackgroundColor,
//       body: Stack(children: [
//         SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Sección de Búsqueda
//                 Text(
//                   'Buscar Cliente',
//                   style: fluent.FluentTheme.of(context).typography.subtitle,
//                 ),
//                 const SizedBox(height: CustomSpacer.medium),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: TextfieldTheme(
//                         texto: 'ID o Nro Identificación',
//                         controlador: searchController,
//                         inputType: TextInputType.text,
//                         onSubmitted: (p0) => _searhCustomer(),
//                       ),
//                     ),
//                     const SizedBox(width: 10),
//                     Tooltip(
//                       message: 'Buscar Cliente',
//                       child: IconButton(
//                         padding: EdgeInsets.all(12),
//                         style: ButtonStyle(
//                           backgroundColor: MaterialStateProperty.all(
//                               fluent.FluentTheme.of(context).accentColor),
//                         ),
//                         onPressed: () => _searhCustomer(),
//                         icon: fluent.Icon(
//                           fluent.FluentIcons.search,
//                           size: 28,
//                           color: fluent.FluentTheme.of(context).cardColor,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const Divider(height: 40),

//                 Center(
//                   child: Column(
//                     children: [
//                       GestureDetector(
//                         onTap: () {
//                           showDialog(
//                             context: context,
//                             builder: (context) => WebCameraDialog(
//                               onImageCaptured: (XFile image) async {
//                                 final bytes = await image.readAsBytes();
//                                 setState(() {
//                                   _imageBase64 = base64Encode(bytes);
//                                   _imageBytes = bytes;
//                                 });
//                               },
//                             ),
//                           );
//                         },
//                         child: CircleAvatar(
//                           radius: 50,
//                           backgroundImage: _imageBytes != null
//                               ? MemoryImage(_imageBytes!)
//                               : null,
//                           backgroundColor: ColorTheme.aL100,
//                           child: _imageBytes == null
//                               ? const Icon(Icons.camera_alt,
//                                   color: Colors.white)
//                               : null,
//                         ),
//                       ),
//                       const SizedBox(height: CustomSpacer.medium),
//                       Text(
//                         'Subir Foto',
//                         style:
//                             fluent.FluentTheme.of(context).typography.caption,
//                       )
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 20),

//                 Row(
//                   children: [
//                     Text(
//                       'Información del Cliente',
//                       style: fluent.FluentTheme.of(context).typography.subtitle,
//                     ),
//                     const SizedBox(width: CustomSpacer.medium),
//                     Tooltip(
//                       message: 'Limpiar Campos',
//                       child: IconButton(
//                         padding: EdgeInsets.all(12),
//                         style: ButtonStyle(
//                           backgroundColor: MaterialStateProperty.all(
//                               ColorTheme.error.withOpacity(0.1)),
//                         ),
//                         onPressed: () {
//                           clearCustomerControllers();
//                           setState(() {
//                             _imageBase64 = null;
//                             _imageBytes = null;
//                           });
//                           _validateForm();
//                         },
//                         icon: fluent.Icon(
//                           fluent.FluentIcons.erase_tool,
//                           size: 20,
//                           color: ColorTheme.error,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: CustomSpacer.medium),
//                 TextfieldTheme(
//                   texto: 'ID Único',
//                   controlador: idController,
//                   readOnly: true,
//                 ),
//                 const SizedBox(height: CustomSpacer.medium),
//                 TextfieldTheme(
//                   texto: 'Nro Identificación *',
//                   hint: 'Cédula o Pasaporte',
//                   controlador: taxIdController,
//                   inputType: TextInputType.name,
//                   onChanged: (p0) => _validateForm(),
//                 ),

//                 const SizedBox(height: CustomSpacer.medium),
//                 TextfieldTheme(
//                   texto: 'Nombres *',
//                   controlador: nombreController,
//                   inputType: TextInputType.name,
//                   onChanged: (p0) => _validateForm(),
//                 ),
//                 const SizedBox(height: CustomSpacer.medium),
//                 TextfieldTheme(
//                   texto: 'Apellidos *',
//                   controlador: apellidoController,
//                   inputType: TextInputType.name,
//                   onChanged: (p0) => _validateForm(),
//                 ),
//                 const SizedBox(height: CustomSpacer.medium),
//                 CustomDropdown(
//                   value: selectedSalesRepID,
//                   items: salesRepOptions,
//                   labelText: 'Representante Comercial *',
//                   onChanged: (value) {
//                     setState(() {
//                       selectedSalesRepID = value;
//                       _validateForm();
//                     });
//                   },
//                 ),
//                 const SizedBox(height: CustomSpacer.medium),

//                 CustomDropdown(
//                   value: selectedStateID,
//                   items: stateOptions
//                       .map((state) => {
//                             'id': state['id'],
//                             'name': state['name'] +
//                                 ' ${(state['isInTransit'] == 'IN') ? '[Entrada]' : '[Salida]'}'
//                           })
//                       .toList(),
//                   labelText: 'Estado *',
//                   onChanged: (value) {
//                     setState(() {
//                       selectedStateID = value;
//                       _updateSubStateOptions(value);
//                       _validateForm();
//                     });
//                   },
//                 ),
//                 const SizedBox(height: CustomSpacer.medium),

//                 if (subStateOptions.isNotEmpty) ...[
//                   CustomDropdown(
//                     value: selectedSubStateID,
//                     items: subStateOptions,
//                     labelText: 'Subestado *',
//                     onChanged: (value) {
//                       setState(() {
//                         selectedSubStateID = value;
//                       });
//                     },
//                   ),
//                   const SizedBox(height: CustomSpacer.medium),
//                 ],

//                 TextfieldTheme(
//                   texto: 'Correo *',
//                   controlador: correoController,
//                   inputType: TextInputType.emailAddress,
//                   onChanged: (p0) => _validateForm(),
//                 ),

//                 if (correoController.text.trim().isNotEmpty &&
//                     !isValidEmail(correoController.text.trim()))
//                   Text(
//                     'El correo ingresado no es válido.',
//                     style: fluent.FluentTheme.of(context)
//                         .typography
//                         .caption!
//                         .copyWith(
//                           color: ColorTheme.error,
//                         ),
//                   ),

//                 const SizedBox(height: CustomSpacer.medium),
//                 TextfieldTheme(
//                   texto: 'Teléfono',
//                   controlador: telefonoController,
//                   inputType: TextInputType.phone,
//                   inputFormatters: [
//                     FilteringTextInputFormatter.digitsOnly,
//                     PhoneInputFormatter(),
//                   ],
//                 ),
//                 const SizedBox(height: CustomSpacer.medium),
//                 TextfieldTheme(
//                   texto: 'Teléfono Móvil *',
//                   controlador: movilController,
//                   inputType: TextInputType.phone,
//                   onChanged: (p0) => _validateForm(),
//                   inputFormatters: [
//                     FilteringTextInputFormatter.digitsOnly,
//                     PhoneInputFormatter(),
//                   ],
//                 ),
//                 if (movilController.text.trim().isNotEmpty &&
//                     !isValidPhone(movilController.text.trim()))
//                   Text(
//                     'El teléfono de tener al menos 8 digitos.',
//                     style: fluent.FluentTheme.of(context)
//                         .typography
//                         .caption!
//                         .copyWith(
//                           color: ColorTheme.error,
//                         ),
//                   ),
//                 const SizedBox(height: CustomSpacer.medium),
//                 CustomDateField(
//                   controller: cumpleanosController,
//                   onChanged: (date) {
//                     _validateForm();
//                   },
//                   labelText: 'Cumpleaños',
//                 ),
//                 if (isUnderage)
//                   Text(
//                     'Se recomienda agregar al menos a un acudiente',
//                     style: fluent.FluentTheme.of(context)
//                         .typography
//                         .caption!
//                         .copyWith(
//                           color: ColorTheme.error,
//                         ),
//                   ),
//                 const SizedBox(height: CustomSpacer.medium),
//                 TextFieldComments(
//                   texto: 'Dirección',
//                   controlador: direccionController,
//                 ),
//                 const SizedBox(height: CustomSpacer.medium),
//                 TextFieldComments(
//                   texto: 'Comentarios',
//                   controlador: comentariosController,
//                 ),
//                 const SizedBox(height: 40),

//                 Container(
//                   child: isValid
//                       ? ButtonPrimary(
//                           texto: 'Guardar Cliente',
//                           fullWidth: true,
//                           onPressed: () => _saveDialog(context),
//                         )
//                       : Center(
//                           child: Text(
//                             'Completa los campos obligatorios marcados con *',
//                             style: fluent.FluentTheme.of(context)
//                                 .typography
//                                 .bodyStrong!
//                                 .copyWith(
//                                   color: ColorTheme.error,
//                                 ),
//                           ),
//                         ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         if (isLoading) LoadingContainer(),
//       ]),
//     );
//   }
// }
