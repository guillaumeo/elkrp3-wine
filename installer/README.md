# ElkRP3 Installer Directory

Place your official **ElkRP full installer** executable (any version/filename, e.g. `ElkRP-Full-install-3.0.11.exe` or newer) in this folder before running `docker compose up -d --build`.

- Filename-independent: any `*.exe` / `*.EXE` is detected automatically (if multiple versions are present, the highest version is chosen).
- Used **only at image build time** (`Dockerfile` Stage 1 installs it silently under Wine and removes the installer afterward).
- All `.exe` files in this folder are ignored by Git (`.gitignore`).
