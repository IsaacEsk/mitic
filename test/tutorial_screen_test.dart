import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitic/models/guerrero_field_model_2.0.dart';
import 'package:mitic/screens/tutorialScreen.dart';
import 'package:mitic/widgets/guerrero_tablero.dart';
import 'package:mitic/widgets/hospital_tablero.dart';
import 'package:mitic/widgets/monumento_tablero.dart';
import 'package:mitic/widgets/torre_tablero.dart';

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
    if (find.text('🎲 ROLLING DICE...').evaluate().isEmpty) {
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
    }
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
    expect(find.text('Warriors'), findsOneWidget);
    expect(
      find.text(
        "It's time to summon a warrior. Select the empty square on the board and summon a warrior.",
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('tutorial-summon-warrior')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('tutorial-summon-warrior')));
    await tester.pumpAndSettle();
    expect(find.text('Kukulkan'), findsOneWidget);
    expect(find.text('⚔️ 18   ❤️ 28'), findsOneWidget);
    expect(find.text('⚡ 16'), findsOneWidget);
    expect(find.text('Mayan Villager'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('tutorial-warrior-option')));
    await tester.pumpAndSettle();
    expect(find.text('Kukulkan'), findsNothing);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('tutorial-player-points')))
          .data,
      '6',
    );
    expect(find.byKey(const ValueKey('tutorial-summon-warrior')), findsNothing);
    expect(
      find.byKey(const ValueKey('tutorial-warrior-piece')),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/personajes/kukulkan.png',
      ),
      findsOneWidget,
    );
    expect(find.text('Warrior attacks'), findsOneWidget);
    expect(
      find.text(
        'Warriors attack the first enemy unit directly in front of them. But be careful: you cannot attack the monument until it is the only piece left on the board.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('tutorial-pass-turn')), findsNothing);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text('Warrior attacks'), findsNothing);
    expect(find.text('Move your warrior'), findsOneWidget);
    expect(
      find.text(
        'Move your warrior to a good position so it can attack an enemy crop. To do so, tap the warrior and select the move option.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    final warriorPosition = tester.getTopLeft(
      find.byKey(const ValueKey('tutorial-warrior-piece')),
    );
    await tester.tap(find.byKey(const ValueKey('tutorial-warrior-piece')));
    await tester.pumpAndSettle();
    expect(find.text('Kukulkan'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('tutorial-warrior-move-action')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('tutorial-warrior-move-action')),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Select the highlighted square to position Kukulkan in front of an enemy crop.',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('tutorial-warrior-move-target')),
      findsOneWidget,
    );
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('tutorial-warrior-move-target')),
      findsOneWidget,
    );
    final enemyCropPosition = tester.getTopLeft(
      find.byKey(const ValueKey('tutorial-opponent-crop-1')),
    );
    await tester.tap(
      find.byKey(const ValueKey('tutorial-warrior-move-target')),
    );
    await tester.pumpAndSettle();
    final movedWarriorPosition = tester.getTopLeft(
      find.byKey(const ValueKey('tutorial-warrior-piece')),
    );
    expect(movedWarriorPosition.dx, closeTo(enemyCropPosition.dx, 0.1));
    expect(movedWarriorPosition.dy, greaterThan(enemyCropPosition.dy));
    expect(movedWarriorPosition.dx, isNot(warriorPosition.dx));
    expect(
      find.byKey(const ValueKey('tutorial-warrior-move-target')),
      findsNothing,
    );
    expect(find.text('Attack the crop'), findsOneWidget);
    expect(
      find.text(
        'To attack the crop, tap the warrior and select the attack option.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    final warriorAttackAnimation = find.byKey(
      const ValueKey('tutorial-warrior-attack-animation'),
    );
    final warriorAttackAnimationWidget = tester.widget<AnimatedContainer>(
      warriorAttackAnimation,
    );
    expect(
      warriorAttackAnimationWidget.duration,
      const Duration(milliseconds: 200),
    );
    expect(warriorAttackAnimationWidget.curve, Curves.easeOutBack);
    await tester.tap(find.byKey(const ValueKey('tutorial-warrior-piece')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('tutorial-warrior-attack-action')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('tutorial-warrior-attack-action')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Attack damage'), findsOneWidget);
    expect(
      find.text(
        "Your warrior's attack points ⚔️ are subtracted from your target's health points. If the target's health is lower than or equal to your warrior's attack, the unit will be destroyed.",
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('tutorial-opponent-crop-1')),
      findsNothing,
    );
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
      findsNWidgets(3),
    );
    expect(
      find.byKey(const ValueKey('tutorial-warrior-attack-action')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('tutorial-pass-turn')), findsNothing);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text('Attacks per turn'), findsOneWidget);
    expect(
      find.text(
        'Warriors can attack only once per turn. They can attack again when your next turn begins. Press Pass to end your turn.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('tutorial-pass-turn')), findsNothing);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tutorial-pass-turn')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tutorial-pass-turn')));
    await tester.pump();
    expect(find.text('🤖 AI ROLLING DICE...'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/dados/3x6.png',
      ),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    final opponentTower = tester.widget<TorreTablero>(
      find.byKey(const ValueKey('tutorial-opponent-tower')),
    );
    expect(opponentTower.torre.coordenada, 'E3');
    expect(opponentTower.torre.torreBase.id, 'torre_azteca');
    expect(opponentTower.torre.ataqueActual, 12);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('tutorial-opponent-points')))
          .data,
      '0',
    );

    final playerPointsBeforeDefenseTurn = int.parse(
      tester
          .widget<Text>(find.byKey(const ValueKey('tutorial-player-points')))
          .data!,
    );
    final cropHealthBeforeDefenseTurn =
        tester
            .widget<Text>(
              find.byKey(const ValueKey('tutorial-player-crop-health-4')),
            )
            .data!;
    final playerCropProductionBeforeDefenseTurn = [1, 3, 4].fold<int>(0, (
      total,
      column,
    ) {
      final cropStats =
          tester
              .widget<Text>(
                find.byKey(ValueKey('tutorial-player-crop-health-$column')),
              )
              .data!;
      return total + int.parse(cropStats.split('🌾 ').last.split('   ').first);
    });

    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(find.text('🎲 ROLLING DICE...'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/dados/2x5.png',
      ),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('An enemy tower!'), findsOneWidget);
    expect(
      find.text(
        'The enemy has built a tower and increased its attack power. At the start of a turn, towers attack the first opposing target in front of them. Our crop is in danger!',
      ),
      findsOneWidget,
    );
    expect(
      int.parse(
        tester
            .widget<Text>(find.byKey(const ValueKey('tutorial-player-points')))
            .data!,
      ),
      playerPointsBeforeDefenseTurn + 7 + playerCropProductionBeforeDefenseTurn,
    );
    final cropHealthAfterDefenseTurn =
        tester
            .widget<Text>(
              find.byKey(const ValueKey('tutorial-player-crop-health-4')),
            )
            .data!;
    expect(
      int.parse(cropHealthAfterDefenseTurn.split('❤️ ').last),
      int.parse(cropHealthBeforeDefenseTurn.split('❤️ ').last) + 1,
    );

    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text('Protect your crop'), findsOneWidget);
    expect(
      find.text('To protect our crop, we can place a building in front of it.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('tutorial-summon-hospital')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('tutorial-summon-hospital')));
    await tester.pumpAndSettle();
    expect(find.text('Mayan Hospital'), findsOneWidget);
    expect(find.text('💊 1   ❤️ 60'), findsOneWidget);
    expect(find.text('⚡ 6'), findsOneWidget);
    expect(find.text('Aztec Hospital'), findsNothing);
    expect(find.text('Warrior'), findsNothing);
    expect(find.text('Mayan Villager'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('tutorial-hospital-option')));
    await tester.pumpAndSettle();
    final playerHospital = tester.widget<HospitalTablero>(
      find.byKey(const ValueKey('tutorial-player-hospital')),
    );
    expect(playerHospital.hospital.coordenada, 'E0');
    expect(playerHospital.hospital.hospitalBase.id, 'hospital_maya');
    expect(
      int.parse(
        tester
            .widget<Text>(find.byKey(const ValueKey('tutorial-player-points')))
            .data!,
      ),
      playerPointsBeforeDefenseTurn +
          7 +
          playerCropProductionBeforeDefenseTurn -
          6,
    );
    expect(
      find.byKey(const ValueKey('tutorial-summon-hospital')),
      findsNothing,
    );
    expect(find.text('Hospital healing'), findsOneWidget);
    expect(
      find.text(
        'Hospitals heal your warriors and villagers in the same row or column. At the start of each turn, hospitals use their healing power 💊 to restore health to your warriors and villagers.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text('Use the hospital to your advantage'), findsOneWidget);
    expect(
      find.text(
        'Remember to attack whenever possible on each of your turns. Move your warrior to attack another crop while positioning it to benefit strategically from your hospital.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();

    final warriorBeforeHospitalMove = tester.getTopLeft(
      find.byKey(const ValueKey('tutorial-warrior-piece')),
    );
    final hospitalPosition = tester.getTopLeft(
      find.byKey(const ValueKey('tutorial-player-hospital')),
    );
    await tester.tap(find.byKey(const ValueKey('tutorial-warrior-piece')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('tutorial-warrior-move-action')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('tutorial-warrior-move-action')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Move beside the hospital'), findsOneWidget);
    expect(
      find.text(
        'Select the highlighted square to place your warrior in the same row as the hospital and in front of another enemy crop.',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('tutorial-warrior-move-target')),
      findsOneWidget,
    );
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('tutorial-warrior-move-target')),
    );
    await tester.pumpAndSettle();
    final warriorHospitalRowPosition = tester.getTopLeft(
      find.byKey(const ValueKey('tutorial-warrior-piece')),
    );
    expect(
      warriorHospitalRowPosition.dx,
      lessThan(warriorBeforeHospitalMove.dx),
    );
    expect(warriorHospitalRowPosition.dy, closeTo(hospitalPosition.dy, 0.1));
    expect(find.text('Attack the crop'), findsOneWidget);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tutorial-warrior-piece')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('tutorial-warrior-attack-action')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('tutorial-warrior-attack-action')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('tutorial-opponent-crop-0')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('tutorial-opponent-crop-3')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('tutorial-opponent-crop-4')),
      findsOneWidget,
    );
    expect(find.text('Attack damage'), findsNothing);
    expect(find.text('Attacks per turn'), findsNothing);
    expect(find.byKey(const ValueKey('tutorial-pass-turn')), findsOneWidget);

    final towerBeforeFinalOpponentTurn = tester.widget<TorreTablero>(
      find.byKey(const ValueKey('tutorial-opponent-tower')),
    );
    final towerAttack = towerBeforeFinalOpponentTurn.torre.ataqueActual;
    final hospitalBeforeTowerAttack = tester.widget<HospitalTablero>(
      find.byKey(const ValueKey('tutorial-player-hospital')),
    );
    final hospitalHealth = hospitalBeforeTowerAttack.hospital.vidaActual;
    await tester.tap(find.byKey(const ValueKey('tutorial-pass-turn')));
    await tester.pump();
    expect(find.text('🤖 AI ROLLING DICE...'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/dados/5x6.png',
      ),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final opponentCropCellSizeOnFinalTurn = tester.getSize(
      find.byKey(const ValueKey('tutorial-opponent-crop-3')),
    );
    final opponentCropDuringHarvest = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('tutorial-opponent-crop-harvest-3')),
    );
    expect(
      opponentCropDuringHarvest.constraints!.maxWidth,
      closeTo(opponentCropCellSizeOnFinalTurn.width * 0.9 * 1.1, 0.1),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    final towerDuringAttack = tester.widget<TorreTablero>(
      find.byKey(const ValueKey('tutorial-opponent-tower')),
    );
    final hospitalDuringAttack = tester.widget<HospitalTablero>(
      find.byKey(const ValueKey('tutorial-player-hospital')),
    );
    expect(towerDuringAttack.torre.animar, isTrue);
    expect(hospitalDuringAttack.hospital.resplandor, isTrue);
    expect(
      hospitalDuringAttack.hospital.vidaActual,
      hospitalHealth - towerAttack,
    );
    expect(
      int.parse(
        tester
            .widget<Text>(
              find.byKey(const ValueKey('tutorial-opponent-points')),
            )
            .data!,
      ),
      greaterThan(11),
    );

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(
      tester
          .widget<TorreTablero>(
            find.byKey(const ValueKey('tutorial-opponent-tower')),
          )
          .torre
          .animar,
      isFalse,
    );
    final opponentWarriorDuringSummon = tester.widget<GuerreroTablero>(
      find.byKey(const ValueKey('tutorial-opponent-warrior')),
    );
    expect(opponentWarriorDuringSummon.guerrero, isA<GuerreroCampo>());
    expect(opponentWarriorDuringSummon.guerrero.coordenada, 'A3');
    expect(opponentWarriorDuringSummon.guerrero.animar, isTrue);
    expect(opponentWarriorDuringSummon.guerrero.guerreroBase.id, 'azteca_001');
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('tutorial-opponent-points')))
          .data,
      '6',
    );

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    final opponentWarriorDuringAttack = tester.widget<GuerreroTablero>(
      find.byKey(const ValueKey('tutorial-opponent-warrior')),
    );
    expect(opponentWarriorDuringAttack.guerrero.animar, isTrue);
    expect(opponentWarriorDuringAttack.guerrero.yaAtacoEsteTurno, isTrue);
    final playerWarriorDecoration =
        tester
                .widget<AnimatedContainer>(
                  find.byKey(const ValueKey('tutorial-warrior-piece')),
                )
                .decoration!
            as BoxDecoration;
    expect(playerWarriorDecoration.boxShadow, isNotEmpty);
    expect(
      tester
          .widget<Text>(
            find.descendant(
              of: find.byKey(const ValueKey('tutorial-warrior-piece')),
              matching: find.byType(Text),
            ),
          )
          .data,
      contains('❤️ 11'),
    );

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<GuerreroTablero>(
            find.byKey(const ValueKey('tutorial-opponent-warrior')),
          )
          .guerrero
          .animar,
      isFalse,
    );
    expect(
      tester
          .widget<HospitalTablero>(
            find.byKey(const ValueKey('tutorial-player-hospital')),
          )
          .hospital
          .resplandor,
      isFalse,
    );

    await tester.pumpAndSettle();
    expect(find.text('🎲 ROLLING DICE...'), findsOneWidget);
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
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Summon another warrior'), findsOneWidget);
    expect(
      tester
          .widget<Text>(
            find.descendant(
              of: find.byKey(const ValueKey('tutorial-warrior-piece')),
              matching: find.byType(Text),
            ),
          )
          .data,
      contains('❤️ 13'),
    );
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tutorial-summon-joan')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tutorial-summon-joan')));
    await tester.pumpAndSettle();
    expect(find.text('Joan of Arc'), findsOneWidget);
    expect(find.text('Kukulkan'), findsNothing);
    expect(find.text('Huitzilopochtli'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('tutorial-joan-option')));
    await tester.pumpAndSettle();
    final joan = tester.widget<GuerreroTablero>(
      find.byKey(const ValueKey('tutorial-player-joan')),
    );
    expect(joan.guerrero.coordenada, 'D2');
    expect(joan.guerrero.guerreroBase.id, 'francia_001');
    expect(find.text('Attack the crop'), findsOneWidget);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tutorial-player-joan')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('tutorial-joan-attack-action')),
      findsOneWidget,
    );
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Joan of Arc'), findsOneWidget);
    expect(find.text('⚔️ 12'), findsOneWidget);
    expect(find.text('❤️ 28'), findsOneWidget);
    expect(find.text('CANCEL'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tutorial-joan-attack-action')));
    await tester.pump();
    expect(
      tester
          .widget<GuerreroTablero>(
            find.byKey(const ValueKey('tutorial-player-joan')),
          )
          .guerrero
          .animar,
      isTrue,
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('tutorial-opponent-crop-3')),
      findsNothing,
    );
    expect(find.text('Kukulkan can still attack'), findsOneWidget);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tutorial-warrior-piece')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('tutorial-warrior-attack-action')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('tutorial-warrior-attack-action')),
    );
    await tester.pump();
    final damagedOpponentWarrior = tester.widget<GuerreroTablero>(
      find.byKey(const ValueKey('tutorial-opponent-warrior')),
    );
    expect(damagedOpponentWarrior.guerrero.vidaActual, 16);
    expect(damagedOpponentWarrior.guerrero.resplandor, isTrue);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<GuerreroTablero>(
            find.byKey(const ValueKey('tutorial-opponent-warrior')),
          )
          .guerrero
          .resplandor,
      isFalse,
    );
    expect(find.byKey(const ValueKey('tutorial-pass-turn')), findsNothing);
    expect(find.text('Protect your warriors'), findsOneWidget);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text('Move your warriors'), findsOneWidget);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();

    final hospitalBoardPosition = tester.getTopLeft(
      find.byKey(const ValueKey('tutorial-player-hospital')),
    );
    await tester.tap(find.byKey(const ValueKey('tutorial-warrior-piece')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('tutorial-kukulkan-defensive-move-action')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('tutorial-kukulkan-defensive-move-action')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Choose a square'), findsOneWidget);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('tutorial-warrior-move-target')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('tutorial-warrior-move-target')),
    );
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();
    final kukulkanBehindHospitalPosition = tester.getTopLeft(
      find.byKey(const ValueKey('tutorial-warrior-piece')),
    );
    expect(
      kukulkanBehindHospitalPosition.dx,
      closeTo(hospitalBoardPosition.dx, 0.1),
    );
    expect(
      kukulkanBehindHospitalPosition.dy,
      greaterThan(hospitalBoardPosition.dy),
    );

    final joanBeforeMove = tester.getTopLeft(
      find.byKey(const ValueKey('tutorial-player-joan')),
    );
    await tester.tap(find.byKey(const ValueKey('tutorial-player-joan')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('tutorial-joan-defensive-move-action')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('tutorial-joan-defensive-move-action')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Choose a square'), findsOneWidget);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('tutorial-warrior-move-target')),
    );
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();
    final joanBehindHospitalPosition = tester.getTopLeft(
      find.byKey(const ValueKey('tutorial-player-joan')),
    );
    expect(
      joanBehindHospitalPosition.dx,
      closeTo(hospitalBoardPosition.dx, 0.1),
    );
    expect(joanBehindHospitalPosition.dy, closeTo(joanBeforeMove.dy, 0.1));
    expect(find.text('End your turn'), findsOneWidget);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tutorial-pass-turn')), findsOneWidget);

    final kukulkanHealthBeforeNewTurn = int.parse(
      tester
          .widget<Text>(
            find.descendant(
              of: find.byKey(const ValueKey('tutorial-warrior-piece')),
              matching: find.byType(Text),
            ),
          )
          .data!
          .split('❤️ ')
          .last,
    );
    final joanHealthBeforeNewTurn =
        tester
            .widget<GuerreroTablero>(
              find.byKey(const ValueKey('tutorial-player-joan')),
            )
            .guerrero
            .vidaActual;
    final playerPointsBeforeNewTurn = int.parse(
      tester
          .widget<Text>(find.byKey(const ValueKey('tutorial-player-points')))
          .data!,
    );
    final opponentPointsBeforeEarthquake = int.parse(
      tester
          .widget<Text>(find.byKey(const ValueKey('tutorial-opponent-points')))
          .data!,
    );
    await tester.tap(find.byKey(const ValueKey('tutorial-pass-turn')));
    await tester.pump();
    expect(find.text('🌍 EARTHQUAKE 🌍'), findsOneWidget);
    final earthquakeDialog = tester.widget<Dialog>(find.byType(Dialog));
    final earthquakeCard = earthquakeDialog.child! as Container;
    final earthquakeDecoration = earthquakeCard.decoration! as BoxDecoration;
    expect(earthquakeDecoration.gradient, isA<LinearGradient>());
    expect(earthquakeDecoration.borderRadius, BorderRadius.circular(24));
    expect((earthquakeDecoration.border! as Border).top.width, 3);
    expect(find.byKey(const ValueKey('tutorial-opponent-tower')), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('tutorial-opponent-monument')),
        matching: find.text('76'),
      ),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('🌍 EARTHQUAKE 🌍'), findsNothing);
    expect(find.text('Earthquakes'), findsOneWidget);
    expect(
      find.text(
        'When an earthquake hits a city, towers, hospitals, and monuments are affected and may even be completely destroyed. Earthquakes can eventually happen in either city.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Got it'));
    await tester.pump();
    expect(
      int.parse(
        tester
            .widget<Text>(
              find.byKey(const ValueKey('tutorial-opponent-points')),
            )
            .data!,
      ),
      greaterThan(opponentPointsBeforeEarthquake),
    );
    await tester.pump(const Duration(milliseconds: 1800));
    for (final column in [0, 1, 3, 4]) {
      expect(
        find.byKey(ValueKey('tutorial-opponent-crop-$column')),
        findsOneWidget,
      );
    }
    final opponentWarriorAttackingVillager = tester.widget<GuerreroTablero>(
      find.byKey(const ValueKey('tutorial-opponent-warrior')),
    );
    expect(opponentWarriorAttackingVillager.guerrero.animar, isTrue);
    final villagerDuringAttack = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('tutorial-villager-hammer-animation')),
    );
    expect(
      (villagerDuringAttack.decoration! as BoxDecoration).boxShadow,
      isNotEmpty,
    );
    expect(
      tester
          .widget<Text>(
            find.descendant(
              of: find.byKey(const ValueKey('tutorial-villager-piece')),
              matching: find.byType(Text),
            ),
          )
          .data,
      contains('👨 -'),
    );
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();
    expect(find.text('🎲 ROLLING DICE...'), findsOneWidget);
    expect(find.byKey(const ValueKey('tutorial-opponent-tower')), findsNothing);
    for (final column in [0, 1, 3, 4]) {
      expect(
        find.byKey(ValueKey('tutorial-opponent-crop-$column')),
        findsOneWidget,
      );
    }
    expect(find.byKey(const ValueKey('tutorial-villager-piece')), findsNothing);
    expect(
      tester
          .widget<GuerreroTablero>(
            find.byKey(const ValueKey('tutorial-opponent-warrior')),
          )
          .guerrero
          .vidaActual,
      16,
    );
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('🎲 ROLLING DICE...'), findsOneWidget);
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
    for (var elapsed = 0; elapsed < 2000; elapsed += 100) {
      await tester.pump(const Duration(milliseconds: 100));
      if (tester
          .widget<HospitalTablero>(
            find.byKey(const ValueKey('tutorial-player-hospital')),
          )
          .hospital
          .animar) {
        break;
      }
    }
    expect(
      int.parse(
        tester
            .widget<Text>(find.byKey(const ValueKey('tutorial-player-points')))
            .data!,
      ),
      greaterThanOrEqualTo(playerPointsBeforeNewTurn + 9),
    );
    final healingHospital = tester.widget<HospitalTablero>(
      find.byKey(const ValueKey('tutorial-player-hospital')),
    );
    expect(healingHospital.hospital.animar, isTrue);
    expect(
      (tester
                  .widget<AnimatedContainer>(
                    find.byKey(const ValueKey('tutorial-warrior-piece')),
                  )
                  .decoration!
              as BoxDecoration)
          .boxShadow,
      isNotEmpty,
    );
    final healingJoan = tester.widget<GuerreroTablero>(
      find.byKey(const ValueKey('tutorial-player-joan')),
    );
    expect(healingJoan.guerrero.resplandor, isTrue);
    expect(
      healingJoan.guerrero.vidaActual,
      (joanHealthBeforeNewTurn + 2).clamp(
        0,
        healingJoan.guerrero.guerreroBase.vida,
      ),
    );
    expect(find.byKey(const ValueKey('tutorial-villager-piece')), findsNothing);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<HospitalTablero>(
            find.byKey(const ValueKey('tutorial-player-hospital')),
          )
          .hospital
          .animar,
      isFalse,
    );
    final kukulkanHealthAfterNewTurn = int.parse(
      tester
          .widget<Text>(
            find.descendant(
              of: find.byKey(const ValueKey('tutorial-warrior-piece')),
              matching: find.byType(Text),
            ),
          )
          .data!
          .split('❤️ ')
          .last,
    );
    expect(
      kukulkanHealthAfterNewTurn,
      greaterThan(kukulkanHealthBeforeNewTurn),
    );
    expect(
      kukulkanHealthAfterNewTurn,
      lessThanOrEqualTo(kukulkanHealthBeforeNewTurn + 2),
    );
    expect(find.text('Huitzilopochtli is weak'), findsOneWidget);
    expect(
      find.text(
        'Huitzilopochtli is weak; it is time to finish him. Tap Kukulkan to move him in front of the enemy warrior.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tutorial-warrior-piece')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('tutorial-kukulkan-defensive-move-action')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('tutorial-kukulkan-defensive-move-action')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Place Kukulkan in front of the enemy'), findsOneWidget);
    expect(
      find.text(
        "Select the highlighted square in the hospital's row to place Kukulkan in front of Huitzilopochtli.",
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('tutorial-warrior-move-target')),
      findsOneWidget,
    );
    final hospitalRowPosition = tester.getTopLeft(
      find.byKey(const ValueKey('tutorial-player-hospital')),
    );
    final enemyWarriorColumnPosition = tester.getTopLeft(
      find.byKey(const ValueKey('tutorial-opponent-warrior')),
    );
    await tester.tap(
      find.byKey(const ValueKey('tutorial-warrior-move-target')),
    );
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();
    final kukulkanInFrontOfEnemy = tester.getTopLeft(
      find.byKey(const ValueKey('tutorial-warrior-piece')),
    );
    expect(
      kukulkanInFrontOfEnemy.dx,
      closeTo(enemyWarriorColumnPosition.dx, 0.1),
    );
    expect(kukulkanInFrontOfEnemy.dy, closeTo(hospitalRowPosition.dy, 0.1));
    expect(find.text('Attack the enemy'), findsOneWidget);
    expect(find.text('Tap Kukulkan and attack the enemy.'), findsOneWidget);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tutorial-warrior-piece')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('tutorial-kukulkan-enemy-attack-action')),
      findsOneWidget,
    );
    expect(find.text('ATTACK'), findsOneWidget);
    final opponentBeforeKukulkanAttack = tester.widget<GuerreroTablero>(
      find.byKey(const ValueKey('tutorial-opponent-warrior')),
    );
    expect(opponentBeforeKukulkanAttack.guerrero.vidaActual, 16);
    await tester.tap(
      find.byKey(const ValueKey('tutorial-kukulkan-enemy-attack-action')),
    );
    await tester.pump();
    final attackerDuringAnimation = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('tutorial-warrior-attack-animation')),
    );
    expect(
      attackerDuringAnimation.constraints!.maxWidth,
      lessThan(
        tester
            .getSize(find.byKey(const ValueKey('tutorial-warrior-piece')))
            .width,
      ),
    );
    final opponentDuringAnimation = tester.widget<GuerreroTablero>(
      find.byKey(const ValueKey('tutorial-opponent-warrior')),
    );
    expect(opponentDuringAnimation.guerrero.animar, isTrue);
    expect(opponentDuringAnimation.guerrero.resplandor, isTrue);
    expect(opponentDuringAnimation.guerrero.vidaActual, -2);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('tutorial-opponent-warrior')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('tutorial-warrior-piece')),
      findsOneWidget,
    );
    expect(find.text('Weaken the enemy further'), findsOneWidget);
    expect(
      find.text(
        "Tap Joan of Arc to attack the enemy's other crop and weaken them further.",
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tutorial-player-joan')));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Joan of Arc'), findsOneWidget);
    expect(find.text('⚔️ 12'), findsOneWidget);
    expect(find.text('❤️ 28'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('tutorial-joan-attack-action')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('tutorial-joan-attack-action')));
    await tester.pump();
    final joanAttacking = tester.widget<GuerreroTablero>(
      find.byKey(const ValueKey('tutorial-player-joan')),
    );
    expect(joanAttacking.guerrero.animar, isTrue);
    final finalOpponentCropDuringAttack = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('tutorial-opponent-crop-glow-4')),
    );
    expect(
      (finalOpponentCropDuringAttack.decoration! as BoxDecoration).boxShadow,
      isNotEmpty,
    );
    expect(
      find.byKey(const ValueKey('tutorial-opponent-crop-4')),
      findsOneWidget,
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('tutorial-opponent-crop-4')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('tutorial-opponent-crop-3')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<GuerreroTablero>(
            find.byKey(const ValueKey('tutorial-player-joan')),
          )
          .guerrero
          .animar,
      isFalse,
    );
    expect(find.text('Summon more warriors'), findsOneWidget);
    expect(
      find.text('We can keep summoning warriors to attack the crops.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    for (final column in [1, 3]) {
      expect(
        find.byKey(ValueKey('tutorial-summon-terracotta-$column')),
        findsOneWidget,
      );
    }

    final pointsBeforeTerracottaInvocations = int.parse(
      tester
          .widget<Text>(find.byKey(const ValueKey('tutorial-player-points')))
          .data!,
    );
    await tester.tap(
      find.byKey(const ValueKey('tutorial-summon-terracotta-1')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Terracotta Warrior'), findsOneWidget);
    expect(find.text('Kukulkan'), findsNothing);
    expect(find.text('Joan of Arc'), findsNothing);
    expect(
      find.byKey(const ValueKey('tutorial-terracotta-option-1')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('tutorial-terracotta-option-1')),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey('tutorial-terracotta-warrior-1')),
      findsOneWidget,
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<GuerreroTablero>(
            find.byKey(const ValueKey('tutorial-terracotta-warrior-1')),
          )
          .guerrero
          .coordenada,
      'B2',
    );
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('tutorial-player-points')))
          .data,
      '${pointsBeforeTerracottaInvocations - 12}',
    );

    await tester.tap(
      find.byKey(const ValueKey('tutorial-summon-terracotta-3')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Terracotta Warrior'), findsOneWidget);
    expect(find.text('Kukulkan'), findsNothing);
    expect(find.text('Joan of Arc'), findsNothing);
    await tester.tap(
      find.byKey(const ValueKey('tutorial-terracotta-option-3')),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey('tutorial-terracotta-warrior-3')),
      findsOneWidget,
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<GuerreroTablero>(
            find.byKey(const ValueKey('tutorial-terracotta-warrior-3')),
          )
          .guerrero
          .coordenada,
      'D2',
    );
    expect(
      find.byKey(const ValueKey('tutorial-summon-terracotta-1')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('tutorial-summon-terracotta-3')),
      findsNothing,
    );
    expect(find.text('Attack!'), findsOneWidget);
    expect(
      find.text(
        'Use your new warriors who have not attacked yet to destroy more enemy crops. Tap your Terracotta Warriors to attack the crops.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();

    for (final column in [1, 3]) {
      final warriorFinder = find.byKey(
        ValueKey('tutorial-terracotta-warrior-$column'),
      );
      await tester.tap(warriorFinder);
      await tester.pumpAndSettle();
      expect(find.text('Terracotta Warrior'), findsOneWidget);
      expect(
        find.byKey(ValueKey('tutorial-terracotta-attack-action-$column')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(ValueKey('tutorial-terracotta-attack-action-$column')),
      );
      await tester.pump();

      final attackingWarrior = tester.widget<GuerreroTablero>(warriorFinder);
      expect(attackingWarrior.guerrero.animar, isTrue);
      expect(attackingWarrior.guerrero.yaAtacoEsteTurno, isTrue);
      final targetCropDuringAttack = tester.widget<AnimatedContainer>(
        find.byKey(ValueKey('tutorial-opponent-crop-glow-$column')),
      );
      expect(
        (targetCropDuringAttack.decoration! as BoxDecoration).boxShadow,
        isNotEmpty,
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey('tutorial-opponent-crop-$column')),
        findsNothing,
      );
      expect(
        tester.widget<GuerreroTablero>(warriorFinder).guerrero.animar,
        isFalse,
      );
    }

    expect(find.text('End your turn'), findsOneWidget);
    expect(
      find.text(
        'We have no more warriors to attack with. Press Pass to end your turn.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('tutorial-pass-turn')), findsNothing);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tutorial-pass-turn')), findsOneWidget);

    final opponentPointsBeforeTurn = int.parse(
      tester
          .widget<Text>(find.byKey(const ValueKey('tutorial-opponent-points')))
          .data!,
    );
    final playerPointsBeforeTurn = int.parse(
      tester
          .widget<Text>(find.byKey(const ValueKey('tutorial-player-points')))
          .data!,
    );
    final opponentCropProductionBeforeTurn = int.parse(
      RegExp(r'🌾 (\d+)').firstMatch(
        tester
            .widget<Text>(
              find.byKey(const ValueKey('tutorial-opponent-crop-production-0')),
            )
            .data!,
      )![1]!,
    );
    final kukulkanHealthBeforeEpidemic = int.parse(
      RegExp(r'❤️ (\d+)').firstMatch(
        tester
            .widget<Text>(
              find.byKey(const ValueKey('tutorial-player-warrior-stats')),
            )
            .data!,
      )![1]!,
    );
    final joanHealthBeforeEpidemic =
        tester
            .widget<GuerreroTablero>(
              find.byKey(const ValueKey('tutorial-player-joan')),
            )
            .guerrero
            .vidaActual;
    final terracottaHealthBeforeEpidemic = <int, int>{
      for (final column in [1, 3])
        column:
            tester
                .widget<GuerreroTablero>(
                  find.byKey(ValueKey('tutorial-terracotta-warrior-$column')),
                )
                .guerrero
                .vidaActual,
    };
    var playerCropProductionBeforeTurn = 0;
    for (final column in [1, 3, 4]) {
      final productionFinder = find.byKey(
        ValueKey('tutorial-player-crop-health-$column'),
      );
      if (productionFinder.evaluate().isNotEmpty) {
        final productionText = tester.widget<Text>(productionFinder).data!;
        playerCropProductionBeforeTurn += int.parse(
          RegExp(r'🌾 (\d+)').firstMatch(productionText)![1]!,
        );
      }
    }

    await tester.tap(find.byKey(const ValueKey('tutorial-pass-turn')));
    await tester.pump();
    expect(find.text('🤖 AI ROLLING DICE...'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/dados/1x1.png',
      ),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 600));

    expect(
      find.byKey(const ValueKey('tutorial-epidemic-dialog')),
      findsOneWidget,
    );
    expect(find.text('🦠 EPIDEMIC 🦠'), findsOneWidget);
    expect(kukulkanHealthBeforeEpidemic, lessThanOrEqualTo(16));
    expect(
      find.byKey(const ValueKey('tutorial-player-warrior-stats')),
      findsNothing,
    );
    expect(
      tester
          .widget<GuerreroTablero>(
            find.byKey(const ValueKey('tutorial-player-joan')),
          )
          .guerrero
          .vidaActual,
      joanHealthBeforeEpidemic - 16,
    );
    for (final column in [1, 3]) {
      expect(
        tester
            .widget<GuerreroTablero>(
              find.byKey(ValueKey('tutorial-terracotta-warrior-$column')),
            )
            .guerrero
            .vidaActual,
        terracottaHealthBeforeEpidemic[column]! - 16,
      );
    }

    await tester.pump(const Duration(seconds: 2));
    expect(
      find.byKey(const ValueKey('tutorial-epidemic-dialog')),
      findsNothing,
    );
    expect(find.text('🎲 ROLLING DICE...'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/dados/2x5.png',
      ),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('tutorial-opponent-points')))
          .data,
      '0',
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('tutorial-opponent-crop-production-0')),
          )
          .data,
      '🌾 ${opponentCropProductionBeforeTurn + opponentPointsBeforeTurn + 4}   ❤️ 3',
    );
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('tutorial-player-points')))
          .data,
      '${playerPointsBeforeTurn + 7 + playerCropProductionBeforeTurn}',
    );
    expect(
      tester
          .widget<GuerreroTablero>(
            find.byKey(const ValueKey('tutorial-player-joan')),
          )
          .guerrero
          .vidaActual,
      (joanHealthBeforeEpidemic - 16 + 2).clamp(0, 28),
    );
    expect(
      tester
          .widget<HospitalTablero>(
            find.byKey(const ValueKey('tutorial-player-hospital')),
          )
          .hospital
          .animar,
      isFalse,
    );
    expect(
      find.byKey(const ValueKey('tutorial-opponent-crop-0')),
      findsOneWidget,
    );
    expect(find.text('Epidemics'), findsOneWidget);
    expect(
      find.text(
        'You have just suffered an epidemic. Your warriors and villagers will be weakened, and some may even die. Epidemics eventually occur in every civilization.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();

    expect(find.text('Summon another warrior'), findsOneWidget);
    expect(
      find.text(
        "Let's summon another warrior to destroy the enemy's last crop.",
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('tutorial-summon-epidemic-kukulkan')),
      findsOneWidget,
    );

    final pointsBeforeKukulkanSummon = int.parse(
      tester
          .widget<Text>(find.byKey(const ValueKey('tutorial-player-points')))
          .data!,
    );
    await tester.tap(
      find.byKey(const ValueKey('tutorial-summon-epidemic-kukulkan')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Kukulkan'), findsOneWidget);
    expect(find.text('Terracotta Warrior'), findsNothing);
    expect(find.text('Joan of Arc'), findsNothing);
    expect(
      find.byKey(const ValueKey('tutorial-epidemic-kukulkan-option')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('tutorial-epidemic-kukulkan-option')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('tutorial-summon-epidemic-kukulkan')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('tutorial-epidemic-kukulkan-warrior')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('tutorial-player-warrior-stats')),
          )
          .data,
      '⚔️ 18   ❤️ 28',
    );
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('tutorial-player-points')))
          .data,
      '${pointsBeforeKukulkanSummon - 16}',
    );
    expect(find.text('Destroy the last crop'), findsOneWidget);
    expect(
      find.text('Tap Kukulkan to attack the last enemy crop.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('tutorial-epidemic-kukulkan-warrior')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Kukulkan'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('tutorial-epidemic-kukulkan-attack-action')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('tutorial-epidemic-kukulkan-attack-action')),
    );
    await tester.pump();
    expect(
      tester
          .widget<AnimatedContainer>(
            find.byKey(const ValueKey('tutorial-warrior-attack-animation')),
          )
          .constraints!
          .maxWidth,
      lessThan(
        tester
            .getSize(
              find.byKey(const ValueKey('tutorial-epidemic-kukulkan-warrior')),
            )
            .width,
      ),
    );
    expect(
      (tester
                  .widget<AnimatedContainer>(
                    find.byKey(const ValueKey('tutorial-opponent-crop-glow-0')),
                  )
                  .decoration!
              as BoxDecoration)
          .boxShadow,
      isNotEmpty,
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('tutorial-opponent-crop-0')),
      findsNothing,
    );
    expect(find.text('Attack the monument'), findsOneWidget);
    expect(
      find.text(
        'The enemy has no other elements on the board. Your warriors can attack the monument freely from where they are; there is no need to reposition them. Tap Joan of Arc and your two Terracotta Warriors, who have not attacked yet, and select Attack.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();

    final monumentHealthBeforeAttacks =
        tester
            .widget<MonumentoTablero>(
              find.byKey(const ValueKey('tutorial-opponent-monument')),
            )
            .vida;
    final monumentAttackerFinders = <String, Finder>{
      'joan': find.byKey(const ValueKey('tutorial-player-joan')),
      'terracotta-1': find.byKey(
        const ValueKey('tutorial-terracotta-warrior-1'),
      ),
      'terracotta-3': find.byKey(
        const ValueKey('tutorial-terracotta-warrior-3'),
      ),
    };
    final monumentAttackDamage = <String, int>{
      'joan': 12,
      'terracotta-1': 8,
      'terracotta-3': 8,
    };
    await tester.tap(
      find.byKey(const ValueKey('tutorial-epidemic-kukulkan-warrior')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    var totalMonumentDamage = 0;
    for (final warriorId in ['joan', 'terracotta-1', 'terracotta-3']) {
      await tester.tap(monumentAttackerFinders[warriorId]!);
      await tester.pumpAndSettle();
      expect(
        find.text(warriorId == 'joan' ? 'Joan of Arc' : 'Terracotta Warrior'),
        findsOneWidget,
      );
      final attackAction = find.byKey(
        ValueKey('tutorial-monument-attack-action-$warriorId'),
      );
      expect(attackAction, findsOneWidget);
      await tester.tap(attackAction);
      await tester.pump();
      final glowingMonument = tester.widget<MonumentoTablero>(
        find.byKey(const ValueKey('tutorial-opponent-monument')),
      );
      expect(glowingMonument.resplandor, isTrue);
      totalMonumentDamage += monumentAttackDamage[warriorId]!;
      expect(
        glowingMonument.vida,
        monumentHealthBeforeAttacks - totalMonumentDamage,
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<MonumentoTablero>(
              find.byKey(const ValueKey('tutorial-opponent-monument')),
            )
            .resplandor,
        isFalse,
      );
    }
    expect(
      tester
          .widget<MonumentoTablero>(
            find.byKey(const ValueKey('tutorial-opponent-monument')),
          )
          .vida,
      48,
    );

    expect(find.text('End your turn'), findsOneWidget);
    expect(find.byKey(const ValueKey('tutorial-pass-turn')), findsNothing);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tutorial-pass-turn')), findsOneWidget);

    final opponentPointsBeforeMonumentTurn = int.parse(
      tester
          .widget<Text>(find.byKey(const ValueKey('tutorial-opponent-points')))
          .data!,
    );
    final playerPointsBeforePlagueTurn = int.parse(
      tester
          .widget<Text>(find.byKey(const ValueKey('tutorial-player-points')))
          .data!,
    );
    final joanHealthBeforePlagueTurn =
        tester
            .widget<GuerreroTablero>(
              find.byKey(const ValueKey('tutorial-player-joan')),
            )
            .guerrero
            .vidaActual;
    await tester.tap(find.byKey(const ValueKey('tutorial-pass-turn')));
    await tester.pump();
    expect(find.text('🤖 AI ROLLING DICE...'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/dados/2x1.png',
      ),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byKey(const ValueKey('tutorial-plague-dialog')),
      findsOneWidget,
    );
    expect(find.text('🌾 PLAGUE IN CROPS 🌾'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('tutorial-opponent-crop-0')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('tutorial-opponent-crop-3')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('tutorial-opponent-points')))
          .data,
      '${opponentPointsBeforeMonumentTurn + 3 - 2}',
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('tutorial-opponent-crop-production-3')),
          )
          .data,
      '🌾 2   ❤️ 3',
    );
    for (final column in [1, 3, 4]) {
      expect(
        find.byKey(ValueKey('tutorial-player-crop-$column')),
        findsNothing,
      );
      expect(
        find.byKey(ValueKey('tutorial-summon-crop-$column')),
        findsNothing,
      );
    }

    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tutorial-plague-dialog')), findsNothing);
    expect(find.text('🎲 ROLLING DICE...'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/dados/5x6.png',
      ),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('tutorial-player-points')))
          .data,
      '${playerPointsBeforePlagueTurn + 11}',
    );
    expect(
      tester
          .widget<GuerreroTablero>(
            find.byKey(const ValueKey('tutorial-player-joan')),
          )
          .guerrero
          .vidaActual,
      (joanHealthBeforePlagueTurn + 2).clamp(0, 28),
    );
    expect(
      tester
          .widget<HospitalTablero>(
            find.byKey(const ValueKey('tutorial-player-hospital')),
          )
          .hospital
          .animar,
      isFalse,
    );
    expect(find.byKey(const ValueKey('tutorial-pass-turn')), findsNothing);
    expect(find.text('A plague has struck your crops'), findsOneWidget);
    expect(
      find.text(
        'Your crops were attacked by a plague. Plagues eventually affect every civilization, weakening or even destroying its crops.',
      ),
      findsOneWidget,
    );
    for (final column in [1, 3, 4]) {
      expect(
        find.byKey(ValueKey('tutorial-summon-crop-$column')),
        findsNothing,
      );
    }

    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text('Destroy the enemy crop'), findsOneWidget);
    expect(
      find.text(
        'Use your Terracotta Warrior in front of the enemy crop to destroy it. Tap the warrior to attack.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('tutorial-terracotta-warrior-1')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('tutorial-plague-terracotta-attack-action')),
      findsNothing,
    );
    await tester.tap(
      find.byKey(const ValueKey('tutorial-terracotta-warrior-3')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Terracotta Warrior'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('tutorial-plague-terracotta-attack-action')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('tutorial-plague-terracotta-attack-action')),
    );
    await tester.pump();

    final plagueAttackingWarrior = tester.widget<GuerreroTablero>(
      find.byKey(const ValueKey('tutorial-terracotta-warrior-3')),
    );
    expect(plagueAttackingWarrior.guerrero.animar, isTrue);
    expect(plagueAttackingWarrior.guerrero.yaAtacoEsteTurno, isTrue);
    final plagueTargetDuringAttack = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('tutorial-opponent-crop-glow-3')),
    );
    expect(
      (plagueTargetDuringAttack.decoration! as BoxDecoration).boxShadow,
      isNotEmpty,
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('tutorial-opponent-crop-3')),
      findsNothing,
    );
    expect(
      tester
          .widget<GuerreroTablero>(
            find.byKey(const ValueKey('tutorial-terracotta-warrior-3')),
          )
          .guerrero
          .animar,
      isFalse,
    );
    expect(find.byKey(const ValueKey('tutorial-pass-turn')), findsNothing);

    final pointsBeforeJoanUpgrade = int.parse(
      tester
          .widget<Text>(find.byKey(const ValueKey('tutorial-player-points')))
          .data!,
    );
    expect(
      find.text(
        "Warriors can increase their attack with your invocation points. Use them to increase Joan of Arc's attack: tap her and select the upgrade attack option.",
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tutorial-player-joan')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('tutorial-joan-upgrade-attack-action')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('tutorial-joan-upgrade-attack-action')),
    );
    await tester.pumpAndSettle();

    final joanAttackUpgradeSlider = tester.widget<Slider>(
      find.byKey(const ValueKey('tutorial-joan-attack-upgrade-slider')),
    );
    expect(joanAttackUpgradeSlider.min, 11);
    expect(joanAttackUpgradeSlider.max, pointsBeforeJoanUpgrade.toDouble());
    expect(joanAttackUpgradeSlider.value, 11);
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('tutorial-joan-attack-upgrade-points')),
          )
          .data,
      '11 ⚡',
    );
    await tester.tap(
      find.byKey(const ValueKey('tutorial-confirm-joan-attack-upgrade')),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<GuerreroTablero>(
            find.byKey(const ValueKey('tutorial-player-joan')),
          )
          .guerrero
          .ataqueActual,
      23,
    );
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('tutorial-player-points')))
          .data,
      '${pointsBeforeJoanUpgrade - 11}',
    );
    expect(
      find.text(
        'The monument has 48 health. Tap Kukulkan, the Terracotta Warrior, and Joan of Arc to attack; their combined attacks exceed its remaining health.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    var finalMonumentHealth = 48;
    final finalMonumentAttacks = <String, (Finder, int)>{
      'kukulkan': (
        find.byKey(const ValueKey('tutorial-epidemic-kukulkan-warrior')),
        18,
      ),
      'terracotta-1': (
        find.byKey(const ValueKey('tutorial-terracotta-warrior-1')),
        8,
      ),
      'joan': (find.byKey(const ValueKey('tutorial-player-joan')), 23),
    };
    for (final warriorId in ['kukulkan', 'terracotta-1', 'joan']) {
      final (warriorFinder, attackDamage) = finalMonumentAttacks[warriorId]!;
      await tester.tap(warriorFinder);
      await tester.pumpAndSettle();
      final attackAction = find.byKey(
        ValueKey('tutorial-final-monument-attack-action-$warriorId'),
      );
      expect(attackAction, findsOneWidget);
      await tester.tap(attackAction);
      await tester.pump();
      if (warriorId == 'kukulkan') {
        final attackingWarrior = tester.widget<AnimatedContainer>(
          find.byKey(const ValueKey('tutorial-warrior-attack-animation')),
        );
        expect(
          attackingWarrior.constraints!.maxWidth,
          lessThan(tester.getSize(warriorFinder).width),
        );
      } else {
        final attackingWarrior = tester.widget<GuerreroTablero>(warriorFinder);
        expect(attackingWarrior.guerrero.animar, isTrue);
        expect(attackingWarrior.guerrero.yaAtacoEsteTurno, isTrue);
      }
      final finalMonumentDuringAttack = tester.widget<MonumentoTablero>(
        find.byKey(const ValueKey('tutorial-opponent-monument')),
      );
      expect(finalMonumentDuringAttack.resplandor, isTrue);
      finalMonumentHealth = (finalMonumentHealth - attackDamage).clamp(
        0,
        finalMonumentHealth,
      );
      expect(finalMonumentDuringAttack.vida, finalMonumentHealth);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
    }

    expect(
      find.byKey(const ValueKey('tutorial-opponent-monument')),
      findsNothing,
    );
    expect(find.text('Victory!'), findsOneWidget);
    expect(
      find.text('Your warriors destroyed the enemy monument. You won!'),
      findsOneWidget,
    );

    final kukulkanPosition = tester.getTopLeft(
      find.byKey(const ValueKey('tutorial-epidemic-kukulkan-warrior')),
    );
    final terracottaPosition = tester.getTopLeft(
      find.byKey(const ValueKey('tutorial-terracotta-warrior-1')),
    );
    expect(terracottaPosition.dx, greaterThan(kukulkanPosition.dx));
    expect(terracottaPosition.dy, closeTo(kukulkanPosition.dy, 0.1));

    expect(
      find.byKey(const ValueKey('tutorial-opponent-crop-3')),
      findsNothing,
    );
    for (final column in [1, 4]) {
      expect(
        find.byKey(ValueKey('tutorial-opponent-crop-$column')),
        findsNothing,
      );
    }
    expect(find.text('🎲 TIRANDO DADOS...'), findsNothing);

    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text('Thanks for playing!'), findsOneWidget);
    expect(
      find.text(
        'Mitic is a game of free choice. Be creative as you defeat your enemy, and have fun trying!',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a game mode'), findsOneWidget);
    expect(find.text('Play vs. machine'), findsOneWidget);
    expect(find.text('Online multiplayer'), findsOneWidget);
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
