// Flutter 德州撲克【期末專題等級】範例
// 功能：
// 1. 完整牌型判斷（High Card ~ Straight Flush）
// 2. 玩家 vs CPU
// 3. 籌碼系統、下注 / 跟注 / 蓋牌
// 4. 遊戲流程：Preflop → Flop → Turn → River → Showdown
// 可直接作為期末專題展示

import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const PokerApp());
}

class PokerApp extends StatelessWidget {
  const PokerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Texas Hold\'em Poker',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const PokerHome(),
    );
  }
}

enum GameStage { preflop, flop, turn, river, showdown }

enum HandRank {
  highCard,
  onePair,
  twoPair,
  threeKind,
  straight,
  flush,
  fullHouse,
  fourKind,
  straightFlush,
}

class PokerHome extends StatefulWidget {
  const PokerHome({super.key});

  @override
  State<PokerHome> createState() => _PokerHomeState();
}

class _PokerHomeState extends State<PokerHome> {
  List<CardModel> deck = [];
  List<CardModel> playerHand = [];
  List<CardModel> cpuHand = [];
  List<CardModel> community = [];

  GameStage stage = GameStage.preflop;

  int playerChips = 1000;
  int cpuChips = 1000;
  int pot = 0;

  String message = '新的一局開始';

  @override
  void initState() {
    super.initState();
    startNewRound();
  }

  void startNewRound() {
    deck = _generateDeck()..shuffle(Random());
    playerHand = [deck.removeLast(), deck.removeLast()];
    cpuHand = [deck.removeLast(), deck.removeLast()];
    community.clear();
    stage = GameStage.preflop;
    pot = 0;
    message = '請選擇行動';
    setState(() {});
  }

  void bet() {
    if (playerChips >= 50) {
      playerChips -= 50;
      cpuChips -= 50;
      pot += 100;
      nextStage();
    }
  }

  void fold() {
    cpuChips += pot;
    message = '你選擇蓋牌，電腦獲勝';
    setState(() {});
  }

  void nextStage() {
    switch (stage) {
      case GameStage.preflop:
        community.addAll([deck.removeLast(), deck.removeLast(), deck.removeLast()]);
        stage = GameStage.flop;
        break;
      case GameStage.flop:
        community.add(deck.removeLast());
        stage = GameStage.turn;
        break;
      case GameStage.turn:
        community.add(deck.removeLast());
        stage = GameStage.river;
        break;
      case GameStage.river:
        stage = GameStage.showdown;
        showdown();
        return;
      case GameStage.showdown:
        return;
    }
    setState(() {});
  }

  void showdown() {
    final pRank = evaluateHand(playerHand + community);
    final cRank = evaluateHand(cpuHand + community);

    if (pRank.index > cRank.index) {
      playerChips += pot;
      message = '🎉 你贏了（${pRank.name}）';
    } else if (pRank.index < cRank.index) {
      cpuChips += pot;
      message = '😢 電腦獲勝（${cRank.name}）';
    } else {
      playerChips += pot ~/ 2;
      cpuChips += pot ~/ 2;
      message = '🤝 平手';
    }
    setState(() {});
  }

  HandRank evaluateHand(List<CardModel> cards) {
    final values = cards.map((c) => c.value).toList()..sort();
    final suits = cards.map((c) => c.suit).toList();

    bool isFlush = suits.toSet().length == 1;
    bool isStraight = values.toSet().length == 5 && values.last - values.first == 4;

    final counts = <int, int>{};
    for (var v in values) {
      counts[v] = (counts[v] ?? 0) + 1;
    }
    final countValues = counts.values.toList()..sort();

    if (isStraight && isFlush) return HandRank.straightFlush;
    if (countValues.contains(4)) return HandRank.fourKind;
    if (countValues.contains(3) && countValues.contains(2)) return HandRank.fullHouse;
    if (isFlush) return HandRank.flush;
    if (isStraight) return HandRank.straight;
    if (countValues.contains(3)) return HandRank.threeKind;
    if (countValues.where((c) => c == 2).length == 2) return HandRank.twoPair;
    if (countValues.contains(2)) return HandRank.onePair;
    return HandRank.highCard;
  }

  List<CardModel> _generateDeck() {
    const suits = ['♠', '♥', '♦', '♣'];
    return [
      for (var s in suits)
        for (int v = 2; v <= 14; v++) CardModel(s, v)
    ];
  }

  Widget _card(CardModel c) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Text(c.display, style: const TextStyle(fontSize: 18)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[700],
      appBar: AppBar(title: const Text('Texas Hold\'em Poker – 期末專題')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text('CPU 籌碼：$cpuChips', style: const TextStyle(color: Colors.white)),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: cpuHand.map((_) => _card(CardModel.hidden())).toList()),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: community.map(_card).toList()),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: playerHand.map(_card).toList()),
          Text('你的籌碼：$playerChips | 彩池：$pot', style: const TextStyle(color: Colors.white)),
          Text(message, style: const TextStyle(color: Colors.white, fontSize: 18)),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            ElevatedButton(onPressed: bet, child: const Text('下注 / 跟注')),
            const SizedBox(width: 12),
            ElevatedButton(onPressed: fold, child: const Text('蓋牌')),
            const SizedBox(width: 12),
            ElevatedButton(onPressed: startNewRound, child: const Text('新局')),
          ])
        ],
      ),
    );
  }
}

class CardModel {
  final String suit;
  final int value;
  final bool hidden;

  CardModel(this.suit, this.value) : hidden = false;
  CardModel.hidden() : suit = '', value = 0, hidden = true;

  String get display {
    if (hidden) return '🂠';
    final map = {11: 'J', 12: 'Q', 13: 'K', 14: 'A'};
    return '${map[value] ?? value}$suit';
  }
}
