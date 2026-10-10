import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'widgets/glass.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  await initializeDateFormatting('tr_TR', null);
  await NotificationService.initialize();
  runApp(const KaloriHesaplaApp());
}

class KaloriHesaplaApp extends StatelessWidget {
  const KaloriHesaplaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KaloriAI - Kalori Takip',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      // Tüm route'ların arkasında ortak cam zemin (aurora + blur katmanı)
      builder: (context, child) {
        return GlassBackground(child: child ?? const SizedBox.shrink());
      },
      home: const HomeScreen(),
    );
  }
}
