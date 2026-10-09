import 'package:flutter_test/flutter_test.dart';
import 'package:pusher_example/main.dart';

void main() {
  testWidgets('shows plugin hint', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.textContaining('Pusher.init'), findsOneWidget);
    expect(find.textContaining('statusDelivered='), findsOneWidget);
  });
}
