import 'package:flutter_test/flutter_test.dart';
import 'package:dailynote/main.dart' as app;

void main() {
  testWidgets('Menampilkan petunjuk saat konfigurasi kosong', (tester) async {
    await app.main();
    await tester.pump();
    expect(find.text('Isi URL dan key melalui dart-define.'), findsOneWidget);
  });
}
