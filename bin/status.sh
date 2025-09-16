#!/usr/bin/env bash
# status.sh — check Pinata pin status for a CID
#
# Usage:
#   bin/status.sh pinata [--watch] [--interval <secs>] [--jwt-file <path>] [--json] <CID>
#   bin/status.sh help
#
# Status values (from Pinata):
#   prechecking, retrieving, expired, over_free_limit, over_max_size,
#   invalid_object, bad_host_node, backfilled
#
# Notes:
#   - "0 rows" means Pinata hasn't recorded a status for that CID yet.
#   - In --watch mode, we poll until status leaves {prechecking,retrieving}
#     or until the record disappears (0 rows).

set -euo pipefail

PINATA_API="https://api.pinata.cloud/v3/files/public/pin_by_cid"
DEFAULT_JWT_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/pinata/jwt"

usage() {
  cat <<EOF
Usage:
  bin/status.sh pinata [--watch] [--interval <secs>] [--jwt-file <path>] [--json] <CID>
  bin/status.sh help

Options:
  --watch             Poll until status is no longer "prechecking" or "retrieving", or until no rows exist.
  --interval <secs>   Poll interval in seconds (default: 5).
  --jwt-file <path>   Read Pinata JWT from this file (default: $DEFAULT_JWT_FILE).
  --json              Print raw JSON response (one line) instead of a friendly summary.

Env:
  PINATA_JWT          If set, overrides JWT file.
EOF
}

short_help() {
  echo "Error: $1" >&2
  echo "Try: bin/status.sh help" >&2
  exit 1
}

cmd="${1:-}"
if [[ -z "$cmd" || "$cmd" == "help" || "$cmd" == "-h" || "$cmd" == "--help" ]]; then
  usage
  exit 0
fi
if [[ "$cmd" != "pinata" ]]; then
  short_help "unknown subcommand '$cmd' (expected 'pinata')"
fi
shift

# Defaults
jwt_file="$DEFAULT_JWT_FILE"
watch="false"
interval=5
raw_json="false"

# Parse options
while [[ $# -gt 0 ]]; do
  case "$1" in
    --watch) watch="true"; shift ;;
    --interval)
      [[ $# -ge 2 ]] || short_help "--interval requires a number"
      interval="$2"; shift 2 ;;
    --jwt-file)
      [[ $# -ge 2 ]] || short_help "--jwt-file requires a path"
      jwt_file="$2"; shift 2 ;;
    --json) raw_json="true"; shift ;;
    --) shift; break ;;
    -*) short_help "unknown option '$1'" ;;
    *) break ;;
  esac
done

CID="${1:-}"
[[ -n "$CID" ]] || short_help "missing <CID>"

# Resolve JWT
if [[ -n "${PINATA_JWT:-}" ]]; then
  JWT="$PINATA_JWT"
else
  if [[ ! -f "$jwt_file" ]]; then
    short_help "Pinata JWT not found; create $jwt_file or set PINATA_JWT"
  fi
  JWT="$(<"$jwt_file")"
fi
[[ -n "$JWT" ]] || short_help "Pinata JWT is empty"

fetch_once() {
  curl --silent --show-error --fail \
    --request GET "${PINATA_API}?cid=${CID}" \
    --header "Authorization: Bearer ${JWT}" \
    --header "Content-Type: application/json"
}

print_summary() {
  local json="$1"
  local count
  count="$(jq -r '.count // 0' <<<"$json")"

  if [[ "$count" -eq 0 ]]; then
    echo "cid: ${CID}"
    echo "status: no_record_yet"
    return 0
  fi

  local status created updated id name regions
  status="$(jq -r '.rows[0].status // "unknown"' <<<"$json")"
  created="$(jq -r '.rows[0].created_at // .rows[0].date_pinned // "unknown"' <<<"$json")"
  updated="$(jq -r '.rows[0].updated_at // .rows[0].date_unpinned // "unknown"' <<<"$json")"
  id="$(jq -r '.rows[0].id // "unknown"' <<<"$json")"
  name="$(jq -r '.rows[0].name // empty' <<<"$json")"
  regions="$(jq -r '(.rows[0].regions // .rows[0].region // []) | (if type=="array" then join(",") else tostring end // "")' <<<"$json")"

  echo "cid: ${CID}"
  echo "status: ${status}"
  [[ -n "$name" ]] && echo "name: ${name}"
  echo "id: ${id}"
  echo "created_at: ${created}"
  echo "updated_at: ${updated}"
  [[ -n "$regions" ]] && echo "regions: ${regions}"
}

should_continue() {
  local status="$1"
  [[ "$status" == "prechecking" || "$status" == "retrieving" ]]
}

if [[ "$watch" == "false" ]]; then
  resp="$(fetch_once)"
  if [[ "$raw_json" == "true" ]]; then
    echo "$resp"
  else
    print_summary "$resp"
  fi
  exit 0
fi

# --watch mode
while true; do
  resp="$(fetch_once)" || {
    echo "Request failed; will retry in ${interval}s..." >&2
    sleep "$interval"
    continue
  }

  if [[ "$raw_json" == "true" ]]; then
    echo "$resp"
  else
    print_summary "$resp"
  fi

  count="$(jq -r '.count // 0' <<<"$resp")"
  if [[ "$count" -eq 0 ]]; then
    sleep "$interval"
    continue
  fi

  status_val="$(jq -r '.rows[0].status // "unknown"' <<<"$resp")"
  if should_continue "$status_val"; then
    sleep "$interval"
  else
    [[ "$raw_json" == "false" ]] && print_summary "$resp"
    exit 0
  fi
done
