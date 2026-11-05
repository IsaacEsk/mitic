import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitic/screens/tutorialScreen.dart';
import 'package:mitic/widgets/monumento_tablero.dart';

void main() {
  testWidgets('opens the localized fixed tutorial board from How to play', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: TutorialScreen(selectedLanguage: 'en')),
    );
    await tester.pumpAndSettle();

    expect(find.text('How to play'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);

    await tester.tap(find.text('How to play'));
    await tester.pumpAndSettle();

    expect(find.text('Dice roll'), findsOneWidget);
    expect(
      find.text(
        'At the start of each turn, each player adds the dice total to their invocation points. Use those points to summon or upgrade elements.',
      ),
      findsOneWidget,
    );
    expect(find.text('1 + 3 = 4 points'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/dados/1x3.png',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();

    expect(find.text('Summoning and upgrading'), findsOneWidget);
    expect(
      find.text(
        'When you summon or upgrade an element on the board, its cost is deducted from your accumulated points. Crops also generate invocation points at the start of each turn. Select the empty space next to your monument and summon the crop to see how it works: it will generate 2 points per turn.',
      ),
      findsOneWidget,
    );
    expect(find.byTooltip('Summon crop'), findsNothing);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Player 1'), findsOneWidget);
    expect(find.textContaining('Player 2'), findsOneWidget);
    expect(find.textContaining('Mayan'), findsOneWidget);
    expect(find.textContaining('Aztec'), findsOneWidget);
    expect(find.text('750'), findsNWidgets(2));
    expect(find.text('Warriors available to summon'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName.contains('/personajes/'),
      ),
      findsNothing,
    );
    expect(find.text('Continue'), findsNothing);
    expect(find.text('PASS'), findsNothing);
    expect(find.byType(ElevatedButton), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.byTooltip('Summon crop'), findsOneWidget);

    await tester.tap(find.byTooltip('Summon crop'));
    await tester.pumpAndSettle();
    expect(find.textContaining('SUMMON'), findsOneWidget);
    expect(find.text('Mayan Milpa'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tutorial-crop-option')));
    await tester.pumpAndSettle();

    expect(find.text('Upgrade your crop'), findsOneWidget);
    expect(
      find.text(
        'Tap your crop and choose an option to improve its health or production. The higher its production, the more points you will collect on your next turn.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('tutorial-crop-piece')));
    await tester.pumpAndSettle();
    expect(find.text('UPGRADE PRODUCTION'), findsOneWidget);
    expect(find.text('REBUILD'), findsOneWidget);

    await tester.tap(find.text('UPGRADE PRODUCTION'));
    await tester.pumpAndSettle();
    expect(find.text('Current value 2'), findsOneWidget);
    expect(find.text('1 ⚡'), findsOneWidget);

    await tester.tap(find.text('UPGRADE'));
    await tester.pumpAndSettle();
    expect(find.text('End your turn'), findsOneWidget);
    expect(find.text('PASS'), findsNothing);
    expect(
      find.text(
        'To end your turn, press the “Pass” button at the bottom of the board.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text('PASS'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    expect(find.textContaining('🌾 3'), findsOneWidget);
    expect(find.byTooltip('Summon crop'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is AnimatedContainer &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).image?.image is AssetImage &&
            ((widget.decoration! as BoxDecoration).image!.image as AssetImage)
                    .assetName ==
                'assets/images/cultivos/cultivo_maya.png',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('tutorial-pass-turn')));
    await tester.pump();
    expect(find.text('🤖 AI ROLLING DICE...'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/dados/6x6.png',
      ),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('PASS'), findsNothing);
    expect(find.text('4'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is AnimatedContainer &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).image?.image is AssetImage &&
            ((widget.decoration! as BoxDecoration).image!.image as AssetImage)
                    .assetName ==
                'assets/images/cultivos/cultivo_azteca.png',
      ),
      findsNWidgets(4),
    );
    expect(find.text('🎲 ROLLING DICE...'), findsNothing);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.text('🎲 ROLLING DICE...'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/dados/6x5.png',
      ),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.text('+3'), findsOneWidget);
    final cropCellSize = tester.getSize(
      find.byKey(const ValueKey('tutorial-crop-piece')),
    );
    final cropImage = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('tutorial-player-crop-harvest')),
    );
    expect(
      cropImage.constraints!.maxWidth,
      closeTo(cropCellSize.width * 0.9 * 1.1, 0.1),
    );
    expect(
      cropImage.constraints!.maxHeight,
      closeTo(cropCellSize.height * 0.9 * 1.1, 0.1),
    );
    final opponentCropImages = tester.widgetList<AnimatedContainer>(
      find.byWidgetPredicate(
        (widget) =>
            widget is AnimatedContainer &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).image?.image is AssetImage &&
            ((widget.decoration! as BoxDecoration).image!.image as AssetImage)
                    .assetName ==
                'assets/images/cultivos/cultivo_azteca.png',
      ),
    );
    expect(opponentCropImages, hasLength(4));
    for (final opponentCropImage in opponentCropImages) {
      expect(
        opponentCropImage.constraints!.maxWidth,
        closeTo(cropCellSize.width * 0.9, 0.1),
      );
      expect(
        opponentCropImage.constraints!.maxHeight,
        closeTo(cropCellSize.height * 0.9, 0.1),
      );
    }
    expect(cropImage.duration, const Duration(milliseconds: 500));
    expect(cropImage.curve, Curves.easeOutBack);

    await tester.pump(const Duration(milliseconds: 300));
    final resetCropImage = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('tutorial-player-crop-harvest')),
    );
    expect(
      resetCropImage.constraints!.maxWidth,
      closeTo(cropCellSize.width * 0.9, 0.1),
    );
    expect(
      resetCropImage.constraints!.maxHeight,
      closeTo(cropCellSize.height * 0.9, 0.1),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text('15'), findsOneWidget);
    expect(find.text('+3'), findsNothing);
    expect(find.text('More crops'), findsOneWidget);
    expect(
      find.text(
        'Keep planting crops to increase your point production. Select the empty spaces and plant two more crops.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('tutorial-summon-crop-3')), findsNothing);
    expect(find.byKey(const ValueKey('tutorial-summon-crop-4')), findsNothing);

    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('tutorial-summon-crop-3')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('tutorial-summon-crop-4')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('tutorial-summon-crop-3')));
    await tester.pumpAndSettle();
    expect(find.text('Mayan Milpa'), findsOneWidget);
    expect(find.text('Upgrade your crop'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('tutorial-crop-option')));
    await tester.pumpAndSettle();
    expect(find.text('13'), findsOneWidget);
    expect(find.byKey(const ValueKey('tutorial-summon-crop-3')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('tutorial-summon-crop-4')));
    await tester.pumpAndSettle();
    expect(find.text('Mayan Milpa'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tutorial-crop-option')));
    await tester.pumpAndSettle();
    expect(find.text('11'), findsOneWidget);
    expect(find.byKey(const ValueKey('tutorial-summon-crop-4')), findsNothing);
    expect(find.text('Villagers'), findsOneWidget);
    expect(
      find.text(
        "You can use invocation points to improve your crops' health, but villagers can also rebuild them and make them stronger. Summon a villager so it can rebuild your crops and monuments each turn.",
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('tutorial-summon-villager')),
      findsNothing,
    );
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('tutorial-summon-villager')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('tutorial-summon-villager')));
    await tester.pumpAndSettle();
    expect(find.text('Mayan Villager'), findsOneWidget);
    expect(find.text('Mayan Milpa'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('tutorial-villager-option')));
    await tester.pumpAndSettle();
    expect(find.text('Villagers'), findsOneWidget);
    expect(
      find.text(
        'Villagers repair buildings and crops with their reconstruction power. 🔨 At the start of each turn, they repair all buildings and crops in their row and column.',
      ),
      findsOneWidget,
    );
    expect(find.text('10'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('tutorial-villager-piece')),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is AnimatedContainer &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).image?.image is AssetImage &&
            ((widget.decoration! as BoxDecoration).image!.image as AssetImage)
                    .assetName ==
                'assets/images/aldeanos/aldeano_maya.png',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Move your villagers to the position that works best for you. To do so, tap a villager and select the move option.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text('Villagers'), findsNothing);
    expect(
      find.text(
        'Move your villagers to the position that works best for you. To do so, tap a villager and select the move option.',
      ),
      findsNothing,
    );
    expect(find.text('PASS'), findsNothing);
    expect(
      find.byKey(const ValueKey('tutorial-villager-piece')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('tutorial-villager-piece')));
    await tester.pumpAndSettle();
    expect(find.text('Mayan Villager'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('tutorial-villager-move-action')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('tutorial-villager-move-action')),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Select the highlighted square next to the crop to move the villager there.',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('tutorial-villager-move-target')),
      findsOneWidget,
    );
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('tutorial-villager-move-target')),
      findsOneWidget,
    );
    final villagerPosition = tester.getTopLeft(
      find.byKey(const ValueKey('tutorial-villager-piece')),
    );
    final cropPosition = tester.getTopLeft(
      find.byKey(const ValueKey('tutorial-crop-piece')),
    );
    await tester.tap(
      find.byKey(const ValueKey('tutorial-villager-move-target')),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .getTopLeft(find.byKey(const ValueKey('tutorial-villager-piece')))
          .dx,
      lessThan(cropPosition.dx),
    );
    expect(
      tester
          .getTopLeft(find.byKey(const ValueKey('tutorial-villager-piece')))
          .dy,
      closeTo(cropPosition.dy, 0.1),
    );
    expect(villagerPosition.dy, isNot(cropPosition.dy));
    expect(
      find.byKey(const ValueKey('tutorial-villager-move-target')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('tutorial-pass-turn')), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is AnimatedContainer &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).image?.image is AssetImage &&
            ((widget.decoration! as BoxDecoration).image!.image as AssetImage)
                    .assetName ==
                'assets/images/cultivos/cultivo_maya.png',
      ),
      findsNWidgets(3),
    );

    await tester.tap(find.byKey(const ValueKey('tutorial-pass-turn')));
    await tester.pump();
    expect(find.text('🤖 AI ROLLING DICE...'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/dados/4x5.png',
      ),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('tutorial-opponent-points')))
          .data,
      '21',
    );
    expect(find.text('+8'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
    final opponentCropCellSize = tester.getSize(
      find.byKey(const ValueKey('tutorial-opponent-crop-0')),
    );
    for (var column = 0; column < 5; column++) {
      if (column == 2) continue;
      final animatedOpponentCrop = tester.widget<AnimatedContainer>(
        find.byKey(ValueKey('tutorial-opponent-crop-harvest-$column')),
      );
      expect(
        animatedOpponentCrop.constraints!.maxWidth,
        closeTo(opponentCropCellSize.width * 0.9 * 1.1, 0.1),
      );
      expect(
        animatedOpponentCrop.constraints!.maxHeight,
        closeTo(opponentCropCellSize.height * 0.9 * 1.1, 0.1),
      );
      expect(animatedOpponentCrop.duration, const Duration(milliseconds: 500));
      expect(animatedOpponentCrop.curve, Curves.easeOutBack);
    }
    await tester.pump(const Duration(milliseconds: 300));
    for (var column = 0; column < 5; column++) {
      if (column == 2) continue;
      final resetOpponentCrop = tester.widget<AnimatedContainer>(
        find.byKey(ValueKey('tutorial-opponent-crop-harvest-$column')),
      );
      expect(
        resetOpponentCrop.constraints!.maxWidth,
        closeTo(opponentCropCellSize.width * 0.9, 0.1),
      );
      expect(
        resetOpponentCrop.constraints!.maxHeight,
        closeTo(opponentCropCellSize.height * 0.9, 0.1),
      );
    }
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('tutorial-opponent-points')))
          .data,
      '21',
    );
    expect(find.text('+8'), findsNothing);
    for (final column in [0, 1, 3, 4]) {
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();
      expect(
        tester
            .widget<Text>(
              find.byKey(ValueKey('tutorial-opponent-crop-production-$column')),
            )
            .data,
        '🌾 6   ❤️ 3',
      );
      final upgradedCropCount =
          [
            0,
            1,
            3,
            4,
          ].where((upgradedColumn) => upgradedColumn <= column).length;
      final opponentPoints = 21 - upgradedCropCount * 4;
      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey('tutorial-opponent-points')),
            )
            .data,
        '$opponentPoints',
      );
    }
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('tutorial-opponent-points')))
          .data,
      '5',
    );
    expect(find.text('🎲 ROLLING DICE...'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/dados/4x1.png',
      ),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('tutorial-player-points')))
          .data,
      '22',
    );
    expect(find.text('+7'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    final villagerCellSize = tester.getSize(
      find.byKey(const ValueKey('tutorial-villager-piece')),
    );
    final hammerImage = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('tutorial-villager-hammer-animation')),
    );
    expect(
      hammerImage.constraints!.maxWidth,
      closeTo(villagerCellSize.width * 0.9 * 0.5, 0.1),
    );
    expect(
      tester
          .widget<MonumentoTablero>(
            find.byKey(const ValueKey('tutorial-player-monument')),
          )
          .vida,
      751,
    );
    for (final column in [1, 3, 4]) {
      expect(
        tester
            .widget<Text>(
              find.byKey(ValueKey('tutorial-player-crop-health-$column')),
            )
            .data,
        '🌾 ${column == 1 ? 3 : 2}   ❤️ 3',
      );
    }
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 80));
    await tester.pump();
    expect(
      tester
          .widget<AnimatedContainer>(
            find.byKey(const ValueKey('tutorial-villager-hammer-animation')),
          )
          .constraints!
          .maxWidth,
      closeTo(villagerCellSize.width * 0.9 * 0.5, 0.1),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 80));
    await tester.pump();
    expect(
      tester
          .widget<AnimatedContainer>(
            find.byKey(const ValueKey('tutorial-villager-hammer-animation')),
          )
          .constraints!
          .maxWidth,
      closeTo(villagerCellSize.width * 0.9 * 0.5, 0.1),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(find.text('+7'), findsNothing);
    expect(find.byKey(const ValueKey('tutorial-pass-turn')), findsNothing);
  });

  testWidgets('Skip opens game mode selection', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: TutorialScreen(selectedLanguage: 'es')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Saltar'));
    await tester.pumpAndSettle();

    expect(find.text('Elige un modo de juego'), findsOneWidget);
  });
}
