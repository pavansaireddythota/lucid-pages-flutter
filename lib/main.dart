import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'firebase_options.dart';
import 'navigation/app_navigator.dart';

// Import supplemental utility screens
import './screens/profile/edit_profile_screen.dart';
import './screens/feedback/feedback_screen.dart';
import './screens/about_us/about_us_screen.dart';
import './screens/privacy_policy/privacy_policy_screen.dart';

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
      
      // Global app routes accessible from any screen context
      routes: {
        '/edit-profile': (context) => const EditProfileScreen(),
        '/feedback': (context) => const FeedbackScreen(),
        '/about-us': (context) => const AboutUsScreen(),
        '/privacy-policy': (context) => const PrivacyPolicyScreen(),
      },
    );
  }
}