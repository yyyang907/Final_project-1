import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

// 遊戲狀態枚舉
enum GameState { running, playerBust, playerWin, dealerWin, tie, playerStand }

// 卡牌模型
class CardModel {
  final String suit;
  final String rank;
  final int value;
  final bool isFaceDown; // 新增：卡牌是否覆蓋

  CardModel(this.suit, this.rank, this.value, {this.isFaceDown = false});

  // 為了方便，增加一個用於創建覆蓋牌的工廠建構函數
  factory CardModel.faceDown() {
    return CardModel("?", "?", 0, isFaceDown: true);
  }

  // 根據花色返回顏色
  Color get color {
    return (suit == "♥" || suit == "♦") ? Colors.red : Colors.black;
  }
}

// 21點遊戲核心邏輯
class BlackjackGame {
  List<CardModel> deck = [];
  List<CardModel> playerCards = [];
  List<CardModel> dealerCards = [];
  GameState gameState = GameState.running;
  String resultMessage = '';

  BlackjackGame() {
    startGame();
  }

  // 建立並洗牌
  void _buildDeck() {
    List<String> suits = ["♠", "♥", "♦", "♣"];
    List<String> ranks = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"];
    deck = [];

    for (var s in suits) {
      for (var r in ranks) {
        int value = 0;
        if (r == "A") {
          value = 11;
        } else if (["J", "Q", "K"].contains(r)) {
          value = 10;
        } else {
          value = int.parse(r);
        }
        deck.add(CardModel(s, r, value));
      }
    }
    deck.shuffle();
  }

  // 計算點數
  int calculatePoints(List<CardModel> cards) {
    int sum = cards.fold(0, (total, card) => total + card.value);
    int aceCount = cards.where((c) => c.rank == "A").length;

    while (sum > 21 && aceCount > 0) {
      sum -= 10; // A 從 11 變 1
      aceCount--;
    }
    return sum;
  }

  // 開始新遊戲
  void startGame() {
    _buildDeck();
    playerCards = [_deckDraw(), _deckDraw()];
    // 莊家第一張牌是明牌，第二張是蓋牌
    dealerCards = [_deckDraw(), CardModel.faceDown()];
    gameState = GameState.running;
    resultMessage = '';
  }

  // 從牌堆抽一張牌
  CardModel _deckDraw() {
    return deck.removeLast();
  }

  // 玩家要牌
  void playerHit() {
    if (gameState != GameState.running) return;
    playerCards.add(_deckDraw());
    if (calculatePoints(playerCards) > 21) {
      gameState = GameState.playerBust;
      resultMessage = "玩家爆牌！你輸了";
    }
  }

  // 玩家停牌
  void playerStand() {
    if (gameState != GameState.running) return;

    // 翻開莊家的蓋牌
    dealerCards[1] = _deckDraw();

    // 莊家補牌直到 17 點或以上
    while (calculatePoints(dealerCards) < 17) {
      dealerCards.add(_deckDraw());
    }

    _determineWinner();
  }

  // 判斷勝負
  void _determineWinner() {
    int playerPoints = calculatePoints(playerCards);
    int dealerPoints = calculatePoints(dealerCards);

    if (dealerPoints > 21 || playerPoints > dealerPoints) {
      gameState = GameState.playerWin;
      resultMessage = "你贏了！";
    } else if (dealerPoints > playerPoints) {
      gameState = GameState.dealerWin;
      resultMessage = "莊家贏了！";
    } else {
      gameState = GameState.tie;
      resultMessage = "平手！";
    }
  }
}

void main() => runApp(const BlackjackApp());

class BlackjackApp extends StatelessWidget {
  const BlackjackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blackjack',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // 使用 Google Fonts 來美化字體
        textTheme: GoogleFonts.latoTextTheme(),
      ),
      home: const BlackjackPage(),
    );
  }
}

class BlackjackPage extends StatefulWidget {
  const BlackjackPage({super.key});

  @override
  _BlackjackPageState createState() => _BlackjackPageState();
}

class _BlackjackPageState extends State<BlackjackPage> {
  late BlackjackGame game;

  @override
  void initState() {
    super.initState();
    game = BlackjackGame();
  }

  void _startGame() {
    setState(() {
      game.startGame();
    });
  }

  void _playerHit() {
    setState(() {
      game.playerHit();
    });
  }

  void _playerStand() {
    setState(() {
      game.playerStand();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B5E20), // 深綠色背景
      appBar: AppBar(
        title: Text(
          "21 點 Blackjack",
          style: GoogleFonts.bebasNeue(fontSize: 28, letterSpacing: 2),
        ),
        backgroundColor: Colors.black54,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildHandArea("莊家", game.dealerCards),
            _buildResultText(),
            _buildHandArea("玩家", game.playerCards),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  // 建立手牌區域 (莊家或玩家)
  Widget _buildHandArea(String title, List<CardModel> cards) {
    // 遊戲結束時才顯示莊家真實點數
    bool showDealerPoints = title == "莊家" && game.gameState != GameState.running;
    int points = showDealerPoints ? game.calculatePoints(cards) : game.calculatePoints(cards.where((c) => !c.isFaceDown).toList());

    return Column(
      children: [
        Text(
          "$title ($points)",
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: cards.map(_buildCard).toList(),
        ),
      ],
    );
  }

  // 建立結果文字
  Widget _buildResultText() {
    return Text(
      game.resultMessage,
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: game.gameState == GameState.playerWin ? Colors.yellowAccent : Colors.white,
      ),
    );
  }

  // 建立操作按鈕
  Widget _buildActionButtons() {
    bool isGameRunning = game.gameState == GameState.running;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: isGameRunning ? _playerHit : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text("要牌 (Hit)", style: TextStyle(fontSize: 18)),
        ),
        const SizedBox(width: 20),
        ElevatedButton(
          onPressed: isGameRunning ? _playerStand : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text("停牌 (Stand)", style: TextStyle(fontSize: 18)),
        ),
        const SizedBox(width: 20),
        ElevatedButton(
          onPressed: _startGame,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueGrey,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text("新局", style: TextStyle(fontSize: 18)),
        ),
      ],
    );
  }

  // 建立卡牌 Widget
  Widget _buildCard(CardModel card) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      width: 80,
      height: 110,
      decoration: BoxDecoration(
        color: card.isFaceDown ? Colors.blueGrey : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black54, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2)),
        ],
      ),
      child: card.isFaceDown
          ? _buildCardBack()
          : _buildCardFace(card),
    );
  }

  // 卡牌正面
  Widget _buildCardFace(CardModel card) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Text(
              "${card.rank}${card.suit}",
              style: TextStyle(fontSize: 16, color: card.color, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Text(
          card.suit,
          style: TextStyle(fontSize: 36, color: card.color),
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: RotatedBox(
              quarterTurns: 2,
              child: Text(
                "${card.rank}${card.suit}",
                style: TextStyle(fontSize: 16, color: card.color, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 卡牌背面
  Widget _buildCardBack() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF3D5AFE),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white, width: 4),
        gradient: const LinearGradient(
            colors: [Color(0xFF3D5AFE), Color(0xFF0D47A1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
      ),
    );
  }
}