#!/usr/bin/env bash
#
# Fetches the prebuilt libmonero_wallet2_api_c.so for each Android ABI
# from MrCyjaneK's monero_c releases and places them where Flutter's
# Android build will bundle them (android/app/src/main/jniLibs/<abi>/).
#
# Runs in CI; also runnable locally if you want to do a real release
# build on your Mac. Safe to re-run — skips the download if the cache
# is already there.
#
# Version is pinned (matches the ref in pubspec.yaml's monero git dep
# so the Dart bindings and the native code line up). Bump both when
# moving to a newer release.

set -euo pipefail

VERSION="v0.18.4.6-RC1"
BUNDLE_URL="https://github.com/MrCyjaneK/monero_c/releases/download/${VERSION}/release-bundle.zip"

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CACHE_DIR="${PROJECT_ROOT}/.cache/monero_c"
JNI_BASE="${PROJECT_ROOT}/android/app/src/main/jniLibs"

mkdir -p "$CACHE_DIR" "$JNI_BASE"

# Skip work if all four ABIs are already in place.
if [[ -f "${JNI_BASE}/arm64-v8a/libmonero_wallet2_api_c.so" \
   && -f "${JNI_BASE}/armeabi-v7a/libmonero_wallet2_api_c.so" \
   && -f "${JNI_BASE}/x86_64/libmonero_wallet2_api_c.so" \
   && -f "${JNI_BASE}/x86/libmonero_wallet2_api_c.so" ]]; then
  echo "[prepare_monero] All four ABI libraries already present — skipping."
  exit 0
fi

if [[ ! -f "${CACHE_DIR}/release-bundle.zip" ]]; then
  echo "[prepare_monero] Downloading ${VERSION} (~211 MB) ..."
  curl -L --fail --progress-bar -o "${CACHE_DIR}/release-bundle.zip" "$BUNDLE_URL"
fi

echo "[prepare_monero] Inspecting bundle layout ..."
# List the Monero-Android entries so CI logs make any layout drift obvious.
unzip -l "${CACHE_DIR}/release-bundle.zip" \
  | grep -E "monero/release/.*android.*\.(so)$" \
  | head -20 || true

# MrCyjaneK's bundle places binaries at:
#   release/monero/release/android/<arch>/libmonero_wallet2_api_c.so
# where <arch> is one of: aarch64, arm, i686, x86_64
declare -A ARCH_MAP=(
  ["aarch64"]="arm64-v8a"
  ["arm"]="armeabi-v7a"
  ["x86_64"]="x86_64"
  ["i686"]="x86"
)

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

for src_arch in "${!ARCH_MAP[@]}"; do
  abi="${ARCH_MAP[$src_arch]}"
  dst_dir="${JNI_BASE}/${abi}"
  mkdir -p "$dst_dir"

  # The path inside the zip — we don't know the exact prefix, so
  # extract anything matching and let the loop sort it out.
  unzip -j -o -q "${CACHE_DIR}/release-bundle.zip" \
    "*/monero/release/android/${src_arch}/libmonero_wallet2_api_c.so" \
    -d "$WORK" || true

  if [[ -f "${WORK}/libmonero_wallet2_api_c.so" ]]; then
    mv "${WORK}/libmonero_wallet2_api_c.so" "${dst_dir}/libmonero_wallet2_api_c.so"
    size=$(stat -c%s "${dst_dir}/libmonero_wallet2_api_c.so" 2>/dev/null \
      || stat -f%z "${dst_dir}/libmonero_wallet2_api_c.so")
    echo "[prepare_monero] Installed ${abi}/libmonero_wallet2_api_c.so (${size} bytes)"
  else
    echo "[prepare_monero] WARNING: ${src_arch} -> ${abi} not found in bundle. Bundle layout may have changed."
    echo "[prepare_monero] Run \`unzip -l ${CACHE_DIR}/release-bundle.zip\` and update ARCH_MAP paths."
  fi
done

echo "[prepare_monero] Done."
