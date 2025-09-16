#!/usr/bin/env bash
# add.sh — add a directory (folio) to IPFS with optional JSON output
#
# Usage:
#   ./add.sh [--ignore-file <path>] [--quiet|--no-quiet] [--recursive|--no-recursive]
#            [--wrap|--no-wrap] [--json|--json-all] [<dir>]
#   ./add.sh help
#
# Options:
#   --ignore-file <path>  Use this ignore file (default: .gitignore).
#   --quiet               Print minimal output from ipfs (default: quiet ON).
#   --no-quiet            Disable quiet mode.
#   --recursive           Add recursively (default: yes).
#   --no-recursive        Disable recursion.
#   --wrap                Wrap with a directory node.
#   --no-wrap             Do not wrap with a directory node (default).
#   --json                Emit a single JSON object with the root CID: {"cid": "..."}.
#   --json-all            Emit a JSON array of all entries (requires jq), with fields {cid, path}.
#
# Notes:
#   - Default command is equivalent to: ipfs add --ignore-rules-path .gitignore -Qr .
#   - With --json, we still run ipfs in quiet mode and return the *last* CID as the root CID.
#   - With --json-all, we parse "added <cid> <path>" lines into JSON (needs jq).
#
# Examples:
#   ./add.sh
#   ./add.sh --json
#   ./add.sh --json-all
#   ./add.sh --ignore-file .ipfsignore --wrap myproject/
#
# Exit codes:
#   0 on success, non-zero on failure.

set -euo pipefail

usage() {
  sed -n '2,40p' "$0"
}

short_help() {
  echo "Error: $1" >&2
  echo "Try: ./add.sh help" >&2
  exit 1
}

cmd="${1:-}"
if [[ -z "$cmd" || "$cmd" == "help" || "$cmd" == "-h" || "$cmd" == "--help" ]]; then
  usage
  exit 0
fi

# Defaults
ignore_file=".gitignore"
quiet="true"
recursive="true"
wrap="false"
json_root="false"
json_all="false"

# Parse options
while [[ $# -gt 0 ]]; do
  case "$1" in
    --ignore-file)
      [[ $# -ge 2 ]] || short_help "--ignore-file requires a path"
      ignore_file="$2"; shift 2 ;;
    --quiet) quiet="true"; shift ;;
    --no-quiet) quiet="false"; shift ;;
    --recursive) recursive="true"; shift ;;
    --no-recursive) recursive="false"; shift ;;
    --wrap) wrap="true"; shift ;;
    --no-wrap) wrap="false"; shift ;;
    --json) json_root="true"; shift ;;
    --json-all) json_all="true"; shift ;;
    --) shift; break ;;
    -*)
      short_help "unknown option '$1'" ;;
    *)
      break ;;
  esac
done

# Validate JSON flags
if [[ "$json_root" == "true" && "$json_all" == "true" ]]; then
  short_help "use either --json or --json-all (not both)"
fi

target="${1:-.}"

# Build base ipfs add args
args=(add --ignore-rules-path "$ignore_file")
[[ "$recursive" == "true" ]] && args+=(-r)
[[ "$wrap" == "true" ]] && args+=(--wrap-with-directory)

# Run and format output
if [[ "$json_all" == "true" ]]; then
  command -v jq >/dev/null 2>&1 || short_help "--json-all requires 'jq' to be installed"
  # For json-all we need the full "added <cid> <path>" lines, so force non-quiet
  out="$(ipfs "${args[@]}" "$target")"
  # Convert to JSON array using jq:
  # Lines look like: "added QmCID path/to/file" or "added QmCID ."
  # We split and keep the rest of the line (field 3..end) as path.
  printf '%s\n' "$out" \
    | awk 'BEGIN{OFS="\t"} /^added /{$1=""; sub(/^\t/,""); cid=$2; sub(/^\S+\s+/,""); path=$0; print cid, path}' \
    | jq -R -s 'split("\n")
        | map(select(length>0))
        | map(split("\t"))
        | map({"cid": .[0], "path": (.[1] // ".")})'
  exit 0
fi

# Otherwise, maybe JSON root or plain output (quiet default on)
[[ "$quiet" == "true" || "$json_root" == "true" ]] && args+=(-Q)

out="$(ipfs "${args[@]}" "$target")"

if [[ "$json_root" == "true" ]]; then
  # When quiet/recursive, ipfs may print multiple CIDs; last non-empty is root
  root_cid="$(printf '%s\n' "$out" | awk 'NF{last=$0} END{print last}')"
  # Emit minimal JSON without requiring jq
  printf '{\"cid\":\"%s\"}\n' "$root_cid"
else
  # Pass-through ipfs output
  printf '%s\n' "$out"
fi
