// import 'package:flutter/material.dart';
// // import 'package:noteapp/text_container.dart';
// import 'package:flutter/rendering.dart';
// import 'package:noteapp/database.dart';
// import 'package:noteapp/editor.dart';
// import 'package:flutter_quill/flutter_quill.dart';
// import 'package:noteapp/homepage.dart';
// import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:sqflite/sqflite.dart';
// import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   final DatabaseHelper db = DatabaseHelper.instance;

//   await db.database;

//   final path = await getDatabasesPath();
//   print(path);

//   debugPaintSizeEnabled = false;
//   runApp(const NoteApp());
// }

// class NoteApp extends StatelessWidget {
//   const NoteApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       localizationsDelegates: const [
//         GlobalMaterialLocalizations.delegate,
//         GlobalCupertinoLocalizations.delegate,
//         GlobalWidgetsLocalizations.delegate,
//         FlutterQuillLocalizations.delegate,
//       ],
//       debugShowCheckedModeBanner: false,
//       initialRoute: '/',
//       routes: {
//         '/': (context) => Homepage(),
//         '/editingSpace': (context) => Editor(),
//       },
//     );
//   }
// }

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:noteapp/main_screen.dart'; // Changed from homepage to main_screen
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:adaptive_theme/adaptive_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Setup database for Windows, Mac, Linux
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final savedThemeMode = await AdaptiveTheme.getThemeMode();

  runApp(MyApp(savedThemeMode: savedThemeMode));
  final path = await getDatabasesPath();
  debugPrint('DB path: $path');
}

class MyApp extends StatelessWidget {
  final AdaptiveThemeMode? savedThemeMode;
  const MyApp({super.key, this.savedThemeMode});

  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
      light: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      dark: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      initial: savedThemeMode ?? AdaptiveThemeMode.light,
      builder: (theme, darkTheme) => MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          FlutterQuillLocalizations.delegate,
        ],
        title: 'Simple Editor',
        theme: theme,
        darkTheme: darkTheme,
        home:
            const MainScreen(), // Changed from HomePage to MainScreen
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
