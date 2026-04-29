# ChipGameX 維運檢查清單（Raspberry Pi / Docker Compose）

## 0) 基本資訊
- 主機：`jccafe01`
- 專案路徑：`~/chipgamex`
- 服務：`db`(TimescaleDB), `api`(FastAPI), `web`(Vite)
- 備份路徑：`/home/jc/backups/chipgamex`

---

## 1) 每日巡檢（1~3 分鐘）

### 1.1 容器狀態
```bash
cd ~/chipgamex
docker compose ps
```
**預期**：`db/api/web` 皆為 `Up`，且健康狀態正常。

### 1.2 API 健康檢查
```bash
curl -s http://localhost:8000/api/v1/health
```
**預期**：`{"status":"ok"}`

### 1.3 最近備份檔
```bash
ls -lh /home/jc/backups/chipgamex | tail
```
**預期**：每日有新 `.dump.gz` 檔案。

### 1.4 備份 log
```bash
tail -n 50 /home/jc/backups/chipgamex/backup.log
```
**預期**：有 `[INFO] backup -> ...` 與 `[INFO] done`，無中斷錯誤。

---

## 2) 例行維護（每週/每月）

### 2.1 更新服務（先拉新版再重建）
```bash
cd ~/chipgamex
docker compose pull
docker compose up -d
docker compose ps
```

### 2.2 檢查 DB 日誌（錯誤關鍵字）
```bash
cd ~/chipgamex
docker compose logs --tail=200 db
```
若要快速找錯：
```bash
docker compose logs --tail=500 db | grep -Ei "error|fatal|panic"
```

### 2.3 密碼輪替（建議每月或每季）
```bash
cd ~/chipgamex
./rotate_db_password.sh
```
完成後：
- 立即存入密碼管理器
- 確認 API health 正常

---

## 3) 備份與還原 SOP

### 3.1 手動備份
```bash
/home/jc/chipgamex/backup_db.sh
```

### 3.2 還原到正式庫（高風險，需確認）
```bash
/home/jc/chipgamex/restore_db.sh /home/jc/backups/chipgamex/<file>.dump.gz
```
> 會覆蓋現有物件，僅在明確需要時使用。

### 3.3 還原後驗證
```bash
curl -s http://localhost:8000/api/v1/health
docker compose ps
```

---

## 4) 排程（cron）基準

### 4.1 正確設定（每天 03:30）
```cron
30 3 * * * /home/jc/chipgamex/backup_db.sh >> /home/jc/backups/chipgamex/backup.log 2>&1
```

### 4.2 檢查目前 crontab
```bash
crontab -l
```
**注意**：避免重複條目（同一行只保留 1 條）。

---

## 5) 常見故障快排

### 5.1 指令打成 `logs ...` 導致找不到
請使用完整指令：
```bash
docker compose logs --tail=120 db
```

### 5.2 TimescaleDB extension 版本錯誤
若出現：
`could not access file "$libdir/timescaledb-..."`

處置：
1. 確認 `docker-compose.yml` DB image 與資料目錄版本一致  
2. 建議使用：
```yaml
image: timescale/timescaledb:latest-pg15
```
3. 重建 DB 容器後再看 logs。

### 5.3 backup.log 不存在
若 cron 尚未到時間，log 檔尚未建立屬正常。可手動觸發：
```bash
/home/jc/chipgamex/backup_db.sh >> /home/jc/backups/chipgamex/backup.log 2>&1
```

---

## 6) 安全建議（最小必要）
- `.env` 權限限縮（避免其他使用者讀取）：
```bash
chmod 600 ~/chipgamex/.env
```
- 備份目錄限縮：
```bash
chmod 700 /home/jc/backups/chipgamex
```
- 避免在聊天/工單貼出明文密碼。
- 每次密碼輪替後，確認所有相依服務都已重載。

---

## 7) 重大操作前檢查（變更前 30 秒）
1. 先做一次備份
2. 確認 `docker compose ps` 全綠
3. 記錄目前時間與操作內容（方便回溯）
4. 準備回復指令（rollback）

---

## 8) 目前環境已完成項目（可勾選）
- [x] DB / API / WEB 健康運行
- [x] DB 密碼輪替腳本可用
- [x] 備份腳本可用（`.dump.gz`）
- [x] 還原腳本可用（實測成功）
- [x] cron 每日備份已配置
