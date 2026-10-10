import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kalori_hesapla/main.dart';
import 'package:kalori_hesapla/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('KaloriHesaplaApp loads smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
    await initializeDateFormatting('tr_TR', null);

    await tester.pumpWidget(const KaloriHesaplaApp());
    await tester.pumpAndSettle();

    expect(find.byType(KaloriHesaplaApp), findsOneWidget);
  });
}
