# ChipGameX 上線完成紀錄（Raspberry Pi 4）

- **日期**：2026-04-29 (Asia/Taipei)
- **主機**：`jccafe01`（Raspberry Pi 4）
- **部署方式**：Docker Compose
- **紀錄人**：`jc`

---

## 1) 本次變更摘要

### 前端部署模式調整
- 將前端由 Vite 開發伺服器模式改為 **Nginx 靜態檔服務**。
- `web` 服務對外埠由主機映射為：
  - `8080:80`（避免與主機 Apache `:80` 衝突）。

### Web 映像建置穩健化
- 前端 Dockerfile 採多階段建置（builder/runtime）。
- 依 lockfile 自動選擇：
  - 有 `package-lock.json` → `npm ci`
  - 無 lockfile → `npm install`
- runtime 層安裝 `curl` 供 healthcheck 使用。

### 健康檢查修正
- `web.healthcheck` 改為：
  - `curl -fsS http://localhost/ >/dev/null || exit 1`
- 確認容器由 `starting` 轉為 `healthy`。

---

## 2) 最終服務狀態（驗收）

### Docker Compose 服務
- `api`：Up (healthy)
- `db`：Up (healthy)
- `web`：Up (healthy)
- `uptime-kuma`：Up (healthy)

### Web 日誌驗證（重點）
- Nginx 正常啟動，無致命錯誤。
- 可見 healthcheck 週期性請求：
  - `GET / HTTP/1.1" 200 ... "curl/..."`
- 判定：`web` 健康檢查機制正常。

---

## 3) Uptime Kuma 監控定版

> 監控策略：**內網監控（方案 C）**

### 已建立監控項目（4 項）
1. **chipgamex-api**（HTTP）
   - URL: `http://api:8000/api/v1/health`
2. **chipgamex-web**（HTTP）
   - URL: `http://web/`
3. **chipgamex-db**（Docker Container）
   - Container Name: `chipgamex-db`
4. **Raspberry Pi 主機**（Ping）
   - Host: `host.docker.internal`（或主機 LAN IP）

### 告警參數（統一）
- Interval: `60s`
- Retries: `2`
- Timeout: `10s`

### 備註
- 歷史可用率（SLA）在部署調整當天可能低於 100%，屬正常現象；
  待連續穩定運行後會逐步回升。

---

## 4) 安全與維運現況

- `.env` 權限：`chmod 600 .env`
- 備份目錄權限：`chmod 700 /home/jc/backups/chipgamex`
- 已具備腳本：
  - `deploy.sh`
  - `backup_db.sh`
  - `restore_db.sh`
  - `rotate_db_password.sh`

---

## 5) 當前已知決策

1. 前端正式服務固定使用 **Nginx 靜態站**（不再使用 Vite dev server）。
2. `WEB_PORT=8080` 作為正式對外入口。
3. Uptime Kuma 以容器內 URL 為主（`http://web/`、`http://api:8000/...`）。

---

## 6) 建議後續事項（Next Actions）

1. 將 Uptime Kuma 資料目錄納入每日備份。
2. 執行一次「故障演練」並留存紀錄：
   - 停止 `web` → 告警觸發 → 恢復服務 → 告警清除
3. 清理舊有監控項（避免與 `chipgamex-db` 重複的 DB 監控）。
4. 每週例行檢查：
   - `docker compose ps`
   - `docker compose logs --tail=100 web api`
   - 備份檔是否生成、可否還原。

---

## 7) 驗收指令（留存）

```
docker compose config
docker compose build web
docker compose up -d --no-deps --force-recreate web
docker compose ps
curl -I http://localhost:8080
docker compose logs --tail=80 web
```

---

## 8) 驗收結論

本次上線調整已完成，核心服務（API / Web / DB / 監控）皆正常，  
前端架構已成功由開發模式切換至正式生產模式，系統進入穩定運行階段。

- **Go-Live Result**: ✅ PASS
- **Environment**: `prod`
- **Owner**: `jc`
