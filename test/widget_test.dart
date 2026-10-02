import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aprimorar_video/app/aprimorar_video_app.dart';
import 'package:aprimorar_video/features/trim/presentation/widgets/trim_timeline.dart';

Future<void> _scrollTo(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    220,
    scrollable: find.byType(Scrollable).first,
  );
}

<<<<<<< HEAD
void main() {
=======
Future<void> _skipLaunch(WidgetTester tester) async {
  await tester.tap(find.text('Pular'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('mostra abertura cinematica e permite pular', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: AprimorarVideoApp()),
    );

    expect(find.text('Sua história. Em alta definição.'), findsOneWidget);
    expect(find.text('ATÉ 4K'), findsOneWidget);

    await _skipLaunch(tester);
    expect(find.text('Cortar vídeo'), findsOneWidget);
  });

>>>>>>> origin/main
  testWidgets('abre na tela inicial', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: AprimorarVideoApp()),
    );
<<<<<<< HEAD
=======
    await _skipLaunch(tester);
>>>>>>> origin/main

    expect(find.text('Aprimorar Vídeo'), findsOneWidget);
    expect(find.text('Cortar vídeo'), findsOneWidget);
    expect(find.text('Cortar melhores momentos'), findsOneWidget);

    await _scrollTo(tester, find.text('Melhorar qualidade'));
    expect(find.text('Melhorar qualidade'), findsOneWidget);
  });

  testWidgets('navega para as abas', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: AprimorarVideoApp()),
    );
<<<<<<< HEAD
=======
    await _skipLaunch(tester);
>>>>>>> origin/main

    await tester.tap(find.text('Cortar'));
    await tester.pumpAndSettle();
    expect(find.text('Escolha um vídeo para começar'), findsOneWidget);
    expect(find.byType(TrimTimeline), findsNothing);

    await tester.tap(find.text('Momentos'));
    await tester.pumpAndSettle();
    expect(find.text('Escolher vídeo'), findsOneWidget);

    await tester.tap(find.text('Qualidade'));
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('Melhorar qualidade'));
    expect(find.text('Melhorar qualidade'), findsOneWidget);

    await tester.tap(find.text('Biblioteca'));
    await tester.pumpAndSettle();
    expect(find.text('Nada exportado ainda'), findsOneWidget);
  });
}
