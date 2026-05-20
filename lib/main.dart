import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexora_academy/l10n/app_localizations.dart';
import 'core/router/app_router.dart';
import 'core/providers/locale_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  try {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);
    await Hive.openBox('subjects');
    await Hive.openBox('lessons');
    await Hive.openBox('progress_cache');
    await Hive.openBox('offline_progress');
  } catch (e) {
    debugPrint("Hive initialization failed: $e");
  }
  
  // Initialize Supabase Platform
  // IMPORTANT: Replace with your actual Supabase URL and Anon Key!
  try {
    await Supabase.initialize(
      url: 'https://jzinlwgzqoandlcdazfg.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp6aW5sd2d6cW9hbmRsY2RhemZnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMwNjg4NDcsImV4cCI6MjA4ODY0NDg0N30.yVq7cDp2ijTfWBducoEdWC-33cHZw6EU85pps-Iw4RQ',
    );
  } catch (e) {
    debugPrint("Supabase initialization failed: $e");
  }

  runApp(
    const ProviderScope(
      child: NexoraAcademyApp(),
    ),
  );
}

class NexoraAcademyApp extends ConsumerWidget {
  const NexoraAcademyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Nexora Academy',
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('fr'),
        Locale('ar'),
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: locale.languageCode == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: child!,
        );
      },
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
