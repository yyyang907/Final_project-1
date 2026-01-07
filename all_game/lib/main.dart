import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const CasinoApp());

// =========================================================
// 1. 數據與 API 服務 (同步資金與債務)
// =========================================================

class UserData {
  static int chips = 1000;
  static int debt = 0;
  static bool isGameOver = false;
}

class ApiService {
  // [修改] 將端口從 3000 改為 8000 以匹配 FastAPI 設定
  // Android 模擬器使用 10.0.2.2，iOS 模擬器請使用 http://localhost:8000/api
  static const String baseUrl = "https://finalproject.zeabur.app/api";

  static Future<void> refresh(BuildContext context) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/user/balance'));
      if (res.statusCode == 200) {
        var data = jsonDecode(res.body);
        UserData.chips = data['chips'];
        UserData.debt = data['debt'];
        UserData.isGameOver = data['isGameOver'] ?? (UserData.debt >= 10000);
        if (UserData.isGameOver) _triggerGameOver(context);
      }
    } catch (e) { print("Refresh Error: $e"); }
  }

  static Future<Map<String, dynamic>?> playGameAction(BuildContext context, int bet, bool isWin, {double multiplier = 2.0}) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/game/action'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "betAmount": bet,
          "isWin": isWin,
          "winMultiplier": multiplier,
        }),
      );
      if (res.statusCode == 200) {
        var data = jsonDecode(res.body);
        UserData.chips = data['chips'];
        UserData.debt = data['debt'];
        if (data['isGameOver'] == true) _triggerGameOver(context);
        return data;
      }
    } catch (e) { print("API Action Error: $e"); }
    return null;
  }

  static void _triggerGameOver(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: const Text("💀 債務強制清算", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text("你的債務已達門檻 (\$10,000)，地下錢莊已沒收你所有的財產..."),
        actions: [
          ElevatedButton(
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text("重新做人")
          )
        ],
      ),
    );
  }
}

// =========================================================
// 2. 主選單
// =========================================================
class CasinoApp extends StatelessWidget {
  const CasinoApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '玉祥娛樂城 Pro',
      theme: ThemeData(brightness: Brightness.dark, primarySwatch: Colors.amber),
      home: const MainMenuPage(),
    );
  }
}

class MainMenuPage extends StatefulWidget {
  const MainMenuPage({super.key});
  @override
  State<MainMenuPage> createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage> {
  @override
  void initState() { super.initState(); _update(); }
  void _update() async => await ApiService.refresh(context).then((_) => setState(() {}));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black, Colors.red.shade900], begin: Alignment.topCenter)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("玉祥娛樂城", style: GoogleFonts.bebasNeue(fontSize: 70, color: Colors.amber)),
            Text("現金: \$ ${UserData.chips} | 債務: \$ ${UserData.debt}", style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 50),
            _menuBtn("🎰 老虎機 (50)", const SlotMachinePage()),
            _menuBtn("🃏 21 點 (100)", const BlackjackPage()),
            _menuBtn("♠️ 德州撲克 Pro", const PokerHome()),
            const SizedBox(height: 20),
            SizedBox(
                width: 250,
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () => _showBank(),
                    child: const Text("🏦 地下錢莊")
                )
            ),
          ],
        ),
      ),
    );
  }

  void _showBank() {
    showDialog(context: context, builder: (c) => AlertDialog(
      title: const Text("玉祥錢莊"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text("當前債務: \$ ${UserData.debt}"),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: ElevatedButton(onPressed: () async {
            await http.post(Uri.parse('${ApiService.baseUrl}/user/borrow'), headers: {"Content-Type": "application/json"}, body: jsonEncode({"amount": 1000}));
            _update(); Navigator.pop(context);
          }, child: const Text("借 1000"))),
          const SizedBox(width: 5),
          Expanded(child: ElevatedButton(onPressed: () async {
            await http.post(Uri.parse('${ApiService.baseUrl}/user/repay'), headers: {"Content-Type": "application/json"}, body: jsonEncode({"amount": UserData.chips}));
            _update(); Navigator.pop(context);
          }, child: const Text("還款"))),
        ])
      ]),
    ));
  }

  Widget _menuBtn(String t, Widget p) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: SizedBox(width: 250, height: 55, child: ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => p)).then((_) => _update()), child: Text(t))),
  );
}


