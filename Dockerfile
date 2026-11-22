# ==============================================================================
# Stage 1: Build 32-bit Wine prefix + .NET 4.8 + Jet 4.0 + ElkRP3
# ==============================================================================
FROM ubuntu:24.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive \
    WINEARCH=win32 \
    WINEPREFIX=/opt/wine32 \
    WINEDEBUG=-all

RUN set -eux; \
    dpkg --add-architecture i386; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        binutils \
        ca-certificates \
        cabextract \
        curl \
        gnupg \
        libfontconfig1:i386 \
        libfreetype6:i386 \
        libgnutls30t64:i386 \
        p7zip-full \
        python3 \
        wget \
        xauth \
        xvfb \
        zenity; \
    install -d -m 0755 /etc/apt/keyrings; \
    curl -fsSL https://dl.winehq.org/wine-builds/winehq.key \
        | gpg --dearmor -o /etc/apt/keyrings/winehq-archive.key; \
    curl -fsSL https://dl.winehq.org/wine-builds/ubuntu/dists/noble/winehq-noble.sources \
        -o /etc/apt/sources.list.d/winehq-noble.sources; \
    apt-get update; \
    apt-get install -y --no-install-recommends winehq-stable; \
    curl -fsSL https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks \
        -o /usr/local/bin/winetricks; \
    chmod 0755 /usr/local/bin/winetricks

COPY installer/ /tmp/installer/

RUN set -eux; \
    installer_exe="$(ls -1v /tmp/installer/ElkRP*.[eE][xX][eE] 2>/dev/null | tail -n 1 || true)"; \
    if [ -z "${installer_exe}" ]; then \
      echo "ERROR: No ElkRP .exe installer found in ./installer/" >&2; \
      exit 1; \
    fi; \
    echo "Installing ElkRP from: ${installer_exe}"; \
    install -d -o 1000 -g 1000 /opt/wine32; \
    INSTALLER_EXE="${installer_exe}" su -s /bin/bash ubuntu -c ' \
      set -eux; \
      export HOME=/home/ubuntu WINEARCH=win32 WINEPREFIX=/opt/wine32 WINEDEBUG=-all; \
      xvfb-run -a bash -euc '\'' \
        WINEDLLOVERRIDES="mscoree,mshtml=" wineboot -u && wineserver -w; \
        winetricks -q corefonts mfc42 jet40 mdac28 dotnet48 && wineserver -w; \
        wine "${INSTALLER_EXE}" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- && wineserver -w; \
        wineserver -k || true \
      '\''; \
      rm -rf /home/ubuntu/.cache \
    '; \
    test -n "$(find "/opt/wine32/drive_c/Program Files" -maxdepth 2 -type f -iname 'ElkRP*.exe' ! -iname 'unins*' -print -quit)"

RUN set -eux; \
    # Separate default RP database templates for runtime seeding and link C:\ProgramData\RP -> /database
    mv /opt/wine32/drive_c/ProgramData/RP /opt/elkrp-db-seed; \
    ln -sfn /database /opt/wine32/drive_c/ProgramData/RP; \
    # Prune 64-bit Wine, installer caches, temp dirs, and ELF debug symbols
    rm -rf \
        /opt/wine-stable/lib/wine/x86_64-windows \
        /opt/wine-stable/bin/wine64* \
        /opt/wine-stable/share/man \
        /opt/wine32/drive_c/windows/Installer \
        /opt/wine32/drive_c/windows/temp/* \
        /opt/wine32/drive_c/windows/Temp/* \
        /opt/wine32/*.log \
        /tmp/installer; \
    find /opt/wine32/drive_c -maxdepth 1 -regextype posix-extended -regex '.*/[0-9a-f]{12,}' -exec rm -rf {} +; \
    strip --strip-unneeded /opt/wine-stable/bin/wine /opt/wine-stable/bin/wineserver /opt/wine-stable/lib/wine/i386-unix/*.so /opt/wine-stable/lib/wine/x86_64-unix/*.so || true; \
    # Deduplicate identical DLLs between /opt/wine-stable and /opt/wine32 via hardlinks (~605 MB saved)
    python3 -c 'import os,hashlib; w={}; [w.setdefault(hashlib.sha256(open(p,"rb").read()).digest(),p) for dp,_,fns in os.walk("/opt/wine-stable/lib/wine/i386-windows") for fn in fns for p in [os.path.join(dp,fn)] if os.path.isfile(p) and not os.path.islink(p) and os.path.getsize(p)>=4096]; [ (os.unlink(p),os.link(w[h],p)) for dp,_,fns in os.walk("/opt/wine32/drive_c") for fn in fns for p in [os.path.join(dp,fn)] if os.path.isfile(p) and not os.path.islink(p) and os.path.getsize(p)>=4096 for h in [hashlib.sha256(open(p,"rb").read()).digest()] if h in w and os.stat(w[h]).st_ino!=os.stat(p).st_ino ]'; \
    chown -h -R 1000:1000 /opt/wine32 /opt/elkrp-db-seed

# ==============================================================================
# Stage 2: Minimal runtime image (no build tools, no 64-bit Wine, no recommends)
# ==============================================================================
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    DISPLAY=:1 \
    HOME=/home/ubuntu \
    PATH="/opt/wine-stable/bin:${PATH}" \
    WINEARCH=win32 \
    WINEPREFIX=/opt/wine32 \
    WINEDEBUG=-all

RUN set -eux; \
    dpkg --add-architecture i386; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        adwaita-icon-theme \
        ca-certificates \
        libc6:i386 \
        libfontconfig1:i386 \
        libfreetype6:i386 \
        libgcc-s1:i386 \
        libgnutls30t64:i386 \
        libgssapi-krb5-2:i386 \
        libkrb5-3:i386 \
        libodbc2:i386 \
        libpng16-16t64:i386 \
        libstdc++6:i386 \
        libx11-6:i386 \
        libxcomposite1:i386 \
        libxcursor1:i386 \
        libxext6:i386 \
        libxfixes3:i386 \
        libxi6:i386 \
        libxinerama1:i386 \
        libxrandr2:i386 \
        libxrender1:i386 \
        novnc \
        openbox \
        python3 \
        tint2 \
        websockify \
        x11vnc \
        xterm \
        xvfb \
        zlib1g:i386; \
    install -d -o 1000 -g 1000 /database /home/ubuntu/.config/openbox /home/ubuntu/.config/tint2; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /usr/share/doc/* /usr/share/man/*

COPY --from=builder /opt /opt
COPY rootfs/ /

USER 1000:1000
WORKDIR /home/ubuntu
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD ["python3", "-c", "import socket,urllib.request; urllib.request.urlopen('http://127.0.0.1:3000/vnc.html',timeout=3); s=socket.socket(socket.AF_UNIX); s.settimeout(3); s.connect('/tmp/vnc.sock'); s.close()"]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
