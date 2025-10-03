#!/usr/bin/env bash
# pin.sh — simple wrapper for "pin pinata <CID>" with optional hostNodes
# Usage:
#   pin.sh pin pinata [--addrs-from-ipfs] [--host-node <multiaddr>]... [--jwt-file <path>] <CID>
#   pin.sh help

set -euo pipefail

PINATA_API="https://api.pinata.cloud/pinning/pinByHash"
DEFAULT_JWT_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/pinata/jwt"

usage() {
  cat <<EOF
Usage:
  bin/pin.sh pin pinata [--addrs-from-ipfs] [--host-node <multiaddr>]... [--jwt-file <path>] <CID>
  bin/pin.sh help

Options:
  --addrs-from-ipfs     Pull hostNodes from \`ipfs id\` (requires jq).
  --host-node <addr>    Add a specific multiaddr (repeatable).
  --jwt-file <path>     Read Pinata JWT from this file (default: $DEFAULT_JWT_FILE).

Env:
  PINATA_JWT            If set, overrides JWT file.

Examples:
  bin/pin.sh pin pinata Qm...
  bin/pin.sh pin pinata --addrs-from-ipfs Qm...
  bin/pin.sh pin pinata --host-node /ip4/.../tcp/4001/p2p/... Qm...
EOF
}

short_help() {
  echo "Error: $1" >&2
  echo "Try: bin/pin.sh help" >&2
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
hostnodes=()
addrs_from_ipfs="false"

# Parse flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    --addrs-from-ipfs)
      addrs_from_ipfs="true"; shift ;;
    --host-node)
      [[ $# -ge 2 ]] || short_help "--host-node requires a value"
      hostnodes+=("$2"); shift 2 ;;
    --jwt-file)
      [[ $# -ge 2 ]] || short_help "--jwt-file requires a path"
      jwt_file="$2"; shift 2 ;;
    --) shift; break ;;
    -*)
      short_help "unknown option '$1'" ;;
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

# Optionally pull hostNodes from `ipfs id`
if [[ "$addrs_from_ipfs" == "true" ]]; then
  command -v jq >/dev/null 2>&1 || short_help "jq is required for --addrs-from-ipfs"
  command -v ipfs >/dev/null 2>&1 || short_help "ipfs CLI not found for --addrs-from-ipfs"
  while IFS= read -r addr; do
    [[ -n "$addr" ]] && hostnodes+=("$addr")
  done < <(ipfs id | jq -r '.Addresses[]')
fi

# Build JSON payload
if [[ ${#hostnodes[@]} -gt 0 ]]; then
  hosts_json="$(printf '%s\n' "${hostnodes[@]}" | jq -R . | jq -s .)"
  payload="$(jq -n --arg cid "$CID" --argjson hosts "$hosts_json" \
    '{hashToPin:$cid, pinataOptions:{hostNodes:$hosts}}')"
else
  payload="$(jq -n --arg cid "$CID" '{hashToPin:$cid}')"
fi

# Make request
response="$(
  curl --silent --show-error --fail \
    --request POST "$PINATA_API" \
    --header "Authorization: Bearer $JWT" \
    --header "Content-Type: application/json" \
    --data "$payload"
)"

# Pretty-print minimal result
echo "$response" | jq '{id, ipfsHash, status, name}'
