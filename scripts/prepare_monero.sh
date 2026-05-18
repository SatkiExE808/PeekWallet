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

# Skip work if all three target ABIs are already in place. (Cake doesn't
# build i686 / x86 32-bit — no modern Android phones need it.)
if [[ -f "${JNI_BASE}/arm64-v8a/libmonero_wallet2_api_c.so" \
   && -f "${JNI_BASE}/armeabi-v7a/libmonero_wallet2_api_c.so" \
   && -f "${JNI_BASE}/x86_64/libmonero_wallet2_api_c.so" ]]; then
  echo "[prepare_monero] ABI libraries already present — skipping."
  exit 0
fi

if [[ ! -f "${CACHE_DIR}/release-bundle.zip" ]]; then
  echo "[prepare_monero] Downloading ${VERSION} (~211 MB) ..."
  curl -L --fail --progress-bar -o "${CACHE_DIR}/release-bundle.zip" "$BUNDLE_URL"
fi

echo "[prepare_monero] Inspecting bundle layout ..."
unzip -l "${CACHE_DIR}/release-bundle.zip" \
  | grep -E "libmonero_wallet2_api_c\.so" \
  | head -10 || true

# Bundle layout (verified against Cake's build_monero_all.sh):
#   release/<tag>/<target>-linux-android(eabi)/libmonero_wallet2_api_c.so
# The Cake script uses these exact target triples:
#   x86_64-linux-android, aarch64-linux-android, armv7a-linux-androideabi
declare -A ARCH_MAP=(
  ["aarch64-linux-android"]="arm64-v8a"
  ["x86_64-linux-android"]="x86_64"
  ["armv7a-linux-androideabi"]="armeabi-v7a"
)

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

for src_target in "${!ARCH_MAP[@]}"; do
  abi="${ARCH_MAP[$src_target]}"
  dst_dir="${JNI_BASE}/${abi}"
  mkdir -p "$dst_dir"

  unzip -j -o -q "${CACHE_DIR}/release-bundle.zip" \
    "*/${src_target}/libmonero_wallet2_api_c.so" \
    -d "$WORK" || true

  if [[ -f "${WORK}/libmonero_wallet2_api_c.so" ]]; then
    mv "${WORK}/libmonero_wallet2_api_c.so" "${dst_dir}/libmonero_wallet2_api_c.so"
    size=$(stat -c%s "${dst_dir}/libmonero_wallet2_api_c.so" 2>/dev/null \
      || stat -f%z "${dst_dir}/libmonero_wallet2_api_c.so")
    echo "[prepare_monero] Installed ${abi}/libmonero_wallet2_api_c.so (${size} bytes)"
  else
    echo "[prepare_monero] WARNING: ${src_target} -> ${abi} not found in bundle."
    echo "[prepare_monero] Inspect bundle: unzip -l ${CACHE_DIR}/release-bundle.zip | grep libmonero"
    exit 1
  fi
done

echo "[prepare_monero] Done."
