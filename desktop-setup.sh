#!/usr/bin/env bash

# ==============================================================================
# IDEMPOTENT & MODULAR TERMUX FULL-ENVIRONMENT PROVISIONING SCRIPT
# Target: Oppo Find N5 (Snapdragon 8 Elite / Adreno 830 GPU)
# Design Principle: Non-destructive, repeatable execution, step-selectable.
# ==============================================================================

set -e # Exit immediately if a command exits with a non-zero status

# Capture script directory location early before any execution side-effects
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd 2>/dev/null || pwd)"

# Initialize Modularity and Force Flags to False
FORCE=false
RUN_REPO_SETUP=false; RUN_REPAIR_PACKAGES=false; RUN_ALLOW_APPS=false
RUN_DESKTOP_ENV=false; RUN_NODE_ENV=false; RUN_INSTALL_APPS=false
RUN_FIREFOX_MCP=false; RUN_HARDEN_FIREFOX=false; RUN_OPENCODE_BIN=false
RUN_OPENCODE_CONFIG=false; RUN_LAUNCH_SCRIPT=false
ANY_FLAG_SPECIFIED=false

# Help Function
show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

If no descriptive step options are provided, the entire pipeline is run sequentially.

Global Options:
  -f, --force         Override all idempotency checks to force re-downloading, 
                      re-installing, and overwriting existing configurations.
  -h, --help          Show this reference guide and document environmental tokens

Available Module Options:
  --repo-setup        Conditional repository setup & Cloudflare CDN alignment
  --repair-packages   Repair open/broken dpkg package transactions
  --allow-apps        Configure external app integration permissions (Termux properties)
  --desktop-env       Install X11 Server, Turnip/Freedreno Vulkan stack, & XFCE4
  --node-env          Deploy Node.js core runtime & global pnpm package engine
  --install-apps      Install core utilities & visual apps (Code-OSS, Firefox, Chromium)
  --firefox-mcp       Install Firefox DevTools MCP server & apply Termux hotfix
  --harden-firefox    Harden Firefox configuration profile & disable Mozilla telemetry
  --opencode-bin      Set up glibc repository & compile native OpenCode AI agent
  --opencode-config   Migrate and substitute credentials in opencode.json & auth.json
  --launch-script     Generate the hardware-accelerated desktop session macro script

Supported Environment Variables:
  OPENCODE_URL          Direct URL override to pull down an explicit OpenCode aarch64.deb binary.
                        If absent, the script crawls the GitHub release channel APIs automatically.
  
  OPENCODE_API_KEY      The access string to substitute inside your OpenCode profile matrix configuration.
  NEURALWATT_API_KEY    The programmatic authorization string mapping directly to the Neuralwatt gateway.
  DEEPSEEK_API_KEY      The core authentication token required to pipeline requests out to DeepSeek.

  Note: If an environment variable is omitted or empty at launch, its corresponding JSON token macro 
        template wrapper (e.g. {env:DEEPSEEK_API_KEY}) is stripped into an empty string inside auth.json.
EOF
}

# Parse Command-Line Arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--force)          FORCE=true; shift ;;
        --repo-setup)        RUN_REPO_SETUP=true;        ANY_FLAG_SPECIFIED=true; shift ;;
        --repair-packages)   RUN_REPAIR_PACKAGES=true;   ANY_FLAG_SPECIFIED=true; shift ;;
        --allow-apps)        RUN_ALLOW_APPS=true;        ANY_FLAG_SPECIFIED=true; shift ;;
        --desktop-env)       RUN_DESKTOP_ENV=true;       ANY_FLAG_SPECIFIED=true; shift ;;
        --node-env)          RUN_NODE_ENV=true;          ANY_FLAG_SPECIFIED=true; shift ;;
        --install-apps)      RUN_INSTALL_APPS=true;      ANY_FLAG_SPECIFIED=true; shift ;;
        --firefox-mcp)       RUN_FIREFOX_MCP=true;       ANY_FLAG_SPECIFIED=true; shift ;;
        --harden-firefox)    RUN_HARDEN_FIREFOX=true;    ANY_FLAG_SPECIFIED=true; shift ;;
        --opencode-bin)      RUN_OPENCODE_BIN=true;      ANY_FLAG_SPECIFIED=true; shift ;;
        --opencode-config)   RUN_OPENCODE_CONFIG=true;   ANY_FLAG_SPECIFIED=true; shift ;;
        --launch-script)     RUN_LAUNCH_SCRIPT=true;     ANY_FLAG_SPECIFIED=true; shift ;;
        -h|--help) show_help; exit 0 ;;
        *)
            echo "❌ Unknown command-line parameter detected: $1"
            show_help
            exit 1
            ;;
    esac
