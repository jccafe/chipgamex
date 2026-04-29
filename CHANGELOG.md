## 2026-04-29
- Deploy target: `jccafe01` (Raspberry Pi 4), env: `prod`.
- Frontend switched from Vite dev server to Nginx static hosting.
- Resolved port conflict with Apache by setting web mapping to `8080:80`.
- Hardened web image build (multi-stage; auto `npm ci` / `npm install`).
- Added `curl` in web runtime image for healthcheck support.
- Updated web healthcheck to `curl -fsS http://localhost/ >/dev/null || exit 1`.
- Verified services healthy: `api`, `db`, `web`, `uptime-kuma`.
- Finalized Uptime Kuma monitors: API / Web / DB container / Pi host.
- Go-live verification passed ✅
