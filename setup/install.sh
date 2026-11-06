#!/usr/bin/env bash
# Workspace setup for the Neon Glitch repo: Debian 12 (bookworm) container, run as root (or a sudo user).
# Idempotent: a re-run skips what is already installed. Log: /var/log/workspace-setup.log
# Godot stays pinned (GODOT_VER). Blender is not installed here: it stays on the owner's Windows PC.
set -euo pipefail

: "${HOME:=/root}"
GODOT_VER="${GODOT_VER:-4.7.2}"
ANDROID_API="${ANDROID_API:-35}"
BUILD_TOOLS="${BUILD_TOOLS:-35.0.0}"
CMDLINE_ZIP="${CMDLINE_ZIP:-commandlinetools-linux-11076708_latest.zip}"
ANDROID_SDK=/opt/android-sdk
LOG_FILE=/var/log/workspace-setup.log
GODOT_DIR=/opt/godot
GODOT_BIN="$GODOT_DIR/Godot_v${GODOT_VER}-stable_linux.x86_64"
GODOT_BASE="https://github.com/godotengine/godot/releases/download/${GODOT_VER}-stable"
TPL_DIR="$HOME/.local/share/godot/export_templates/${GODOT_VER}.stable"
SDKMANAGER="$ANDROID_SDK/cmdline-tools/latest/bin/sdkmanager"

if [ "$(id -u)" -eq 0 ]; then SUDO=""; else SUDO="sudo"; fi

# Everything (stdout and stderr) goes to the log file and to the terminal.
$SUDO touch "$LOG_FILE"
$SUDO chown "$(id -u):$(id -g)" "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

export DEBIAN_FRONTEND=noninteractive
export ANDROID_HOME="$ANDROID_SDK"
export PATH="$HOME/.local/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

step() { echo; echo "== $1/9 $2"; }
apt_get() { $SUDO env DEBIAN_FRONTEND=noninteractive apt-get "$@"; }

echo "install.sh start $(date -u '+%Y-%m-%d %H:%M:%S') UTC, user $(id -un), Godot $GODOT_VER"

# 1. apt packages (Debian 12 names)
step 1 "apt packages"
apt_get -qq update
apt_get install -y -qq --no-install-recommends \
  ca-certificates curl wget git jq unzip zip xz-utils bash coreutils gnupg \
  python3 python3-pip python3-venv python-is-python3 \
  build-essential pkg-config fontconfig fonts-dejavu \
  libgl1 libxi6 libxrandr2 libxcursor1 libxinerama1 libasound2 libpulse0 libglu1-mesa mesa-utils \
  xvfb xauth ffmpeg openjdk-17-jdk-headless

# 2. GitHub CLI from the official cli.github.com apt repo
step 2 "GitHub CLI (gh)"
if command -v gh >/dev/null 2>&1; then
  echo "gh already installed"
else
  $SUDO install -d -m 755 /etc/apt/keyrings
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg -o "$TMP/githubcli-archive-keyring.gpg"
  $SUDO install -m 644 "$TMP/githubcli-archive-keyring.gpg" /etc/apt/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | $SUDO tee /etc/apt/sources.list.d/github-cli.list >/dev/null
  apt_get -qq update
  apt_get install -y -qq --no-install-recommends gh
fi

# 3. Node.js LTS from NodeSource (includes npm)
step 3 "Node.js LTS"
if command -v node >/dev/null 2>&1; then
  echo "node already installed: $(node --version)"
else
  curl -fsSL https://deb.nodesource.com/setup_lts.x -o "$TMP/nodesource_setup.sh"
  $SUDO bash "$TMP/nodesource_setup.sh"
  apt_get install -y -qq --no-install-recommends nodejs
fi

# 4. Godot (pinned) and its export templates
step 4 "Godot $GODOT_VER + export templates"
if [ ! -x "$GODOT_BIN" ]; then
  curl -fL --retry 3 -o "$TMP/godot.zip" "$GODOT_BASE/Godot_v${GODOT_VER}-stable_linux.x86_64.zip"
  $SUDO mkdir -p "$GODOT_DIR"
  $SUDO unzip -o -q "$TMP/godot.zip" -d "$GODOT_DIR"
  [ -f "$GODOT_BIN" ] || { echo "Godot binary not found in the zip: $GODOT_BIN"; exit 1; }
  $SUDO chmod +x "$GODOT_BIN"