done

# Default Behavior: If no specific flags are passed, execute everything
if [ "$ANY_FLAG_SPECIFIED" = false ]; then
    RUN_REPO_SETUP=true; RUN_REPAIR_PACKAGES=true; RUN_ALLOW_APPS=true
    RUN_DESKTOP_ENV=true; RUN_NODE_ENV=true; RUN_INSTALL_APPS=true
    RUN_FIREFOX_MCP=true; RUN_HARDEN_FIREFOX=true; RUN_OPENCODE_BIN=true
    RUN_OPENCODE_CONFIG=true; RUN_LAUNCH_SCRIPT=true
fi

if [ "$FORCE" = true ]; then
    echo "⚠️  [FORCE MODE ACTIVE] Idempotency safeguards are disabled. Overwriting all targets..."
fi

echo "🚀 Analyzing system state and checking dependency baselines..."

# ------------------------------------------------------------------------------
# MODULE: REPOSITORY CONFIGURATION
# ------------------------------------------------------------------------------
if [ "$RUN_REPO_SETUP" = true ]; then
    NEED_APT_UPDATE=false
    echo "🔍 [MODULE: repo-setup] Checking repository mirror configurations..."
    if [ "$FORCE" = true ] || [ ! -f "$PREFIX/etc/apt/sources.list.d/x11.list" ] || ! grep -q "packages-cf.termux.dev" "$PREFIX/etc/apt/sources.list" 2>/dev/null; then
        echo "📦 Mapping core system package pools directly to global Cloudflare CDN..."
        echo "deb https://packages-cf.termux.dev/apt/termux-main stable main" > $PREFIX/etc/apt/sources.list
        mkdir -p $PREFIX/etc/apt/sources.list.d
        pkg install x11-repo -y
        echo "deb https://packages-cf.termux.dev/apt/termux-x11 x11 main" > $PREFIX/etc/apt/sources.list.d/x11.list
        NEED_APT_UPDATE=true
    else
        echo "✓ Repositories are already mapped to Cloudflare CDN mirrors."
    fi

    if [ "$NEED_APT_UPDATE" = true ] || [ "$FORCE" = true ]; then
        echo "🧹 Purging dirty apt indices and running an aggressive database synchronization..."
        apt-get clean
        apt-get update -y
    fi
fi

# ------------------------------------------------------------------------------
# MODULE: REPAIR PACKAGES
# ------------------------------------------------------------------------------
if [ "$RUN_REPAIR_PACKAGES" = true ]; then
    echo "🔧 [MODULE: repair-packages] Re-triggering the system package configuration layout engine..."
    dpkg --configure -a || true
fi

# ------------------------------------------------------------------------------
# MODULE: ALLOW APPS
# ------------------------------------------------------------------------------
if [ "$RUN_ALLOW_APPS" = true ]; then
    echo "🔍 [MODULE: allow-apps] Checking external app integration properties..."
    mkdir -p ~/.termux
    if [ "$FORCE" = true ] || ! grep -q "allow-external-apps = true" ~/.termux/termux.properties 2>/dev/null; then
        echo "🔐 Registering external execution layer property settings..."
        # Prevent duplicate lines if forced by cleaning any existing entries first
        sed -i '/allow-external-apps/d' ~/.termux/termux.properties 2>/dev/null || true
        echo "allow-external-apps = true" >> ~/.termux/termux.properties
        termux-reload-settings
    else
        echo "✓ External app communications are already allowed."
    fi
fi

