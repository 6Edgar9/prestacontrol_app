import 'package:flutter_test/flutter_test.dart';
import 'package:prestacontrol_app/main.dart';

void main() {
  testWidgets('Carga inicial de PrestaControl', (WidgetTester tester) async {
    await tester.pumpWidget(const PrestaControlApp(inicioConSesion: false));
    expect(find.text('PrestaControl'), findsOneWidget);
  });
}
