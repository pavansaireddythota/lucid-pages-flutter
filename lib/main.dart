import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
// Added localization delegates for standard widgets and Cupertino styles
import 'package:flutter_localizations/flutter_localizations.dart';
// Added the localization delegate required by flutter_quill UI tools
import 'package:flutter_quill/flutter_quill.dart';

import 'firebase_options.dart';
import 'navigation/app_navigator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const LucidPagesApp());
}

class LucidPagesApp extends StatelessWidget {
  const LucidPagesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lucid Pages',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),

      // Fixes the MissingFlutterQuillLocalizationException runtime error
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate, // Injects internal quill asset strings
      ],
      supportedLocales: const [
        Locale('en', 'US'), // Sets English as default locale target
      ],

      home: const AppNavigator(),
    );
  }
}