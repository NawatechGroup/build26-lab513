#!/usr/bin/env bash
# ===========================================================================
# sqldbhyperscale.sh
# Create a dedicated Azure SQL logical server + Hyperscale database.
# The script creates a NEW dedicated SQL server, whitelists your current
# public IP, and creates a Hyperscale database with a random suffix by default.
#
# Windows usage (PowerShell + WSL/Git Bash):
#   chmod +x ./sqldbhyperscale.sh
#   ./sqldbhyperscale.sh
#
#   Optional shortcuts / overrides:
#     --instance ID    Fills in rg-lab513-ID, faq-ai-server-ID, admin-ID
#     --server-rg RG   Resource group (alias: --rg, --resource-group)
#     --server NAME    Dedicated SQL server name (default: faq-ai-server-<shared-random>)
#     --location LOC   Server location (default: indonesiacentral)
#     --database NAME  Database name (default: faq-ai-assistant-db-<shared-random>)
#     --admin USER     SQL admin username (default: admin-ID when using --instance)
#     --env-file FILE  Output env file (default: ./sqldbhyperscale.env)
#     --ai-endpoint EP Azure Foundry endpoint host or URL (for SQL bootstrap)
#     --ai-key KEY     Azure Foundry API key (for SQL bootstrap)
#     --no-sql-bootstrap
#     --subscription SUB
#     --yes
# ===========================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR"

if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'; C_BLUE=$'\033[34m'; C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'; C_RED=$'\033[31m'; C_BOLD=$'\033[1m'
else
  C_RESET=""; C_BLUE=""; C_GREEN=""; C_YELLOW=""; C_RED=""; C_BOLD=""
fi

log()  { printf '%s[ %s ]%s %s\n' "$C_BLUE"  "info" "$C_RESET" "$*"; }
ok()   { printf '%s[  ok ]%s %s\n' "$C_GREEN" "$C_RESET" "$*"; }
warn() { printf '%s[warn ]%s %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
err()  { printf '%s[error]%s %s\n' "$C_RED"   "$C_RESET" "$*" >&2; }
die()  { err "$*"; exit 1; }
hr()   { printf '%s\n' "------------------------------------------------------------"; }

_PHASE_NAMES=(); _PHASE_SECS=(); _CUR_PHASE=""; _CUR_T0=0
fmt_secs() { local s="${1:-0}"; printf '%dm%02ds' $(( s / 60 )) $(( s % 60 )); }
_close_phase() {
  [[ -z "$_CUR_PHASE" ]] && return 0
  _PHASE_NAMES+=("$_CUR_PHASE")
  _PHASE_SECS+=( $(( $(date +%s) - _CUR_T0 )) )
  _CUR_PHASE=""
}
phase() { _close_phase; _CUR_PHASE="$*"; _CUR_T0=$(date +%s); hr; log "$*"; hr; }
print_timing_summary() {
  _close_phase
  local i total=0
  hr; printf '%s[ time ]%s phase durations\n' "$C_BLUE" "$C_RESET"
  for i in "${!_PHASE_NAMES[@]}"; do
    printf '   %-46s %s\n' "${_PHASE_NAMES[$i]}" "$(fmt_secs "${_PHASE_SECS[$i]}")"
    total=$(( total + ${_PHASE_SECS[$i]} ))
  done
  printf '   %-46s %s\n' "TOTAL" "$(fmt_secs "$total")"; hr
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Required command '$1' not found in PATH. $2"
}

preflight_network() {
  log "Checking outbound connectivity to Azure (management.azure.com) ..."
  local code
  code="$(curl -sS -m 8 -o /dev/null -w '%{http_code}' "https://management.azure.com/" 2>/dev/null || echo 000)"
  if [[ "$code" != "000" ]]; then
    ok "Azure control plane reachable (HTTP ${code})."
    return 0
  fi
  die "Cannot reach https://management.azure.com from this shell."
}

ensure_login() {
  log "Checking Azure CLI sign-in ..."
  if ! az account show >/dev/null 2>&1; then
    die "Not signed in. Run: az login (or az login --use-device-code)"
  fi
  CURRENT_SUB_NAME=$(az account show --query name -o tsv)
  CURRENT_SUB_ID=$(az account show --query id -o tsv)
  CURRENT_USER=$(az account show --query user.name -o tsv)
  ok "Signed in as ${CURRENT_USER} on subscription '${CURRENT_SUB_NAME}'."
}

confirm() {
  local prompt="$1" reply
  if [[ "${AUTO_YES:-0}" == "1" ]]; then return 0; fi
  read -r -p "$prompt [type 'yes' to continue]: " reply
  [[ "$reply" == "yes" ]]
}

LAB_INSTANCE_ID=""
SERVER_RG="workshop-microsoft-august"
SQL_SERVER=""
LOCATION="indonesiacentral"
SQL_DB="faq-ai-assistant-db"
SQL_ADMIN="adminuser"
SQL_PASSWORD=""
ENV_FILE="${ROOT_DIR}/sqldbhyperscale.env"
SQL_DIR="${ROOT_DIR}/sql"
GEN_DIR="${ROOT_DIR}/.generated"
DO_SQL_BOOTSTRAP=1
AI_ENDPOINT=""
AI_ENDPOINT_HOST=""
AI_KEY=""
SUBSCRIPTION=""
AUTO_YES=0
DB_NAME_EXPLICIT=0
SERVER_NAME_EXPLICIT=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --instance)        LAB_INSTANCE_ID="$2"; shift 2;;
    --server-rg|--rg|--resource-group) SERVER_RG="$2"; shift 2;;
    --server)          SQL_SERVER="$2"; SERVER_NAME_EXPLICIT=1; shift 2;;
    --location)        LOCATION="$2"; shift 2;;
    --database)        SQL_DB="$2"; DB_NAME_EXPLICIT=1; shift 2;;
    --admin)           SQL_ADMIN="$2"; shift 2;;
    --env-file)        ENV_FILE="$2"; shift 2;;
    --ai-endpoint)     AI_ENDPOINT="$2"; shift 2;;
    --ai-key)          AI_KEY="$2"; shift 2;;
    --no-sql-bootstrap) DO_SQL_BOOTSTRAP=0; shift;;
    --subscription)    SUBSCRIPTION="$2"; shift 2;;
    --yes|-y)          AUTO_YES=1; shift;;
    -h|--help)
      cat <<'EOF'