# ------------------------------------------------------------------------------
# MODULE: DESKTOP ENVIRONMENT
# ------------------------------------------------------------------------------
if [ "$RUN_DESKTOP_ENV" = true ]; then
    echo "🔍 [MODULE: desktop-env] Verifying visual XFCE environment stack components..."
    if [ "$FORCE" = true ] || ! command -v termux-x11 &>/dev/null || ! command -v xfce4-session &>/dev/null || ! dpkg -s mesa-vulkan-icd-freedreno &>/dev/null; then
        echo "🖥️ Provisioning X11 Server, native Turnip/Freedreno Vulkan stack, and XFCE4..."
        pkg install termux-x11 xfce4 xfce4-goodies \
                    mesa-vulkan-icd-freedreno mesa-demos \
                    gst-plugins-good gst-plugins-bad -y --reinstall
    else
        echo "✓ X11, Turnip drivers, and XFCE graphical suites are fully installed."
    fi
fi

# ------------------------------------------------------------------------------
# MODULE: NODE ENVIRONMENT
# ------------------------------------------------------------------------------
if [ "$RUN_NODE_ENV" = true ]; then
    echo "🔍 [MODULE: node-env] Checking Node.js and global package infrastructure..."
    if [ "$FORCE" = true ] || ! command -v node &>/dev/null || ! command -v git &>/dev/null; then
        echo "🟢 Deploying Node.js development runtime environment and build tools..."
        pkg install nodejs git build-essential curl -y --reinstall
    else
        echo "✓ Node.js and build essentials are present."
    fi

    if [ "$FORCE" = true ] || ! command -v pnpm &>/dev/null; then
        echo "⚡ Hydrating global NPM path space with the standalone Corepack manager..."
        npm install -g corepack pnpm
        corepack enable pnpm || true
    else
        echo "✓ pnpm toolchain package engine is active."
    fi
fi

# ------------------------------------------------------------------------------
# MODULE: INSTALL APPS
# ------------------------------------------------------------------------------
if [ "$RUN_INSTALL_APPS" = true ]; then
    echo "🔍 [MODULE: install-apps] Verifying desktop application binaries..."
    if [ "$FORCE" = true ] || ! command -v code-oss &>/dev/null || ! command -v rg &>/dev/null; then
        echo "📝 Installing Code-OSS & Ripgrep search backend..."
        pkg install code-oss ripgrep -y --reinstall
    else
        echo "✓ Code-OSS editor layers are fully available."
    fi

    if [ "$FORCE" = true ] || ! command -v firefox &>/dev/null; then
        echo "🦊 Deploying the mainline Firefox browser binary infrastructure..."
        pkg install firefox -y --reinstall
    else
        echo "✓ Firefox graphical engine is installed."
    fi

    if [ "$FORCE" = true ] || ! command -v chromium &>/dev/null; then
        echo "🌐 Deploying the Chromium browser binary infrastructure..."
        pkg install chromium -y --reinstall
    else
        echo "✓ Chromium web engine is installed."
    fi
fi

# ------------------------------------------------------------------------------
# MODULE: FIREFOX MCP
# ------------------------------------------------------------------------------
if [ "$RUN_FIREFOX_MCP" = true ]; then
    echo "🔍 [MODULE: firefox-mcp] Verifying Firefox DevTools MCP configuration and hotfix telemetry..."
    MCP_DIST_FILE="/data/data/com.termux/files/usr/lib/node_modules/@mozilla/firefox-devtools-mcp/dist/index.js"

    if [ "$FORCE" = true ] || [ ! -f "$MCP_DIST_FILE" ] || ! grep -q "termux-hotfix-applied" "$MCP_DIST_FILE" 2>/dev/null; then
        echo "⚡ Deploying global Firefox DevTools MCP server (v0.9.3)..."
        npm i -g @mozilla/firefox-devtools-mcp@0.9.3

        echo "📥 Injecting custom distribution patch file (0.9.3-termux-hotfix-dist)..."
        mkdir -p "$(dirname "$MCP_DIST_FILE")"
        curl -L "https://github.com/themarcocara/firefox-devtools-mcp/releases/download/0.9.3-termux-hotfix-dist/index.js" -o "$MCP_DIST_FILE"
        
        # Append a trailing single-line comment token to make the download idempotent
        echo -e "\n// termux-hotfix-applied" >> "$MCP_DIST_FILE"
        echo "✓ Hotfix patch committed successfully."
    else
        echo "✓ Firefox DevTools MCP v0.9.3 and target hotfix distributions are active."
    fi
