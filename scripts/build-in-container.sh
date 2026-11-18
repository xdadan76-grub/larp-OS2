#!/usr/bin/env bash
# Corre DENTRO del contenedor Fedora (como root). No lo ejecutes en tu host.
set -euo pipefail

KS="/work/larp-fedora.ks"
FSLABEL="larp-os"
RELEASEVER="${RELEASEVER:-44}"
CACHE_DIR="/var/cache/live"

echo "[+] Instalando herramientas..."
dnf install -y livecd-tools pykickstart

echo "[+] Validando Kickstart..."
ksvalidator "${KS}"

setenforce 0 2>/dev/null || true

mkdir -p /work/out "${CACHE_DIR}"
cd /work/out

echo "[+] livecd-creator (Fedora ${RELEASEVER})..."
livecd-creator --verbose \
    --config="${KS}" \
    --fslabel="${FSLABEL}" \
    --releasever="${RELEASEVER}" \
    --cache="${CACHE_DIR}"

chown -R "${HOST_UID:-0}:${HOST_GID:-0}" /work/out
echo "[+] Listo: /work/out/${FSLABEL}.iso"