// =========================================================
// 老虎機 (Slot Machine) - UI 修復版
// =========================================================
class SlotMachinePage extends StatefulWidget {
  const SlotMachinePage({super.key});

  @override
  State<SlotMachinePage> createState() => _SlotMachinePageState();
}

class _SlotMachinePageState extends State<SlotMachinePage> {
  final List<String> icons = ["🍒", "🔔", "7️⃣", "🍋", "⭐", "🍇"];
  List<int> values = [0, 0, 0];
  bool rolling = false;

  /// 🎰 拉霸邏輯（完全沿用你原本）
  void _spin() async {
    if (rolling || UserData.chips < 50) return;

    setState(() => rolling = true);

    for (int i = 0; i < 12; i++) {
      await Future.delayed(const Duration(milliseconds: 90));
      setState(() {
        values = [
          Random().nextInt(icons.length),
          Random().nextInt(icons.length),
          Random().nextInt(icons.length),
        ];
      });
    }

    bool win = values[0] == values[1] && values[1] == values[2];

    await ApiService.playGameAction(
      context,
      50,
      win,
      multiplier: 20.0,
    );

    setState(() => rolling = false);
  }

  /// 💡 跑馬燈
  Widget _buildLightRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        9,
            (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.orangeAccent,
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.8),
                blurRadius: 6,
              )
            ],
          ),
        ),
      ),
    );
  }

  /// 🎲 單一轉輪
  Widget _buildReel(int value) {
    return Container(
      width: 80,
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Colors.yellowAccent,
            blurRadius: 8,
          )
        ],
      ),
      child: Center(
        child: Text(
          icons[value],
          style: const TextStyle(fontSize: 50),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade900,
      appBar: AppBar(
        backgroundColor: Colors.amber.shade700,
        title: Text("🎰 老虎機｜餘額：${UserData.chips}"),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            /// 🟨 機台本體
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFFD54F),
                    Color(0xFFFFA000),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 16,
                    offset: Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                children: [

                  /// 🔆 上燈
                  _buildLightRow(),
                  const SizedBox(height: 10),

                  /// 🎲 轉輪區
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildReel(values[0]),
                        _buildReel(values[1]),
                        _buildReel(values[2]),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),
                  /// 🔆 下燈
                  _buildLightRow(),
                ],
              ),
            ),

            const SizedBox(height: 40),

            /// 🔴 啟動按鈕（賭場風）
            GestureDetector(
              onTap: rolling ? null : _spin,
              child: Container(
                width: 220,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  gradient: LinearGradient(
                    colors: rolling
                        ? [Colors.grey, Colors.grey.shade700]
                        : [Colors.redAccent, Colors.red.shade900],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 10,
                      offset: Offset(0, 6),
                    )
                  ],
                ),
                child: Center(
                  child: Text(
                    rolling ? "轉動中..." : "拉桿啟動\n(50)",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================
// 21 點 (Blackjack) - 修正 UI
// =========================================================
class BlackjackPage extends StatefulWidget {
  const BlackjackPage({super.key});
  @override
  State<BlackjackPage> createState() => _BlackjackPageState();
}

class _BlackjackPageState extends State<BlackjackPage> {
  List<int> pHand = [], dHand = [];
  bool active = false;

  void _start() async {
    if (UserData.chips < 100) return;
    await ApiService.playGameAction(context, 100, false, multiplier: 0.0);
    setState(() {
      pHand = [Random().nextInt(10) + 1, Random().nextInt(10) + 1];
      dHand = [Random().nextInt(10) + 1];
      active = true;
    });
  }

  void _hit() {
    setState(() {
      pHand.add(Random().nextInt(10) + 1);
      if (pHand.fold(0, (a, b) => a + b) > 21) _stand();
    });
  }

  void _stand() async {
    while (dHand.fold(0, (a, b) => a + b) < 17) dHand.add(Random().nextInt(10) + 1);
    int ps = pHand.fold(0, (a, b) => a + b), ds = dHand.fold(0, (a, b) => a + b);
    bool win = (ps <= 21 && (ds > 21 || ps > ds));
    await ApiService.playGameAction(context, 0, win, multiplier: (ps == ds) ? 1.0 : 2.0);
    setState(() => active = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("21點 - 餘額: \$ ${UserData.chips}")),
      backgroundColor: const Color(0xFF1B5E20),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildH("莊家點數: ${dHand.fold(0, (s, c) => s + c)}", dHand),
          active
              ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            ElevatedButton(onPressed: _hit, child: const Text("要牌")),
            const SizedBox(width: 20),
            ElevatedButton(onPressed: _stand, child: const Text("停牌"))
          ])
              : ElevatedButton(onPressed: _start, child: const Text("下注 100 開始")),
          _buildH("玩家點數: ${pHand.fold(0, (s, c) => s + c)}", pHand),
        ],
      ),
    );
  }
  Widget _buildH(String t, List<int> h) => Column(children: [
    Text(t, style: const TextStyle(fontSize: 18)),
    const SizedBox(height: 10),
    Row(mainAxisAlignment: MainAxisAlignment.center, children: h.map((c) => Container(width: 55, height: 80, margin: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: Center(child: Text(c.toString(), style: const TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold))))).toList())
  ]);
}