sqldbhyperscale.sh - create dedicated SQL server + Hyperscale Azure SQL Database

Usage:
  Windows (PowerShell + WSL/Git Bash):
    chmod +x ./sqldbhyperscale.sh
    ./sqldbhyperscale.sh

  Optional alternative:
    ./sqldbhyperscale.sh --instance ID

Optional shortcuts / overrides:
  --instance ID    Fills in rg-lab513-ID, faq-ai-server-ID, admin-ID
  --server-rg RG   Resource group (alias: --rg, --resource-group)
  --server NAME    Dedicated SQL server name (default: faq-ai-server-<shared-random>)
  --location LOC   Server location (default: indonesiacentral)
  --database NAME  Database name (default: faq-ai-assistant-db-<shared-random>)
  --admin USER     SQL admin username
  --env-file FILE  Output env file (default: ./sqldbhyperscale.env)
  --ai-endpoint EP Azure Foundry endpoint host or URL (for SQL bootstrap)
  --ai-key KEY     Azure Foundry API key (for SQL bootstrap)
  --no-sql-bootstrap
  --subscription SUB
  --yes

Notes:
  - The script creates a NEW dedicated SQL server and database.
  - It does not create resource groups; target RG must already exist.
  - It auto-generates the SQL admin password and stores it in the env file.
  - It automatically whitelists your current public client IP on the SQL server.
  - SQL bootstrap applies: 01_schema.sql, 02_seed_faq.sql,
    03_generate_embeddings.sql, 04_search_proc.sql.
  - If --ai-endpoint/--ai-key are not passed, the script asks during runtime.
