const express = require('express');
const cors = require('cors');
const app = express();
app.use(cors());
app.use(express.json());

let userChips = 1000;
let userDebt = 0;
const DEBT_LIMIT = 10000; // 債務清算門檻

// 獲取狀態 (新增 isGameOver 判定)
app.get('/api/user/balance', (req, res) => {
    res.json({ 
        chips: userChips, 
        debt: userDebt, 
        isGameOver: userDebt >= DEBT_LIMIT 
    });
});

// 借錢接口 (新增上限檢查)
app.post('/api/user/borrow', (req, res) => {
    const { amount } = req.body;
    if (userDebt + amount > DEBT_LIMIT) {
        return res.status(400).json({ error: "信用額度已達上限" });
    }
    userDebt += amount;
    userChips += amount;
    res.json({ chips: userChips, debt: userDebt });
});

// 還錢接口
app.post('/api/user/repay', (req, res) => {
    const { amount } = req.body;
    // 確保還款額不超過現有資金，也不超過欠債
    const actualRepay = Math.min(amount, userChips, userDebt);
    userChips -= actualRepay;
    userDebt -= actualRepay;
    res.json({ chips: userChips, debt: userDebt });
});

// 核心遊戲結算 (修復贏錢邏輯與利息)
app.post('/api/game/action', (req, res) => {
    const { betAmount, isWin, winMultiplier } = req.body;

    // 1. 基礎檢查
    if (userDebt >= DEBT_LIMIT) return res.status(403).json({ error: "已被清算", isGameOver: true });
    if (userChips < betAmount) return res.status(400).json({ error: "餘額不足" });

    // 2. 扣除下注
    userChips -= betAmount;

    // 3. 結算派彩
    // 若 winMultiplier 為 2，表示拿回本金並多賺一倍
    if (isWin) {
        userChips += Math.floor(betAmount * winMultiplier);
    }

    // 4. 計算高利貸利息 (只要有欠債，每動一次就加 5%~10%)
    if (userDebt > 0) {
        const rate = (Math.floor(Math.random() * 6) + 5) / 100; // 0.05 ~ 0.10
        userDebt = Math.round(userDebt * (1 + rate));
    }

    // 5. 回傳最新狀態
    res.json({ 
        chips: userChips, 
        debt: userDebt, 
        isGameOver: userDebt >= DEBT_LIMIT,
        if(isGameOver = true){
            return res.status(403).json({ error: "已被清算", isGameOver: true });         
        }
    });
});

app.listen(3000, () => {
    console.log('玉祥娛樂城 Server 運行中');
    console.log('地址: http://localhost:3000');
    console.log('清算門檻: $' + DEBT_LIMIT);
});