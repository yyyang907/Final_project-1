import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const CasinoApp());
}

class CasinoApp extends StatelessWidget {
  const CasinoApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '玉祥娛樂城 Pro',
      theme: ThemeData(brightness: Brightness.dark, primarySwatch: Colors.amber, textTheme: GoogleFonts.latoTextTheme()),
      home: const MainMenuPage(),
    );
  }
}

// --- 全域數據：共享籌碼 ---
class UserData {
  static int chips = 1000;
}

// --- 主選單 ---
class MainMenuPage extends StatefulWidget {
  const MainMenuPage({super.key});
  @override
  State<MainMenuPage> createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black, Colors.red.shade900], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("玉祥娛樂城", style: GoogleFonts.bebasNeue(fontSize: 60, color: Colors.amber, letterSpacing: 4)),
              Text("帳戶餘額: \$ ${UserData.chips}", style: const TextStyle(fontSize: 18, color: Colors.white)),
              const SizedBox(height: 50),
              _buildMenuButton(context, "🎰 老虎機 ", const SlotMachinePage()),
              const SizedBox(height: 20),
              _buildMenuButton(context, "🃏 決勝 21 點 ", const BlackjackPage()),
              const SizedBox(height: 20),
              _buildMenuButton(context, "♠️ 德州撲克 Pro", const PokerHome()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, String title, Widget targetPage) {
    return SizedBox(width: 280, height: 60, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700, foregroundColor: Colors.white), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => targetPage)).then((_) => setState(() {})), child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))));
  }
}

// =========================================================
// GAME 1：老虎機 (Slot Machine) - 整合籌碼與動畫
// =========================================================
class SlotMachinePage extends StatefulWidget {
  const SlotMachinePage({super.key});
  @override
  State<SlotMachinePage> createState() => _SlotMachinePageState();
}

class _SlotMachinePageState extends State<SlotMachinePage> {
  List<String> symbols = ["🍒", "🔔", "7️⃣", "🍋", "⭐", "🍇"];
  List<int> values = [0, 0, 0];
  bool rolling = false;

  void spin() async {
    if (UserData.chips < 50) return;
    setState(() { rolling = true; UserData.chips -= 50; });

    // 模擬滾動過程
    for (int i = 0; i < 10; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      setState(() { values = [Random().nextInt(6), Random().nextInt(6), Random().nextInt(6)]; });
    }

    setState(() {
      rolling = false;
      if (values[0] == values[1] && values[1] == values[2]) {
        UserData.chips += 500;
        _showResult("中獎！獲得 \$ 500");
      }
    });
  }

  void _showResult(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.orange));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("老虎機 (餘額: ${UserData.chips})")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: values.map((v) => Container(width: 80, height: 100, margin: const EdgeInsets.all(5), decoration: BoxDecoration(color: Colors.black, border: Border.all(color: Colors.amber, width: 2), borderRadius: BorderRadius.circular(10)), child: Center(child: Text(symbols[v], style: const TextStyle(fontSize: 50))))).toList()),
            const SizedBox(height: 50),
            ElevatedButton(onPressed: rolling ? null : spin, style: ElevatedButton.styleFrom(minimumSize: const Size(200, 60), backgroundColor: Colors.amber, foregroundColor: Colors.black), child: Text(rolling ? "滾動中..." : "啟動 (50)", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }
}

// =========================================================
// GAME 2：決勝 21 點 (Blackjack) - 完整邏輯
// =========================================================
class BlackjackPage extends StatefulWidget {
  const BlackjackPage({super.key});
  @override
  State<BlackjackPage> createState() => _BlackjackPageState();
}

class _BlackjackPageState extends State<BlackjackPage> {
  List<int> playerHand = [], dealerHand = [];
  bool gameOver = false;
  String message = "請開始遊戲";

  void startGame() {
    if (UserData.chips < 100) return;
    setState(() {
      UserData.chips -= 100;
      playerHand = [Random().nextInt(10) + 1, Random().nextInt(10) + 1];
      dealerHand = [Random().nextInt(10) + 1];
      gameOver = false;
      message = "要牌或停牌？";
    });
  }

  int calcScore(List<int> hand) => hand.fold(0, (sum, card) => sum + card);

  void hit() {
    setState(() {
      playerHand.add(Random().nextInt(10) + 1);
      if (calcScore(playerHand) > 21) {
        message = "爆牌！你輸了";
        gameOver = true;
      }
    });
  }