EOF
      exit 0
      ;;
    *) die "Unknown argument: $1 (use --help)";;
  esac
done
export AUTO_YES

is_ipv4() {
  local ip="$1"
  [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]
}

current_public_ip() {
  local ip
  ip="$(curl -fsS https://api.ipify.org 2>/dev/null || true)"
  if ! is_ipv4 "$ip"; then
    ip="$(curl -fsS https://ifconfig.me 2>/dev/null || true)"
  fi
  if is_ipv4 "$ip"; then
    printf '%s' "$ip"
  fi
}

shell_quote() {
  local value="$1"
  printf '%q' "$value"
}

gen_suffix() {
  local s
  s="$(printf '%04x%04x' "$RANDOM" "$RANDOM")"
  s="${s:0:6}"
  printf '%s' "$s"
}

gen_firewall_rule_name() {
  local ip_slug ts rnd
  ip_slug="${1//./-}"
  ts="$(date -u +%Y%m%d%H%M%S)"
  rnd="$(printf '%04x' "$RANDOM")"
  printf 'AllowClientIP-%s-%s-%s' "$ip_slug" "$ts" "$rnd"
}

gen_password() {
  local base
  base=$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 21)
  # Keep password easy to type: letters+numbers only, while satisfying
  # Azure SQL complexity with upper+lower+digit categories.
  printf 'Aa1%s' "$base"
}

normalize_ai_endpoint_host() {
  local endpoint="$1"
  endpoint="${endpoint//$'\r'/}"
  endpoint="${endpoint#https://}"
  endpoint="${endpoint#http://}"
  endpoint="${endpoint%%/*}"
  printf '%s' "$endpoint"
}

escape_sed_replacement() {
  local text="$1"
  printf '%s' "$text" | sed -e 's/[\\&|]/\\&/g'
}

require_file() {
  local path="$1"
  [[ -f "$path" ]] || die "Required file not found: $path"
}

prompt_ai_credentials() {
  if [[ -z "$AI_ENDPOINT" ]]; then
    read -r -p "Azure Foundry endpoint host or URL: " AI_ENDPOINT
  fi
  AI_ENDPOINT="${AI_ENDPOINT//$'\r'/}"
  [[ -n "$AI_ENDPOINT" ]] || die "Azure Foundry endpoint is required for SQL bootstrap."

  if [[ -z "$AI_KEY" ]]; then
    read -r -s -p "Azure Foundry API key: " AI_KEY
    printf '\n'
  fi
  AI_KEY="${AI_KEY//$'\r'/}"
  [[ -n "$AI_KEY" ]] || die "Azure Foundry API key is required for SQL bootstrap."

  AI_ENDPOINT_HOST="$(normalize_ai_endpoint_host "$AI_ENDPOINT")"
  [[ -n "$AI_ENDPOINT_HOST" ]] || die "Unable to parse Azure Foundry endpoint host from '${AI_ENDPOINT}'."
}

render_bootstrap_sql() {
  local endpoint_escaped key_escaped
  endpoint_escaped="$(escape_sed_replacement "$AI_ENDPOINT_HOST")"
  key_escaped="$(escape_sed_replacement "$AI_KEY")"

  mkdir -p "$GEN_DIR"
  chmod 700 "$GEN_DIR"

  sed -e "s|<YOUR_FOUNDRY_API_KEY>|${key_escaped}|g" \
      -e "s|<YOUR_FOUNDRY_ENDPOINT>|${endpoint_escaped}|g" \
      "$SQL_DIR/03_generate_embeddings.sql" > "$GEN_DIR/03_generate_embeddings.sql"

  sed -e "s|<YOUR_FOUNDRY_API_KEY>|${key_escaped}|g" \
      -e "s|<YOUR_FOUNDRY_ENDPOINT>|${endpoint_escaped}|g" \
      "$SQL_DIR/04_search_proc.sql" > "$GEN_DIR/04_search_proc.sql"

  chmod 600 "$GEN_DIR/03_generate_embeddings.sql" "$GEN_DIR/04_search_proc.sql"
}