fi

# ------------------------------------------------------------------------------
# MODULE: HARDEN FIREFOX
# ------------------------------------------------------------------------------
if [ "$RUN_HARDEN_FIREFOX" = true ]; then
    echo "🔍 [MODULE: harden-firefox] Checking Firefox privacy configurations..."
    FF_PREF_DIR="$HOME/.config/mozilla/firefox/o62cctdy.default-default"
    mkdir -p "$FF_PREF_DIR"

    if [ "$FORCE" = true ] || [ ! -f "$FF_PREF_DIR/user.js" ] || ! grep -q "CRITICAL MOZILLA TELEMETRY DEACTIVATION" "$FF_PREF_DIR/user.js" 2>/dev/null; then
        echo "🔒 Writing tracking deactivation tokens inside user profile layer..."
        
        # In force mode, rewrite using '>' instead of '>>' to clean out dirty states
        WRITE_OP=">>"
        [ "$FORCE" = true ] && WRITE_OP=">"
        
        cat << 'EOF' >${WRITE_OP} "$FF_PREF_DIR/user.js"

/*** [CRITICAL MOZILLA TELEMETRY DEACTIVATION] ***/
user_pref("toolkit.telemetry.enabled", false);
user_pref("toolkit.telemetry.unified", false);
user_pref("toolkit.telemetry.archive.enabled", false);
user_pref("toolkit.telemetry.server", "data:,");
user_pref("toolkit.telemetry.conditionalProvider.enabled", false);
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("browser.ping-centre.telemetry", false);

/*** [POCKET, SPEECH, & PROPAGANDA REMOVAL] ***/
user_pref("extensions.pocket.enabled", false);
user_pref("browser.newtabpage.activity-stream.feeds.discoverystreamfeed", false);
user_pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);
user_pref("browser.newtabpage.activity-stream.telemetry", false);

/*** [STUDIES & EXPERIMENTS SHUTDOWN] ***/
user_pref("experiments.enabled", false);
user_pref("experiments.supported", false);
user_pref("network.allow-experiments", false);
user_pref("breakpad.reportURL", "data:,");
user_pref("browser.tabs.crashReporting.sendReport", false);
EOF
    else
        echo "✓ Privacy ruleset profile configuration is already hardened."
    fi
fi

