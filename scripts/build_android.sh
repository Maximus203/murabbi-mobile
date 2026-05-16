#!/usr/bin/env bash
# ============================================================
# build_android.sh — Build APK via WSL (Java 17 Linux) + install
#
# Usage depuis PowerShell/CMD :
#   wsl -d Ubuntu -- bash scripts/build_android.sh [--release] [--install]
#
# Usage depuis WSL :
#   bash scripts/build_android.sh [--release] [--install]
#
# Prérequis (déjà configurés) :
#   - Flutter Linux  : /home/sysadmin/flutter (v3.41.9)
#   - Java 17        : dans WSL Ubuntu (openjdk 17)
#   - Android SDK    : /mnt/c/Android/Sdk (partagé Windows)
#   - ADB            : /mnt/c/Android/Sdk/platform-tools/adb.exe
# ============================================================

set -euo pipefail

# ── Chemins ────────────────────────────────────────────────────
FLUTTER="/home/sysadmin/flutter/bin/flutter"
ANDROID_SDK="/mnt/c/Android/Sdk"
ADB="/mnt/c/Android/Sdk/platform-tools/adb.exe"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="/mnt/c/Users/Cherif DIOUF/Documents/Projets/Perso/murabbi/murabbi-admin-repo/.env.cloud.local"

# ── Options ────────────────────────────────────────────────────
BUILD_MODE="debug"
DO_INSTALL=false

for arg in "$@"; do
  case "$arg" in
    --release) BUILD_MODE="release" ;;
    --install) DO_INSTALL=true ;;
  esac
done

# ── Variables Supabase ──────────────────────────────────────────
if [[ -z "${SUPABASE_URL:-}" || -z "${SUPABASE_ANON_KEY:-}" ]]; then
  if [[ -f "$ENV_FILE" ]]; then
    echo "[build] Chargement des clés Supabase depuis .env.cloud.local"
    SUPABASE_URL=$(grep 'NEXT_PUBLIC_SUPABASE_URL' "$ENV_FILE" | cut -d'=' -f2 | tr -d '\r')
    SUPABASE_ANON_KEY=$(grep 'NEXT_PUBLIC_SUPABASE_ANON_KEY' "$ENV_FILE" | cut -d'=' -f2 | tr -d '\r')
  else
    echo "[build] WARN : clés Supabase non trouvées — mode design (sans backend)"
    SUPABASE_URL=""
    SUPABASE_ANON_KEY=""
  fi
fi

# ── Environnement ──────────────────────────────────────────────
export ANDROID_HOME="$ANDROID_SDK"
export ANDROID_SDK_ROOT="$ANDROID_SDK"
export PATH="$ANDROID_SDK/platform-tools:$ANDROID_SDK/cmdline-tools/latest/bin:$PATH"

echo "==========================================="
echo " Murabbi — Build Android via WSL"
echo "==========================================="
echo " Flutter  : $($FLUTTER --version 2>&1 | head -1)"
echo " Java     : $(java -version 2>&1 | head -1)"
echo " Mode     : $BUILD_MODE"
echo " Device   : $("$ADB" devices 2>/dev/null | grep 'device$' | awk '{print $1}' | head -1 || echo 'aucun')"
echo " Supabase : ${SUPABASE_URL:-'(non configuré)'}"
echo "==========================================="
echo ""

cd "$PROJECT_DIR"

# ── pub get ────────────────────────────────────────────────────
echo "[1/4] flutter pub get..."
"$FLUTTER" pub get --suppress-analytics

# ── flutter analyze ────────────────────────────────────────────
echo "[2/4] flutter analyze..."
"$FLUTTER" analyze --no-fatal-infos --suppress-analytics
echo "      ✓ 0 issues"

# ── Build APK ──────────────────────────────────────────────────
echo "[3/4] flutter build apk --$BUILD_MODE ..."

DART_DEFINES=()
[[ -n "${SUPABASE_URL:-}" ]] && DART_DEFINES+=(--dart-define="SUPABASE_URL=$SUPABASE_URL")
[[ -n "${SUPABASE_ANON_KEY:-}" ]] && DART_DEFINES+=(--dart-define="SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY")

"$FLUTTER" build apk "--$BUILD_MODE" --suppress-analytics "${DART_DEFINES[@]}"

APK_PATH="$PROJECT_DIR/build/app/outputs/flutter-apk/app-${BUILD_MODE}.apk"
APK_SIZE=$(du -sh "$APK_PATH" | cut -f1)
echo ""
echo "      ✓ APK : $APK_PATH ($APK_SIZE)"

# ── Install + Lancer ───────────────────────────────────────────
# WSL2 : les devices USB ne sont pas visibles directement.
# On utilise adb.exe Windows via cmd.exe pour l'installation.
WIN_APK_PATH=$(wslpath -w "$APK_PATH" 2>/dev/null || echo "$APK_PATH")

if $DO_INSTALL; then
  echo "[4/4] Installation via ADB Windows (USB hors WSL2)..."
  # Tente ADB natif WSL d'abord (cas usbipd-win configuré)
  if "$ADB" devices 2>/dev/null | grep -q "device$"; then
    "$ADB" install -r "$APK_PATH"
    "$ADB" shell monkey -p com.murabbi.murabbi_mobile -c android.intent.category.LAUNCHER 1 2>/dev/null || true
    echo "      ✓ App installée et lancée (ADB WSL)"
  else
    # Fallback : ADB Windows (path direct sans cmd.exe pour éviter les espaces)
    ADB_WIN="/mnt/c/Android/Sdk/platform-tools/adb.exe"
    # Désinstall si conflit de signature (ancienne release vs debug)
    INSTALLED=$("$ADB_WIN" shell pm list packages 2>/dev/null | grep "com.murabbi.murabbi" || true)
    if [[ -n "$INSTALLED" ]]; then
      echo "      Désinstallation ancienne version (conflit signature)..."
      "$ADB_WIN" shell pm uninstall --user 0 com.murabbi.murabbi 2>/dev/null || true
    fi
    "$ADB_WIN" install "$APK_PATH" 2>&1
    "$ADB_WIN" shell monkey -p com.murabbi.murabbi -c android.intent.category.LAUNCHER 1 2>/dev/null || true
    echo "      ✓ App installée et lancée (ADB Windows)"
  fi
else
  echo "[4/4] APK prêt — pour installer sur le Pixel :"
  echo ""
  echo "  Option A — PowerShell/CMD Windows :"
  echo "  adb install -r \"$WIN_APK_PATH\""
  echo ""
  echo "  Option B — Relance avec --install :"
  echo "  wsl -d Ubuntu -- bash scripts/build_android.sh --install"
fi

echo ""
echo "✅ Build terminé."
