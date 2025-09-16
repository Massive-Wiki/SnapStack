#!/usr/bin/env bash
# pin.sh — simple wrapper for "pin pinata <CID>" with optional hostNodes
# Usage:
#   pin pinata [--addrs-from-ipfs] [--host-node <multiaddr>]... [--jwt-file <path>] <CID>
#   pin help

set -euo pipefail

PINATA_API="https://api.pinata.cloud/pinning/pinByHash"
DEFAULT_JWT_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/pinata/jwt"

usage() {
  cat <<EOF
Usage:
  pin pinata [--addrs-from-ipfs] [--host-node <multiaddr>]... [--jwt-file <path>] <CID>
  pin help

Options:
  --addrs-from-ipfs     Pull hostNodes from \`ipfs id\` (requires jq).
  --host-node <addr>    Add a specific multiaddr (repeatable).
  --jwt-file <path>     Read Pinata JWT from this file (default: $DEFAULT_JWT_FILE).

Env:
  PINATA_JWT            If set, overrides JWT file.

Examples:
  pin pinata Qm...CID
  pin pinata --addrs-from-ipfs Qm...CID
  pin pinata --host-node /ip4/1.2.3.4/tcp/4001/p2p/PeerID Qm...CID
EOF
}

short_help() {
  echo "Error: $1" >&2
  echo "Try: pin help" >&2
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
declare -a hostnodes
addrs_from_ipfs="false"

# Parse flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    --addrs-from-ipfs)
      addrs_from_ipfs="true"
      shift
      ;;
    --host-node)
      [[ $# -ge 2 ]] || short_help "--host-node requires a value"
      hostnodes+=("$2")
      shift 2
      ;;
    --jwt-file)
      [[ $# -ge 2 ]] || short_help "--jwt-file requires a path"
      jwt_file="$2"
      shift 2
      ;;
    --) shift; break ;;
    -*)
      short_help "unknown option '$1'"
      ;;
    *)
      # first non-flag is CID
      break
      ;;
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
  # Extract array of addresses
  mapfile -t addrs < <(ipfs id | jq -r '.Addresses[]')
  if [[ ${#addrs[@]} -eq 0 ]]; then
    short_help "no Addresses returned from 'ipfs id'"
  fi
  hostnodes+=("${addrs[@]}")
fi

# Build JSON payload
if [[ ${#hostnodes[@]} -gt 0 ]]; then
  # Build a JSON array of strings safely
  # shellcheck disable=SC2016
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