// =========================================================
// 德州撲克 (Poker Pro) - 包含 14:A 邏輯與 Slider / All-in
// =========================================================
enum PStage { pre, flop, turn, river, show }

class PokerCard {
  final String suit; final int value;
  PokerCard(this.suit, this.value);
  String get rankStr => value <= 10 ? value.toString() : {11:'J', 12:'Q', 13:'K', 14:'A'}[value]!;
  Color get color => (suit == '♥' || suit == '♦') ? Colors.red : Colors.black;
}

class PokerHome extends StatefulWidget {
  const PokerHome({super.key});
  @override
  State<PokerHome> createState() => _PokerHomeState();
}

class _PokerHomeState extends State<PokerHome> {
  List<PokerCard> deck = [], pHand = [], dHand = [], board = [];
  PStage stage = PStage.pre;
  int pot = 0, betVal = 50;
  bool isPlaying = false;

  // [新增] 紀錄玩家這局總共投入多少錢
  int myTotalBet = 0;

  void _newGame() async {
    if (UserData.chips < betVal) return;

    // [修改] 這裡不呼叫 API，改為本地扣款與紀錄
    // await ApiService.playGameAction(context, betVal, false, multiplier: 0.0);

    setState(() {
      deck = [for (var s in ['♠','♥','♦','♣']) for (int v=2; v<=14; v++) PokerCard(s, v)]..shuffle();
      pHand = [deck.removeLast(), deck.removeLast()];
      dHand = [deck.removeLast(), deck.removeLast()];
      board = [];
      stage = PStage.pre;

      // 初始化底池與玩家投入
      myTotalBet = betVal;
      UserData.chips -= betVal; // 本地先扣除顯示金額
      pot = betVal * 2;

      isPlaying = true;
    });
  }

  void _next() async {
    if (stage == PStage.show) return;

    // [修改] 跟注時，只在本地更新狀態，不呼叫 API
    if (UserData.chips >= betVal && stage != PStage.river) {
      // await ApiService.playGameAction(context, betVal, false, multiplier: 0.0);
      setState(() {
        UserData.chips -= betVal; // 本地扣除
        myTotalBet += betVal;     // 累計投入
        pot += betVal * 2;
      });
    }

    setState(() {
      if (stage == PStage.pre) board.addAll([deck.removeLast(), deck.removeLast(), deck.removeLast()]);
      else if (stage == PStage.flop || stage == PStage.turn) board.add(deck.removeLast());
      else if (stage == PStage.river) _settle(); // 如果是最後一輪，進入結算

      if (stage != PStage.show && stage != PStage.river) {
        // 注意：如果是 river 觸發 _settle，這裡不應該再切換 stage，讓 _settle 去處理
        stage = PStage.values[stage.index + 1];
      }
    });
  }

