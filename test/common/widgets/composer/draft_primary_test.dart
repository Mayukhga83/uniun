import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/common/widgets/composer/uniun_composer.dart';
import 'package:uniun/l10n/app_localizations.dart';

/// Covers #210: `draftIsPrimary` swaps which of the two composer actions
/// carries the accent colour. Opt-in, so every chat surface keeps send
/// primary.
void main() {
  late ColorScheme scheme;

  Widget host({required bool draftIsPrimary}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: (ctx) {
        scheme = Theme.of(ctx).colorScheme;
        return Scaffold(
          body: UniunComposer(
            controller: TextEditingController(text: 'hello'),
            focusNode: FocusNode(),
            avatarSeed: 'seed',
            hintText: 'hint',
            onDraft: () {},
            draftLabel: 'Draft',
            draftIsPrimary: draftIsPrimary,
            onSend: () {},
          ),
        );
      }),
    );
  }

  /// Fill colour of the Draft pill.
  Color draftFill(WidgetTester t) {
    final box = t.widget<Container>(
      find.ancestor(of: find.text('Draft'), matching: find.byType(Container)).first,
    );
    return ((box.decoration!) as BoxDecoration).color!;
  }

  /// Fill colour of the round send button.
  Color sendFill(WidgetTester t) {
    final box = t.widget<Container>(
      find
          .ancestor(
            of: find.byIcon(Icons.arrow_upward_rounded),
            matching: find.byType(Container),
          )
          .first,
    );
    return ((box.decoration!) as BoxDecoration).color!;
  }

  testWidgets('default: send carries the accent, draft is muted', (t) async {
    await t.pumpWidget(host(draftIsPrimary: false));
    expect(sendFill(t), scheme.primary);
    expect(draftFill(t), scheme.surfaceContainerHigh);
  });

  testWidgets('draftIsPrimary: draft carries the accent, send is muted',
      (t) async {
    await t.pumpWidget(host(draftIsPrimary: true));
    expect(draftFill(t), scheme.primary);
    expect(sendFill(t), scheme.surfaceContainerHigh);
  });

  testWidgets('the two actions never both carry the accent', (t) async {
    for (final primary in [true, false]) {
      await t.pumpWidget(host(draftIsPrimary: primary));
      expect(draftFill(t) == sendFill(t), isFalse, reason: '$primary');
    }
  });

  testWidgets('both remain tappable — muted is not disabled', (t) async {
    var drafted = 0;
    var sent = 0;
    await t.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: UniunComposer(
          controller: TextEditingController(text: 'hello'),
          focusNode: FocusNode(),
          avatarSeed: 'seed',
          hintText: 'hint',
          onDraft: () => drafted++,
          draftLabel: 'Draft',
          draftIsPrimary: true,
          onSend: () => sent++,
        ),
      ),
    ));

    await t.tap(find.text('Draft'));
    await t.tap(find.byIcon(Icons.arrow_upward_rounded));
    await t.pump();

    expect(drafted, 1);
    expect(sent, 1);
  });
}
