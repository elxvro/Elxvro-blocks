import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:elxvro_blocks/app_state.dart';
import 'package:elxvro_blocks/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ELXVRO Blocks açılıştan ana ekrana geçer', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final state = AppState();
    await state.load();

    await tester.pumpWidget(ElxvroBlocksApp(appState: state));

    // LaunchScreen: 1350 ms bekleme + 420 ms geçiş.
    // v0.20 arka plan yağmuru sürekli animasyon olduğu için pumpAndSettle
    // bilerek kullanılmaz; aksi halde test sonsuza kadar settle olamaz.
    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('ELXVRO'), findsOneWidget);
    expect(find.text('OYNA'), findsOneWidget);
    expect(find.text('MODLAR'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Sürekli yağmur animasyonunun controller'ını test sonunda kapat.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