  void stand() {
    while (calcScore(dealerHand) < 17) {
      dealerHand.add(Random().nextInt(10) + 1);
    }
    int p = calcScore(playerHand), d = calcScore(dealerHand);
    setState(() {
      gameOver = true;
      if (d > 21 || p > d) {
        message = "你贏了！獲得 200";
        UserData.chips += 200;
      } else if (p == d) {
        message = "平手！退回 100";
        UserData.chips += 100;
      } else {
        message = "莊家贏了";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("21點 (餘額: ${UserData.chips})")),
      backgroundColor: const Color(0xFF1B5E20),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text("莊家: ${calcScore(dealerHand)}", style: const TextStyle(fontSize: 20)),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: dealerHand.map((c) => _cardUI(c)).toList()),
          Text(message, style: const TextStyle(fontSize: 24, color: Colors.amber, fontWeight: FontWeight.bold)),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: playerHand.map((c) => _cardUI(c)).toList()),
          Text("你的點數: ${calcScore(playerHand)}", style: const TextStyle(fontSize: 20)),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (!gameStarted) ElevatedButton(onPressed: startGame, child: const Text("下注 100 開始")),
            if (gameStarted && !gameOver) ...[
              ElevatedButton(onPressed: hit, child: const Text("要牌 ")),
              const SizedBox(width: 10),
              ElevatedButton(onPressed: stand, child: const Text("停牌 ")),
            ],
            if (gameOver) ElevatedButton(onPressed: startGame, child: const Text("再玩一局")),
          ])
        ],
      ),
    );
  }
  bool get gameStarted => playerHand.isNotEmpty;
  Widget _cardUI(int val) => Container(width: 50, height: 75, margin: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: Center(child: Text(val.toString(), style: const TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold))));
}

// =========================================================
// 核心遊戲：德州撲克 Pro (含 All-in 自動開牌與清晰卡片)
// =========================================================
enum PokerStage { preFlop, flop, turn, river, showdown }

class PokerCard {
  final String suit;
  final int value;
  PokerCard(this.suit, this.value);

  // 取得顯示字串 (A, K, Q, J 或數字)
  String get rankStr => value <= 10 ? value.toString() : {11: 'J', 12: 'Q', 13: 'K', 14: 'A'}[value]!;
  // 取得顏色
  Color get color => (suit == '♥' || suit == '♦') ? Colors.red : Colors.black;
}

class PokerHome extends StatefulWidget {
  const PokerHome({super.key});
  @override
  State<PokerHome> createState() => _PokerHomeState();
}

class _PokerHomeState extends State<PokerHome> {
  List<PokerCard> deck = [], playerHand = [], cpuHand = [], community = [];
  PokerStage stage = PokerStage.preFlop;
  int pot = 0, currentBet = 10;
  bool apiLoading = false;
  String gameMessage = "新局開始，請下注";

  @override
  void initState() {
    super.initState();
    _newRound();
  }

  void _newRound() {
    setState(() {
      // 初始化牌組
      deck = [for (var s in ['♠', '♥', '♦', '♣']) for (int v = 2; v <= 14; v++) PokerCard(s, v)]..shuffle();
      playerHand = [deck.removeLast(), deck.removeLast()];
      cpuHand = [deck.removeLast(), deck.removeLast()];
      community = [];
      stage = PokerStage.preFlop;
      pot = 0;
      currentBet = min(10, UserData.chips);
      gameMessage = "請下注開始新局";
    });
  }

  // --- 核心邏輯：確認下注 ---
  void _confirmAction() async {
    if (UserData.chips < currentBet) return;

    setState(() => apiLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      UserData.chips -= currentBet;
      pot += (currentBet * 2);
      apiLoading = false;
    });

