# ElkRP3 Database Directory

Mounted inside the container at `/database` (`C:\ProgramData\RP\`) to persist your ElkRP accounts and settings across container rebuilds.

- **Fresh setup:** Leave this folder as-is—default RP database files (`ElkAccts2.mdb`, `Ops2.mdb`, `Controls2.mdb`, `SOps2.mdw`) are seeded automatically on first container start.
- **Migrating from Windows *(optional)*:** Close ElkRP on Windows, open `%ProgramData%\RP`, and copy **`ElkAccts2.mdb`** (plus **`Ops2.mdb`** if you customized operator logins) into this folder before starting the container.
- All database (`.mdb`, `.mdw`, `.ldb`, `.bak`) and log files in this folder are ignored by Git (`.gitignore`).