phase "1/5  Preflight"
require_cmd az "Install: https://learn.microsoft.com/cli/azure/install-azure-cli"
require_cmd curl ""
preflight_network
ensure_login

if [[ -n "$SUBSCRIPTION" ]]; then
  log "Setting subscription to '${SUBSCRIPTION}' ..."
  az account set --subscription "$SUBSCRIPTION"
  ensure_login
fi

if [[ -n "$LAB_INSTANCE_ID" ]]; then
  LAB_INSTANCE_ID="$(tr '[:upper:]' '[:lower:]' <<<"$LAB_INSTANCE_ID")"
  [[ -z "$SERVER_RG" ]] && SERVER_RG="rg-lab513-${LAB_INSTANCE_ID}"
  [[ -z "$SQL_SERVER" ]] && SQL_SERVER="faq-ai-server-${LAB_INSTANCE_ID}"
  [[ -z "$SQL_ADMIN" ]] && SQL_ADMIN="admin-${LAB_INSTANCE_ID}"
fi

[[ -n "$SERVER_RG" ]] || die "Missing required --server-rg (or use --instance to infer rg-lab513-<id>)."

if [[ "$SERVER_NAME_EXPLICIT" == "0" || "$DB_NAME_EXPLICIT" == "0" ]]; then
  RUN_SUFFIX="$(gen_suffix)"
fi

if [[ "$SERVER_NAME_EXPLICIT" == "0" ]]; then
  SQL_SERVER="faq-ai-server-${RUN_SUFFIX}"
fi
SQL_SERVER="$(tr '[:upper:]' '[:lower:]' <<<"$SQL_SERVER")"

if [[ "$DB_NAME_EXPLICIT" == "0" ]]; then
  SQL_DB="${SQL_DB}-${RUN_SUFFIX}"
fi
if [[ -z "$SQL_PASSWORD" ]]; then
  SQL_PASSWORD="$(gen_password)"
fi

phase "2/5  Create dedicated SQL server"
if az group show -n "$SERVER_RG" >/dev/null 2>&1; then
  ok "Resource group ${SERVER_RG} already exists."
else
  die "Resource group '${SERVER_RG}' not found. Create it first, then rerun this script."
fi

if az sql server show -g "$SERVER_RG" -n "$SQL_SERVER" >/dev/null 2>&1; then
  die "SQL server '${SQL_SERVER}' already exists in '${SERVER_RG}'. Pick another --server name for a dedicated server."
fi

az sql server create -g "$SERVER_RG" -n "$SQL_SERVER" -l "$LOCATION" \
  --admin-user "$SQL_ADMIN" --admin-password "$SQL_PASSWORD" \
  --enable-public-network true -o none
ok "Dedicated SQL server ${SQL_SERVER} created."

phase "3/5  Whitelist current client IP"
CLIENT_IP="$(current_public_ip || true)"
if ! is_ipv4 "$CLIENT_IP"; then
  die "Could not determine current public IPv4 address for SQL firewall whitelist."
fi
FW_RULE_NAME="$(gen_firewall_rule_name "$CLIENT_IP")"
az sql server firewall-rule create -g "$SERVER_RG" -s "$SQL_SERVER" -n "$FW_RULE_NAME" \
  --start-ip-address "$CLIENT_IP" --end-ip-address "$CLIENT_IP" -o none
ok "SQL firewall rule ${FW_RULE_NAME} set to ${CLIENT_IP}."

hr; printf '%sDatabase plan%s\n' "$C_BOLD" "$C_RESET"; hr
cat <<EOF
  Subscription : ${CURRENT_SUB_NAME} (${CURRENT_SUB_ID})
  Server RG    : ${SERVER_RG}
  Location     : ${LOCATION}
  SQL server   : ${SQL_SERVER}
  Database     : ${SQL_DB}
  SQL admin    : ${SQL_ADMIN}
  Password     : auto-generated for this dedicated server and saved to ${ENV_FILE}
