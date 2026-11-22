# ElkRP3 Installer Directory

Place your official **ElkRP 3.x full installer** executable (for example, `ElkRP-Full-install-3.0.11.exe`) in this folder before running `docker compose up -d --build`.

- Used **only at image build time** (`Dockerfile` Stage 1 installs it silently under Wine and removes the installer afterward).
- All `.exe` files in this folder are ignored by Git (`.gitignore`).