fi
$SUDO ln -sf "$GODOT_BIN" /usr/local/bin/godot
if [ ! -f "$TPL_DIR/version.txt" ]; then
  curl -fL --retry 3 -o "$TMP/export_templates.tpz" "$GODOT_BASE/Godot_v${GODOT_VER}-stable_export_templates.tpz"
  unzip -o -q "$TMP/export_templates.tpz" -d "$TMP/tpz"
  rm -f "$TMP/export_templates.tpz"
  mkdir -p "$TPL_DIR"
  cp -r "$TMP/tpz/templates/." "$TPL_DIR/"
  rm -rf "$TMP/tpz"
fi

# 5. Android SDK (command-line tools, platform-tools, platform and build-tools) and the debug keystore
step 5 "Android SDK"
if [ ! -x "$SDKMANAGER" ]; then
  curl -fL --retry 3 -o "$TMP/$CMDLINE_ZIP" "https://dl.google.com/android/repository/$CMDLINE_ZIP"
  unzip -o -q "$TMP/$CMDLINE_ZIP" -d "$TMP/cmdline"
  $SUDO mkdir -p "$ANDROID_SDK/cmdline-tools"
  $SUDO rm -rf "$ANDROID_SDK/cmdline-tools/latest"
  $SUDO mv "$TMP/cmdline/cmdline-tools" "$ANDROID_SDK/cmdline-tools/latest"
  $SUDO chmod -R +x "$ANDROID_SDK/cmdline-tools/latest/bin"
fi
# Accept the Android SDK licences only. `yes` ends by SIGPIPE, so the pipeline may fail: hence `|| true`.
yes | "$SDKMANAGER" --sdk_root="$ANDROID_SDK" --licenses >/dev/null || true
"$SDKMANAGER" --sdk_root="$ANDROID_SDK" "platform-tools" "platforms;android-${ANDROID_API}" "build-tools;${BUILD_TOOLS}"
mkdir -p "$HOME/.android"
if [ ! -f "$HOME/.android/debug.keystore" ]; then
  keytool -genkeypair -v -keystore "$HOME/.android/debug.keystore" \
    -storepass android -keypass android -alias androiddebugkey \
    -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US"
fi

# 6. Claude Code and opencode
step 6 "Claude Code and opencode"
if command -v claude >/dev/null 2>&1; then
  echo "claude already installed"
else
  curl -fsSL https://claude.ai/install.sh -o "$TMP/claude-install.sh"
  bash "$TMP/claude-install.sh"
fi
if command -v opencode >/dev/null 2>&1; then
  echo "opencode already installed"
else
  $SUDO npm install -g opencode-ai
fi

# 7. Playwright + Chromium (Debian 12 needs --break-system-packages for pip)
step 7 "Playwright + Chromium"
python -m pip install --break-system-packages -q playwright
python -m playwright install --with-deps chromium

# 8. Shell environment for later interactive shells (added once)
step 8 "shell environment (~/.bashrc, once)"
BASHRC="$HOME/.bashrc"
if ! grep -qF "# >>> game workspace setup >>>" "$BASHRC" 2>/dev/null; then
  cat >>"$BASHRC" <<'BASHRC_BLOCK'
# >>> game workspace setup >>>
export ANDROID_HOME=/opt/android-sdk
export PATH="$HOME/.local/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
# <<< game workspace setup <<<
BASHRC_BLOCK
  echo "added the workspace block to $BASHRC"
else
  echo "$BASHRC already has the workspace block"
fi

# 9. VERIFY: every tool must be found; exit 1 if any is MISSING
step 9 "VERIFY"
MISSING=0
for name in git gh python node npm godot java ffmpeg claude opencode; do
  if command -v "$name" >/dev/null 2>&1; then
    echo "$name OK"
  else
    echo "$name MISSING"
    MISSING=1
  fi
done
if godot --headless --version >"$TMP/godot_version.txt" 2>&1; then
  echo "godot --headless --version: $(head -n 1 "$TMP/godot_version.txt")"
else
  echo "godot --headless --version FAILED"
  MISSING=1
fi
if adb version >"$TMP/adb_version.txt" 2>&1; then
  echo "adb version: $(head -n 1 "$TMP/adb_version.txt")"
else
  echo "adb MISSING"
  MISSING=1
fi
if [ "$MISSING" -ne 0 ]; then
  echo "VERIFY FAILED: fix the MISSING lines above and rerun"
  exit 1
fi
echo "DONE. Next: setup/LOGINS.md"
