# ElkRP3 Wine Container

This shows how to setup and run elkrp3 in a limited linux container offering a web interface (vnc) to avoid keeping a Windows machine just for running this program once in a while. Just add the official installer and your existing database file (optional) and you are ready to go.

Minimal multi-stage Ubuntu 24.04 (`noble`) + 32-bit Wine + Openbox/tint2/noVNC container with `.NET 4.8`, `Jet 4.0`, and **ElkRP 3.x** (`ElkRP3.exe`) pre-installed inside the image.

## Directory Layout
- `Dockerfile` & `rootfs/` — Multi-stage build definition and static X11/Openbox/tint2/noVNC overlay.
- `docker-compose.yml` — Service definition mounting `./database` and publishing port `3000/tcp` on `127.0.0.1:3000` (override via `ELKRP3_BIND` or attach to your reverse-proxy network).
- `./database/` *(gitignored)* — Mounted at `/database` (`C:\ProgramData\RP\`): holds `ElkAccts2.mdb`, `Ops2.mdb`, `Controls2.mdb`, and `SOps2.mdw`.
- `./installer/` *(gitignored, build-time only)* — Holds the `ElkRP-Full-install-*.exe` binary used during `docker compose build`.

---

## Initial Setup (Fresh Host)

### 1. Provide the installer (and optional database)
1. **Installer:** Copy your ElkRP full installer (e.g. `ElkRP-Full-install-3.0.11.exe`) into `./installer/`.
2. **Database *(optional, if migrating from Windows)*:** On Windows, close ElkRP, open `%ProgramData%\RP`, and copy **`ElkAccts2.mdb`** (plus **`Ops2.mdb`** if you customized operator logins) into `./database/`. *(If left as-is, default database files are seeded automatically on first start.)*

### 2. Build and start the container
```bash
docker compose up -d --build
```
*(The initial build takes ~5–8 minutes while `.NET 4.8`, `Jet 4.0`, and `ElkRP3` install inside the temporary builder stage.)*

### 3. Open the Web UI
Open `http://localhost:3000` in your browser (or place `elkrp3:3000` behind an HTTPS + WebSockets reverse proxy—note VNC has no password by default, so do not expose port `3000` directly to untrusted networks). **ElkRP3** launches automatically on startup, with **Terminal** (`xterm`) and **ElkRP3** icons on the top `tint2` bar.
