from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import math
import random

app = FastAPI()

# 設定 CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 允許所有來源，生產環境建議設為具體網域
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 全域變數 (模擬資料庫狀態)
user_chips = 1000
user_debt = 0
DEBT_LIMIT = 10000  # 債務清算門檻

# 定義請求模型
class AmountRequest(BaseModel):
    amount: int

class GameActionRequest(BaseModel):
    betAmount: int
    isWin: bool
    winMultiplier: float

# 獲取狀態
@app.get("/api/user/balance")
async def get_balance():
    return {
        "chips": user_chips,
        "debt": user_debt,
        "isGameOver": user_debt >= DEBT_LIMIT
    }

# 借錢接口
@app.post("/api/user/borrow")
async def borrow_money(req: AmountRequest):
    global user_debt, user_chips
    
    if user_debt + req.amount > DEBT_LIMIT:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, 
            detail={"error": "信用額度已達上限"}
        )
    
    user_debt += req.amount
    user_chips += req.amount
    return {"chips": user_chips, "debt": user_debt}

# 還錢接口
@app.post("/api/user/repay")
async def repay_money(req: AmountRequest):
    global user_debt, user_chips
    
    # 確保還款額不超過現有資金，也不超過欠債
    actual_repay = min(req.amount, user_chips, user_debt)
    
    user_chips -= actual_repay
    user_debt -= actual_repay
    return {"chips": user_chips, "debt": user_debt}

# 核心遊戲結算
@app.post("/api/game/action")
async def game_action(req: GameActionRequest):
    global user_debt, user_chips
    
    # 1. 基礎檢查
    if user_debt >= DEBT_LIMIT:
        return {
            "error": "已被清算",
            "isGameOver": True
        }
        # 注意：FastAPI 若要返回非 200 狀態碼通常使用 raise HTTPException，
        # 但為了匹配原程式邏輯結構，這裡若僅是返回 JSON 訊息可直接 return。
        # 若需要強制 403 狀態碼：
        # raise HTTPException(status_code=403, detail={"error": "已被清算", "isGameOver": True})

    if user_chips < req.betAmount:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"error": "餘額不足"}
        )

    # 2. 扣除下注
    user_chips -= req.betAmount

    # 3. 結算派彩
    if req.isWin:
        # math.floor 向下取整
        user_chips += math.floor(req.betAmount * req.winMultiplier)

    # 4. 計算高利貸利息 (只要有欠債，每動一次就加 5%~10%)
    if user_debt > 0:
        # random.uniform(0.05, 0.10) 或使用原邏輯
        # 原邏輯: (Math.floor(Math.random() * 6) + 5) / 100 => 5,6,7,8,9,10 / 100
        rate = random.randint(5, 10) / 100
        user_debt = round(user_debt * (1 + rate))

    is_game_over = user_debt >= DEBT_LIMIT

    # 5. 回傳最新狀態
    # 修正了原程式碼中在 JSON 物件內寫 if 語句的語法錯誤
    if is_game_over:
        # 這裡模擬原程式意圖：如果結算後爆了，返回特定錯誤或狀態
        # 原程式碼的寫法其實是在 res.json() 內部嘗試做邏輯判斷，這是無效的 JS。
        # 這裡修正為：如果爆了，回傳狀態並附帶 403 (或僅回傳標記)
        pass 
        
    return {
        "chips": user_chips,
        "debt": user_debt,
        "isGameOver": is_game_over
    }

if __name__ == "__main__":
    import uvicorn
    print('玉祥娛樂城 Server 運行中')
    print('地址: http://localhost:8000')
    print(f'清算門檻: ${DEBT_LIMIT}')
    uvicorn.run(app, host="0.0.0.0", port=8000)