  void _allIn() async {
    int all = UserData.chips;

    // [修改] All-in 本地處理
    // await ApiService.playGameAction(context, all, false, multiplier: 0.0);

    setState(() {
      UserData.chips = 0; // 全部扣光
      myTotalBet += all;  // 累計投入
      pot += (all * 2);
    });

    while (board.length < 5) board.add(deck.removeLast());
    _settle();
  }

  void _settle() async {
    int p = pHand[0].value + pHand[1].value;
    int d = dHand[0].value + dHand[1].value;
    bool win = p >= d; // 簡單的比大小邏輯

    // [重要修正]
    // 只有在這裡才真正呼叫後端 API。
    // 傳入 myTotalBet (你這局總共下的注)。
    // 後端邏輯：餘額(伺服器上是滿的) - myTotalBet + (贏 ? myTotalBet * 2 : 0)
    // 這樣才會得到正確的結果。

    try {
      await ApiService.playGameAction(
          context,
          myTotalBet, // 傳入累計下注額，而不是 0
          win,
          multiplier: win ? 2.0 : 0.0
      );
    } catch (e) {
      // 處理錯誤，例如把本地扣除的錢加回去
      print("結算失敗: $e");
    }

    setState(() {
      stage = PStage.show;
      isPlaying = false;
      myTotalBet = 0; // 重置
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("德州撲克 - 餘額: \$ ${UserData.chips}")),
      backgroundColor: const Color(0xFF0F5132),
      body: Column(
        children: [
          const SizedBox(height: 20),
          _buildPlayerArea("電腦 (AI)", dHand, hide: stage != PStage.show),
          const Spacer(),
          Text("底池: \$ $pot", style: const TextStyle(fontSize: 26, color: Colors.yellow, fontWeight: FontWeight.bold)),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: board.isEmpty ? [const Text("等待開局...")] : board.map((c) => _cardUI(c)).toList()),
          const Spacer(),
          _buildPlayerArea("玩家手牌", pHand),
          _buildBetPanel(),
        ],
      ),
    );
  }

  Widget _buildBetPanel() {
    if (stage == PStage.show) return Padding(padding: const EdgeInsets.all(20), child: ElevatedButton(onPressed: _newGame, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)), child: const Text("再玩一局")));
    if (!isPlaying) return Padding(padding: const EdgeInsets.all(20), child: ElevatedButton(onPressed: _newGame, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)), child: const Text("下注開局")));

    return Container(
      padding: const EdgeInsets.all(15),
      color: Colors.black87,
      child: Column(children: [
        Text("當前加注: \$ $betVal", style: const TextStyle(color: Colors.amber, fontSize: 18)),
        Slider(
            value: betVal.toDouble().clamp(10.0, max(10.0, UserData.chips.toDouble())),
            min: 10, max: max(10, UserData.chips.toDouble()),
            divisions: max(1, UserData.chips ~/ 10),
            onChanged: (v) => setState(() => betVal = v.toInt())
        ),
        Row(children: [
          Expanded(child: ElevatedButton(onPressed: _next, child: Text(stage == PStage.river ? "開牌" : "跟注"))),
          const SizedBox(width: 10),
          Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: _allIn, child: const Text("All-in (梭哈)"))),
        ])
      ]),
    );
  }

  Widget _buildPlayerArea(String t, List<PokerCard> h, {bool hide = false}) => Column(children: [
    Text(t),
    Row(mainAxisAlignment: MainAxisAlignment.center, children: h.map((c) => _cardUI(c, isHidden: hide)).toList())
  ]);

  Widget _cardUI(PokerCard c, {bool isHidden = false}) => Container(
    width: 50, height: 75, margin: const EdgeInsets.all(3),
    decoration: BoxDecoration(color: isHidden ? Colors.blue[900] : Colors.white, borderRadius: BorderRadius.circular(5)),
    child: isHidden ? const Icon(Icons.help_outline) : Center(child: Text("${c.suit}${c.rankStr}", style: TextStyle(color: c.color, fontWeight: FontWeight.bold, fontSize: 18))),
  );
}
