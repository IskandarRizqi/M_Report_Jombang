import 'dart:ui';
import 'dart:io';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ehr_report/cuti.dart';
import 'package:ehr_report/halamanutama.dart';
import 'package:ehr_report/pagelogin.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:ehr_report/firebase_option.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  GoogleFonts.config.allowRuntimeFetching = false;

  await initializeDateFormatting('id_ID', null);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  easyLoadingCustomization();
  HttpOverrides.global = MyHttpOverrides();

  await initFirebase();

  runApp(const MyApp());
}

Future<void> initFirebase() async {
  try {
    print("Initializing Firebase...");

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    print("Firebase Initialized");

    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    await initializeFirebaseMessaging();
  } catch (e) {
    print("Firebase Error: $e");
  }
}

Future<void> initializeFirebaseMessaging() async {
  try {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    print("FCM Token: $fcmToken");

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground Message: ${message.data}');
    });
  } catch (e) {
    print("FCM Error: $e");
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void easyLoadingCustomization() {
  EasyLoading.instance
    ..indicatorType = EasyLoadingIndicatorType.ring
    ..loadingStyle = EasyLoadingStyle.dark;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    print("Building EhrApp...");

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EHR SYSTEM',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginPage(),
      builder: EasyLoading.init(),
      routes: {
        '/cutireport': (context) => const EmployeeLeavePage(prevPage: 'home'),
      },
    );
  }
}
