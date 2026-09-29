import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aprimorar_video/app/aprimorar_video_app.dart';

void main() {
  testWidgets('abre na tela inicial', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: AprimorarVideoApp()),
    );

    expect(find.text('Aprimorar Vídeo'), findsOneWidget);
    expect(find.text('Cortar melhores momentos'), findsOneWidget);
    expect(find.text('Melhorar qualidade'), findsOneWidget);
  });

  testWidgets('navega para as abas', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: AprimorarVideoApp()),
    );

    await tester.tap(find.text('Momentos'));
    await tester.pumpAndSettle();
    expect(find.text('Escolher vídeo'), findsOneWidget);

    await tester.tap(find.text('Qualidade'));
    await tester.pumpAndSettle();
    expect(find.text('Melhorar qualidade'), findsOneWidget);

    await tester.tap(find.text('Biblioteca'));
    await tester.pumpAndSettle();
    expect(find.text('Nada exportado ainda'), findsOneWidget);
  });
}