# ------------------------------------------------------------------------------
# MODULE: OPENCODE BINARY
# ------------------------------------------------------------------------------
if [ "$RUN_OPENCODE_BIN" = true ]; then
    echo "🔍 [MODULE: opencode-bin] Verifying OpenCode execution environments..."
    if [ "$FORCE" = true ] || ! dpkg -s glibc-repo &>/dev/null || ! dpkg -s glibc &>/dev/null; then
        echo "🤖 Setting up custom native glibc subsystem layers..."
        apt install -y glibc-repo
        apt update -y
        apt install -y glibc openssl-glibc --reinstall
    fi

    if [ "$FORCE" = true ] || ! command -v opencode &>/dev/null; then
        echo "🤖 Processing automated OpenCode toolchain installation..."
        if [ -n "$OPENCODE_URL" ]; then
            echo "📥 Direct link override detected via environment rules: $OPENCODE_URL"
            TARGET_DL_URL="$OPENCODE_URL"
        else
            echo "🔍 Scraping GitHub repository for modern asset releases..."
            TARGET_DL_URL=$(curl -s https://api.github.com/repos/Hope2333/opencode-termux/releases/latest | grep -o 'https://[^"]*aarch64\.deb' | head -n 1)
            
            if [ -z "$TARGET_DL_URL" ]; then
                echo "❌ Error: Could not resolve automated asset file markers from GitHub."
                echo "Please manually pass a direct URL: export OPENCODE_URL='...'"
                exit 1
            fi
        fi

        TEMP_DEB_PATH="$TMPDIR/opencode_latest_aarch64.deb"
        rm -f "$TEMP_DEB_PATH"
        
        echo "📥 Downloading dynamic payload target..."
        curl -L "$TARGET_DL_URL" -o "$TEMP_DEB_PATH"
        
        echo "📦 Committing package setup structures..."
        apt install -y "$TEMP_DEB_PATH" --reinstall
        rm -f "$TEMP_DEB_PATH"
    else
        echo "✓ OpenCode AI engine workspace is already fully installed."
    fi
fi

# ------------------------------------------------------------------------------
# MODULE: OPENCODE CONFIGURATION
# ------------------------------------------------------------------------------
if [ "$RUN_OPENCODE_CONFIG" = true ]; then
    echo "🔍 [MODULE: opencode-config] Looking up local layout mapping configurations..."

    # Sequential lookup for opencode.json
    OPENCODE_SRC=""
    if [ -f "opencode.json" ]; then
        OPENCODE_SRC="opencode.json"
    elif [ -f "$SCRIPT_DIR/opencode.json" ]; then
        OPENCODE_SRC="$SCRIPT_DIR/opencode.json"
    fi

    if [ -n "$OPENCODE_SRC" ]; then
        echo "📄 Found opencode.json at $OPENCODE_SRC. Migrating profile mappings..."
        mkdir -p "$HOME/.config/opencode"
        cp "$OPENCODE_SRC" "$HOME/.config/opencode/opencode.json"
    else
        echo "ℹ️ No local opencode.json found in CWD or script origin path."
    fi

    # Sequential lookup for auth.json
    AUTH_SRC=""
    if [ -f "auth.json" ]; then
        AUTH_SRC="auth.json"
    elif [ -f "$SCRIPT_DIR/auth.json" ]; then
        AUTH_SRC="$SCRIPT_DIR/auth.json"
    fi

    if [ -n "$AUTH_SRC" ]; then
        echo "🔐 Found auth.json at $AUTH_SRC. Processing environmental substitutions..."
        mkdir -p "$HOME/.local/share/opencode"
        
        # Read core payload structural data safely into memory
        AUTH_DATA=$(cat "$AUTH_SRC")
        
        # Process replacements using native bash search-and-replace strings
        AUTH_DATA="${AUTH_DATA//\{env:OPENCODE_API_KEY\}/$OPENCODE_API_KEY}"
        AUTH_DATA="${AUTH_DATA//\{env:NEURALWATT_API_KEY\}/$NEURALWATT_API_KEY}"
        AUTH_DATA="${AUTH_DATA//\{env:DEEPSEEK_API_KEY\}/$DEEPSEEK_API_KEY}"
        
        # Commit sanitized structural rules downstream
        echo "$AUTH_DATA" > "$HOME/.local/share/opencode/auth.json"
        echo "✓ Credentials securely compiled and mapped to target data paths."
    else
        echo "ℹ️ No local auth.json found in CWD or script origin path."
    fi
fi

# ------------------------------------------------------------------------------
# MODULE: LAUNCH SCRIPT
# ------------------------------------------------------------------------------
if [ "$RUN_LAUNCH_SCRIPT" = true ]; then
    echo "🔍 [MODULE: launch-script] Verifying runtime startup desktop macro hooks..."
    if [ "$FORCE" = true ] || [ ! -f "$HOME/.desktop-launch.sh" ]; then
        echo "🛠️ Creating macro launch handler utility script..."
        cat << 'EOF' > ~/.desktop-launch.sh
#!/usr/bin/env bash
killall -9 termux-x11 Xwayland xfce4-session 2>/dev/null
rm -rf /tmp/.X11-unix /tmp/.X*-lock

export XDG_RUNTIME_DIR=$TMPDIR
export DISPLAY=:1

echo "🎨 Booting underlying Termux-X11 pipeline matrix layer..."
termux-x11 :1 -ac &
sleep 2

export GALLIUM_DRIVER=zink
export MESA_LOADER_DRIVER_OVERRIDE=kgsl
export TU_DEBUG=noconform

echo "🔥 Launching the accelerated XFCE desktop environment framework..."
xfce4-session
EOF
        chmod +x ~/.desktop-launch.sh
    else
        echo "✓ Launch macro script (~/.desktop-launch.sh) is already safely intact."
    fi
fi

# Complete!
echo -e "\n================================================================================"
echo "🎉 SYSTEM AUDIT AND VERIFICATION SUCCESSFUL!"
echo "================================================================================"
echo "• All selected components verified, mapped, and fully configured."
echo "• Boot up the visual graphical XFCE workspace at any time: ~/.desktop-launch.sh"
echo "================================================================================"