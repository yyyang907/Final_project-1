import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SlotMachinePage(),
    );
  }
}

class SlotMachinePage extends StatefulWidget {
  @override
  State<SlotMachinePage> createState() => _SlotMachinePageState();
}

class _SlotMachinePageState extends State<SlotMachinePage> {
  // Slot Symbol
  List<String> symbols = ["🍒", "🔔", "7️⃣", "🍋", "⭐", "🍇"];
  List<int> slotValues = [0, 0, 0];

  String resultText = "";

  // Lever angle
  double leverAngle = 0;

  // Roll timers
  Timer? timer1;
  Timer? timer2;
  Timer? timer3;

  // Casino weighted win chance
  double winRate = 0.08; // ⭐ 中獎機率 8%0000000
  bool forceWin = false;
  bool forceLose = false;

  // ---------------------------------------------------------
  //                      拉桿 + 動畫流程
  // ---------------------------------------------------------
  void pullLever() async {
    // 拉桿往下
    setState(() => leverAngle = 40);
    await Future.delayed(Duration(milliseconds: 180));
    setState(() => leverAngle = 0);

    // ⭐ 決定是否中獎（賭場核心）
    double rng = (DateTime.now().microsecondsSinceEpoch % 100) / 100;
    forceWin = rng < winRate;
    forceLose = !forceWin;

    // 🎰 開始三輪一起轉動
    startRoll();

    // 依序慢慢停止
    await Future.delayed(Duration(milliseconds: 900));
    timer1?.cancel();
    await Future.delayed(Duration(milliseconds: 500));
    timer2?.cancel();
    await Future.delayed(Duration(milliseconds: 500));
    timer3?.cancel();

    // ⭐ 第三輪決定是否給你中獎（賭場加權）
    finishWeighted();

    // 判定
    checkResult();
  }

  // ---------------------------------------------------------
  //                   三輪獨立轉動（速度不同）
  // ---------------------------------------------------------
  void startRoll() {
    timer1?.cancel();
    timer2?.cancel();
    timer3?.cancel();

    timer1 = Timer.periodic(Duration(milliseconds: 60), (_) {
      setState(() => slotValues[0] = (slotValues[0] + 1) % symbols.length);
    });

    timer2 = Timer.periodic(Duration(milliseconds: 80), (_) {
      setState(() => slotValues[1] = (slotValues[1] + 1) % symbols.length);
    });

    timer3 = Timer.periodic(Duration(milliseconds: 100), (_) {
      setState(() => slotValues[2] = (slotValues[2] + 1) % symbols.length);
    });
  }

  // ---------------------------------------------------------
  //        第三輪依據賭場邏輯 → 強制中或強制不中
  // ---------------------------------------------------------
  void finishWeighted() {
    setState(() {
      if (forceWin) {
        // ⭐ 強制中獎：第三輪與第二輪要一樣
        slotValues[2] = slotValues[1];
      } else {
        // ⭐ 強制不給中獎：找一個不同的符號
        for (int i = 0; i < symbols.length; i++) {
          if (i != slotValues[1]) {
            slotValues[2] = i;
            break;
          }
        }
      }
    });
  }

  // ---------------------------------------------------------
  //                        判定結果
  // ---------------------------------------------------------
  void checkResult() {
    bool win = slotValues[0] == slotValues[1] && slotValues[1] == slotValues[2];

    setState(() {
      resultText = win ? "🎉 JACKPOT!" : "再試一次！";
    });
  }

  // ---------------------------------------------------------
  //                  單格 Slot UI（你原本的風格）
  // ---------------------------------------------------------
  Widget _buildSlotBox(int index) {
    return Container(
      width: 80,
      height: 100,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.7),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        symbols[index],
        style: TextStyle(fontSize: 55, shadows: [
          Shadow(color: Colors.white, blurRadius: 10),
          Shadow(color: Colors.yellow, blurRadius: 20),
        ]),
      ),
    );
  }

  // ---------------------------------------------------------
  //                      主畫面（你原有 UI）
  // ---------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade900,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ----------------------------
            //     SLOT MACHINE FRAME
            // ----------------------------
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber.shade300, Colors.amber.shade700],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.amber.shade200, width: 6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 🔆 上方燈
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      9,
                          (i) => Icon(Icons.circle,
                          color: i % 2 == 0 ? Colors.yellow : Colors.orange,
                          size: 20),
                    ),
                  ),

                  SizedBox(height: 15),

                  // 🔳 內部凹槽 + 玻璃反光
                  Container(
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.9),
                          Colors.black.withOpacity(0.6),
                          Colors.black.withOpacity(0.9),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Stack(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildSlotBox(slotValues[0]),
                            _buildSlotBox(slotValues[1]),
                            _buildSlotBox(slotValues[2]),
                          ],
                        ),

                        // 玻璃反光
                        Positioned(
                          top: 0,
                          left: 0,
                          child: Container(
                            width: 220,
                            height: 100,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.18),
                                  Colors.white.withOpacity(0.05),
                                  Colors.transparent,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 15),

                  // 🔆 下方燈
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      9,
                          (i) => Icon(Icons.circle,
                          color: i % 2 == 0 ? Colors.orange : Colors.yellow,
                          size: 20),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),

            // --------------- 中獎結果（大字） ----------------
            Text(
              resultText,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.yellowAccent,
                shadows: [
                  Shadow(color: Colors.black, blurRadius: 8, offset: Offset(2, 2)),
                  Shadow(color: Colors.redAccent, blurRadius: 10),
                ],
              ),
            ),

            SizedBox(height: 30),

            // ---------------- 拉桿 ----------------
            GestureDetector(
              onTap: pullLever,
              child: AnimatedRotation(
                turns: leverAngle / 360,
                duration: Duration(milliseconds: 180),
                child: Column(
                  children: [
                    Icon(Icons.circle, size: 50, color: Colors.redAccent),
                    Container(width: 10, height: 60, color: Colors.white),
                    Container(
                      width: 30,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
