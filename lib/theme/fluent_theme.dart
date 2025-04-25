// import 'package:fluent_ui/fluent_ui.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'colors.dart';

// AccentColor customAccentColorLight(Color color) {
//   return AccentColor.swatch(
//     {
//       'normal': color,
//       'lighter': ColorTheme.aL200,
//       'darker': ColorTheme.aL800,
//     },
//   );
// }

// AccentColor customAccentColorDark(Color color) {
//   return AccentColor.swatch(
//     {
//       'normal': color,
//       'lighter': ColorTheme.aD200,
//       'darker': ColorTheme.aD800,
//     },
//   );
// }

// /// Tema claro de la aplicación
// final FluentThemeData lightTheme = FluentThemeData(
//   brightness: Brightness.light,
//   accentColor: customAccentColorLight(ColorTheme.accentLight),
//   scaffoldBackgroundColor: ColorTheme.backgroundLight,
//   cardColor: Colors.white,
//   activeColor: ColorTheme.accentLight,
//   inactiveColor: ColorTheme.aL200,
//   typography: Typography.raw(
//     caption: GoogleFonts.poppins(color: ColorTheme.textLight, fontSize: 14),
//     body: GoogleFonts.poppins(color: ColorTheme.textLight, fontSize: 18),
//     bodyLarge: GoogleFonts.poppins(
//         color: ColorTheme.textLight, fontSize: 20, fontWeight: FontWeight.w400),
//     bodyStrong: GoogleFonts.poppins(
//         color: ColorTheme.textLight, fontSize: 20, fontWeight: FontWeight.w600),
//     display: GoogleFonts.poppins(
//         color: ColorTheme.textLight, fontSize: 22, fontWeight: FontWeight.w500),
//     subtitle: GoogleFonts.poppins(
//         color: ColorTheme.textLight, fontSize: 24, fontWeight: FontWeight.w500),
//     title: GoogleFonts.poppins(
//         color: ColorTheme.textLight, fontSize: 28, fontWeight: FontWeight.w600),
//     titleLarge: GoogleFonts.poppins(
//         color: ColorTheme.textLight, fontSize: 32, fontWeight: FontWeight.w700),
//   ),
//   navigationPaneTheme: NavigationPaneThemeData(
//     unselectedTextStyle: WidgetStatePropertyAll(GoogleFonts.poppins(
//         color: ColorTheme.textLight,
//         fontSize: 20,
//         fontWeight: FontWeight.w400)),
//     backgroundColor: ColorTheme.aL100,
//     selectedTextStyle: WidgetStatePropertyAll(GoogleFonts.poppins(
//         color: ColorTheme.accentLight,
//         fontSize: 24,
//         fontWeight: FontWeight.w600)),
//     selectedIconColor: WidgetStatePropertyAll(ColorTheme.accentLight),
//   ),
// );

// /// Tema oscuro de la aplicación
// final FluentThemeData darkTheme = FluentThemeData(
//   brightness: Brightness.dark,
//   accentColor: customAccentColorDark(ColorTheme.accentDark),
//   scaffoldBackgroundColor: ColorTheme.backgroundDark,
//   cardColor: ColorTheme.tD100,
//   activeColor: ColorTheme.accentDark,
//   inactiveColor: ColorTheme.aD200,
//   shadowColor: Colors.transparent,
//   typography: Typography.raw(
//     caption: GoogleFonts.poppins(color: ColorTheme.textDark, fontSize: 14),
//     body: GoogleFonts.poppins(color: ColorTheme.textDark, fontSize: 18),
//     bodyLarge: GoogleFonts.poppins(
//         color: ColorTheme.textDark, fontSize: 20, fontWeight: FontWeight.w400),
//     bodyStrong: GoogleFonts.poppins(
//         color: ColorTheme.textDark, fontSize: 20, fontWeight: FontWeight.w600),
//     display: GoogleFonts.poppins(
//         color: ColorTheme.textDark, fontSize: 22, fontWeight: FontWeight.w500),
//     subtitle: GoogleFonts.poppins(
//         color: ColorTheme.textDark, fontSize: 24, fontWeight: FontWeight.w500),
//     title: GoogleFonts.poppins(
//         color: ColorTheme.textDark, fontSize: 28, fontWeight: FontWeight.w600),
//     titleLarge: GoogleFonts.poppins(
//         color: ColorTheme.textDark, fontSize: 32, fontWeight: FontWeight.w700),
//   ),
//   navigationPaneTheme: NavigationPaneThemeData(
//     backgroundColor: ColorTheme.textLight,
//     selectedTextStyle: WidgetStatePropertyAll(GoogleFonts.poppins(
//         color: ColorTheme.accentDark,
//         fontSize: 24,
//         fontWeight: FontWeight.w600)),
//     selectedIconColor: WidgetStatePropertyAll(ColorTheme.accentDark),
//     unselectedTextStyle: WidgetStatePropertyAll(GoogleFonts.poppins(
//         color: ColorTheme.textDark, fontSize: 20, fontWeight: FontWeight.w400)),
//   ),
// );
