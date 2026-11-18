#!/usr/bin/env bash
# larp.OS - lanza el build de la ISO dentro de un contenedor Fedora (podman).
# Funciona desde cualquier distro (Arch, Quantum, Ubuntu...). Uso: ./build-iso.sh
set -euo pipefail

RELEASEVER="${RELEASEVER:-44}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v podman >/dev/null 2>&1; then
    echo "[!] Falta podman. En Arch/Quantum: sudo pacman -S podman" >&2
    exit 1
fi

echo "[+] Construyendo larp.OS con Fedora ${RELEASEVER} en contenedor..."
sudo podman run --rm --privileged --network=host \
    -e RELEASEVER="${RELEASEVER}" \
    -e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" \
    -v "${HERE}":/work -w /work \
    "registry.fedoraproject.org/fedora:${RELEASEVER}" \
    bash /work/scripts/build-in-container.sh

echo "[+] ISO lista en: ${HERE}/out/larp-os.iso"