EOF
hr
confirm "Proceed with Hyperscale database creation?" || die "Aborted by user."

phase "4/5  Create Hyperscale database"
if az sql db show -g "$SERVER_RG" -s "$SQL_SERVER" -n "$SQL_DB" >/dev/null 2>&1; then
  ok "Database ${SQL_DB} already exists on ${SQL_SERVER}; skipping create."
else
  az sql db create -g "$SERVER_RG" -s "$SQL_SERVER" -n "$SQL_DB" \
    --edition Hyperscale --family Gen5 --capacity 2 \
    --compute-model Serverless --ha-replicas 0 \
    --backup-storage-redundancy Local -o none
  ok "Database ${SQL_DB} created on ${SQL_SERVER}."
fi

umask 077
{
  printf '# Generated %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf 'SERVER_RG=%s\n' "$(shell_quote "$SERVER_RG")"
  printf 'LOCATION=%s\n' "$(shell_quote "$LOCATION")"
  printf 'SQL_SERVER=%s\n' "$(shell_quote "$SQL_SERVER")"
  printf 'SQL_FQDN=%s\n' "$(shell_quote "${SQL_SERVER}.database.windows.net")"
  printf 'SQL_DB=%s\n' "$(shell_quote "$SQL_DB")"
  printf 'SQL_ADMIN=%s\n' "$(shell_quote "$SQL_ADMIN")"
  printf 'SQL_PASSWORD=%s\n' "$(shell_quote "$SQL_PASSWORD")"
} > "$ENV_FILE"
chmod 600 "$ENV_FILE"
ok "Connection details written to ${ENV_FILE} (chmod 600)."

if [[ "$DO_SQL_BOOTSTRAP" == "1" ]]; then
  phase "5/5  SQL bootstrap"
  require_cmd sed ""
  require_cmd sqlcmd "Install sqlcmd: https://learn.microsoft.com/sql/tools/sqlcmd/sqlcmd-utility"

  require_file "$SQL_DIR/01_schema.sql"
  require_file "$SQL_DIR/02_seed_faq.sql"
  require_file "$SQL_DIR/03_generate_embeddings.sql"
  require_file "$SQL_DIR/04_search_proc.sql"

  prompt_ai_credentials
  render_bootstrap_sql

  SQLCMD=(sqlcmd -S "tcp:${SQL_SERVER}.database.windows.net,1433" -d "$SQL_DB" -U "$SQL_ADMIN" -P "$SQL_PASSWORD" -C -l 60)

  log "Applying 01_schema.sql ..."
  "${SQLCMD[@]}" -i "$SQL_DIR/01_schema.sql"

  log "Applying 02_seed_faq.sql ..."
  "${SQLCMD[@]}" -i "$SQL_DIR/02_seed_faq.sql"

  log "Applying 03_generate_embeddings.sql ..."
  "${SQLCMD[@]}" -i "$GEN_DIR/03_generate_embeddings.sql"

  log "Applying 04_search_proc.sql ..."
  "${SQLCMD[@]}" -i "$GEN_DIR/04_search_proc.sql"

  ok "SQL bootstrap finished for ${SQL_DB}."
  log "Rendered SQL files saved in ${GEN_DIR}."
else
  log "SQL bootstrap skipped (--no-sql-bootstrap)."
fi

print_timing_summary
hr; ok "Hyperscale database setup complete."; hr
printf '%sSQL credentials%s\n' "$C_BOLD" "$C_RESET"
printf '  Server   : %s.database.windows.net\n' "$SQL_SERVER"
printf '  Database : %s\n' "$SQL_DB"
printf '  Login    : %s\n' "$SQL_ADMIN"
printf '  Password : %s\n' "$SQL_PASSWORD"
hr
cat <<EOF
  Next step:
    source ${ENV_FILE}
    sqlcmd -S "tcp:${SQL_SERVER}.database.windows.net,1433" -d "${SQL_DB}" -U "${SQL_ADMIN}" -P "\$SQL_PASSWORD" -C
EOF
