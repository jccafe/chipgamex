# ChipGameX 值班口袋清單（10 行）
1) `cd ~/chipgamex && docker compose ps`（先看 db/api/web 是否 Up/Healthy）  
2) `curl -s http://localhost:8000/api/v1/health`（預期 `{"status":"ok"}`）  
3) `docker compose logs --tail=120 api`（先看 API）  
4) `docker compose logs --tail=120 db`（再看 DB）  
5) `ls -lh /home/jc/backups/chipgamex | tail`（確認最近備份）  
6) 先備份再動刀：`/home/jc/chipgamex/backup_db.sh`  
7) 服務異常先重建：`docker compose up -d --force-recreate api web`  
8) DB 密碼輪替：`cd ~/chipgamex && ./rotate_db_password.sh`（做完立刻存密碼管理器）  
9) 災難還原：`/home/jc/chipgamex/restore_db.sh /home/jc/backups/chipgamex/<file>.dump.gz`（會覆蓋）  
10) 收尾三確認：`docker compose ps`、health ok、`tail -n 50 /home/jc/backups/chipgamex/backup.log`