    // 關鍵修正：如果籌碼歸零，啟動 All-in 自動開牌模式
    if (UserData.chips == 0) {
      await _autoRunToFinish();
    } else {
      _advanceStage();
    }
  }

  // 自動跑完所有剩下的公共牌
  Future<void> _autoRunToFinish() async {
    while (stage != PokerStage.river) {
      await Future.delayed(const Duration(milliseconds: 700));
      setState(() {
        _drawCommunityCards();
        stage = PokerStage.values[stage.index + 1];
        gameMessage = "All-in! 自動開牌中...";
      });
    }
    await Future.delayed(const Duration(milliseconds: 700));
    setState(() {
      stage = PokerStage.showdown;
      _settleGame();
    });
  }

  // 正常手動推進階段
  void _advanceStage() {
    setState(() {
      _drawCommunityCards();
      if (stage == PokerStage.river) {
        stage = PokerStage.showdown;
        _settleGame();
      } else {
        stage = PokerStage.values[stage.index + 1];
        gameMessage = "電腦已跟注";
      }
    });
  }

  // 根據階段抽牌
  void _drawCommunityCards() {
    if (stage == PokerStage.preFlop) {
      community.addAll([deck.removeLast(), deck.removeLast(), deck.removeLast()]);
    } else if (stage == PokerStage.flop || stage == PokerStage.turn) {
      community.add(deck.removeLast());
    }
  }

  // 簡易結算邏輯 (可擴充牌型算法)
  void _settleGame() {
    int pScore = playerHand[0].value + playerHand[1].value;
    int cScore = cpuHand[0].value + cpuHand[1].value;
    bool playerWins = pScore >= cScore;
    setState(() {
      if (playerWins) UserData.chips += pot;
      gameMessage = playerWins ? "🎉 你贏了！獲得 \$ $pot" : "💀 電腦贏了！";
      pot = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    double sMax = max(1.0, UserData.chips.toDouble());
    return Scaffold(
      appBar: AppBar(
          title: const Text("德州撲克 Pro"),
          actions: [Center(child: Text("餘額: ${UserData.chips}  ", style: const TextStyle(fontSize: 16)))]
      ),
      backgroundColor: const Color(0xFF0F5132), // 經典綠色牌桌
      body: Column(
        children: [
          _buildPlayerArea("電腦 (AI)", cpuHand, isHidden: stage != PokerStage.showdown),
          const Spacer(),
          _buildCommunityArea(),
          const Spacer(),
          Text(gameMessage,
              style: const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 2, color: Colors.black)])),
          _buildPlayerArea("玩家手牌", playerHand),
          _buildBetPanel(sMax),
        ],
      ),
    );
  }

  // 公共牌區域
  Widget _buildCommunityArea() {
    return Column(
      children: [
        Text("底池: \$ $pot", style: const TextStyle(fontSize: 24, color: Colors.yellow, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: community.isEmpty
              ? [const Text("等待下注...", style: TextStyle(color: Colors.white54))]
              : community.map((c) => _cardUI(c)).toList(),
        ),
      ],
    );
  }

  // 下注控制面板
  Widget _buildBetPanel(double sMax) {
    if (stage == PokerStage.showdown) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: ElevatedButton(
          onPressed: _newRound,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 55),
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
          ),
          child: const Text("下一局", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 30),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 10)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("加注金額: \$ $currentBet",
              style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _potBtn("1/4", (pot/4).round(), sMax),
              _potBtn("1/2", (pot/2).round(), sMax),
              _potBtn("All-in", sMax.toInt(), sMax),
            ],
          ),
          Slider(
            value: currentBet.toDouble().clamp(0.0, sMax),
            min: 0.0,
            max: sMax,
            divisions: sMax > 0 ? sMax.toInt() : 1,
            activeColor: Colors.amber,
            onChanged: apiLoading ? null : (v) => setState(() => currentBet = v.toInt()),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: OutlinedButton(
                      onPressed: apiLoading ? null : () => setState(() => stage = PokerStage.showdown),
                      child: const Text("棄牌 (Fold)")
                  )
              ),
              const SizedBox(width: 15),
              Expanded(
                  child: ElevatedButton(
                      onPressed: (apiLoading || UserData.chips < currentBet || UserData.chips == 0 && pot == 0)
                          ? null : _confirmAction,
                      child: const Text("確認下注 (Call)", style: TextStyle(fontWeight: FontWeight.bold))
                  )
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _potBtn(String label, int target, double sMax) {
    return ActionChip(
        label: Text(label),
        onPressed: apiLoading ? null : () => setState(() => currentBet = target.clamp(0, sMax.toInt()))
    );
  }

  Widget _buildPlayerArea(String label, List<PokerCard> cards, {bool isHidden = false}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 5),
        Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: cards.map((c) => _cardUI(c, isHidden: isHidden)).toList()
        ),
      ],
    );
  }

  // --- 重點：優化後的卡片顯示 UI ---
  Widget _cardUI(PokerCard c, {bool isHidden = false}) {
    return Container(
      width: 55,
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: isHidden ? Colors.blue[900] : Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [const BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(2, 2))],
      ),
      child: isHidden
          ? const Center(child: Icon(Icons.help_outline, color: Colors.white, size: 30))
          : Stack(
        children: [
          // 左上角：數字與花色
          Positioned(
            top: 3,
            left: 4,
            child: Column(
              children: [
                Text(c.rankStr,
                    style: TextStyle(color: c.color, fontSize: 16, fontWeight: FontWeight.bold, height: 1.0)),
                Text(c.suit,
                    style: TextStyle(color: c.color, fontSize: 14)),
              ],
            ),
          ),
          // 中央：大花色水印效果
          Center(
            child: Opacity(
              opacity: 0.15,
              child: Text(c.suit, style: TextStyle(color: c.color, fontSize: 40)),
            ),
          ),
          // 右下角：倒轉數字 (增加質感)
          Positioned(
            bottom: 3,
            right: 4,
            child: RotatedBox(
              quarterTurns: 2,
              child: Text(c.rankStr,
                  style: TextStyle(color: c.color, fontSize: 14, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}

//https://github.com/yyyang907/Final_project-1