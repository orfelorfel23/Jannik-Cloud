#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
AGE_PUB_KEY="${REPO_ROOT}/keys/age-public-key.txt"

generate_secret() { openssl rand -base64 48 | tr -dc 'A-Za-z0-9' | head -c 32; }
generate_agent_token() { echo "sg_agent_$(openssl rand -hex 16)"; }
generate_webhook_token() { echo "sg_hook_$(openssl rand -hex 16)"; }

create_profile_env() {
    local env_file="$1"
    local desc="$2"
    local admin_pw="$3"
    local streamer_pw="$4"
    local mod_pw="$5"
    local twitch_channel="$6"

    local file_path="${SCRIPT_DIR}/${env_file}"
    local age_path="${SCRIPT_DIR}/${env_file}.age"

    if [[ ! -f "${file_path}" ]]; then
        cat > "${file_path}" <<EOF
# StreamGremlin Secrets - ${desc}
PORT=4736
SESSION_SECRET=$(generate_secret)
AGENT_TOKEN=$(generate_agent_token)
WEBHOOK_TOKEN=$(generate_webhook_token)
ADMIN_PASSWORD=${admin_pw}
STREAMER_PASSWORD=${streamer_pw}
MOD_PASSWORD=${mod_pw}
TWITCH_CLIENT_ID=
TWITCH_CLIENT_SECRET=
TWITCH_BROADCASTER_CHANNEL=${twitch_channel}
TWITCH_BOT_CHANNEL=
HA_BASE_URL=https://home.orfel.de
HA_ACCESS_TOKEN=
N8N_WEBHOOK_URL=
EOF
        chmod 600 "${file_path}"
        echo "Generated new ${env_file} (${desc})"
    fi

    if [[ -f "${AGE_PUB_KEY}" ]] && command -v age >/dev/null 2>&1; then
        age -r "$(tr -d '\r\n' < "${AGE_PUB_KEY}")" -o "${age_path}" "${file_path}"
        echo "Encrypted ${env_file} -> ${env_file}.age"
    fi
}

# 1. Main Profile
create_profile_env ".env" "Main Streamer (streamgremlin.orfel.de)" "admin" "streamer" "mod" ""

# 2. JonisDaily Profile
create_profile_env ".env.jonisdaily" "JonisDaily (jonisdaily-streamgremlin.orfel.de)" "admin" "jonisdaily" "jonis-mod" "jonisdaily"

# 3. NiggePhotography Profile
create_profile_env ".env.niggephotography" "NiggePhotography (niggephotography-streamgremlin.orfel.de)" "admin" "niggephotography" "nigge-mod" "niggephotography"

echo "StreamGremlin 3-streamer environments generated."
