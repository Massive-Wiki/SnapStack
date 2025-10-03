#!/usr/bin/env bash

# add.sh — add a directory (folio) to IPFS with optional JSON output
#
# Usage:
#   bin/add.sh [--ignore-file <path>] [--quiet|--no-quiet]
#              [--recursive|--no-recursive] [--wrap|--no-wrap]
#              [--json|--json-all] [<dir>]
#   bin/add.sh help
#
# Options:
#   --ignore-file <path>  Use this ignore file (default: .gitignore).
#   --quiet               Print minimal output from ipfs (default: quiet ON).
#   --no-quiet            Disable quiet mode.
#   --recursive           Add recursively (default: yes).
#   --no-recursive        Disable recursion.
#   --wrap                Wrap with a directory node.
#   --no-wrap             Do not wrap with a directory node (default).
#   --json                Emit a single JSON object with the root CID: {"cid":"..."}.
#   --json-all            Emit a JSON array of all entries {cid, path} (requires jq).
#
# Notes:
#   - Default command is equivalent to: ipfs add --ignore-rules-path .gitignore -Qr .
#   - With --json, we still run ipfs in quiet mode and return the last printed CID as root.
#   - With --json-all, we parse "added <cid> <path>" lines without GNU awk/sed dependencies.

set -euo pipefail

usage() {
  sed -n '2,40p' "$0"
}

short_help() {
  echo "Error: $1" >&2
  echo "Try: bin/add.sh help" >&2
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

# Build ipfs add args
args=(add --ignore-rules-path "$ignore_file")
[[ "$recursive" == "true" ]] && args+=(-r)
[[ "$wrap" == "true" ]] && args+=(--wrap-with-directory)

# Execute
if [[ "$json_all" == "true" ]]; then
  command -v jq >/dev/null 2>&1 || short_help "--json-all requires 'jq' to be installed"
  # Need verbose lines like "added <cid> <path>", so don't force -Q
  out="$(ipfs "${args[@]}" "$target")"
  # Parse without GNU awk: use shell + jq
  echo "$out" | while IFS= read -r line; do
    case "$line" in
      added\ *)
        rest="${line#added }"               # strip leading "added "
        cid="${rest%% *}"                   # first token
        # path is rest after first token; handle case of no path (use ".")
        if [ "$rest" = "$cid" ]; then
          path="."
        else
          path="${rest#"$cid" }"
        fi
        printf '{"cid": %s, "path": %s}\n' \
          "$(printf '%s' "$cid" | jq -R .)" \
          "$(printf '%s' "$path" | jq -R .)"
        ;;
      *) : ;;
    esac
  done | jq -s '.'
  exit 0
fi

# Otherwise, possibly quiet or JSON root
[[ "$quiet" == "true" || "$json_root" == "true" ]] && args+=(-Q)

out="$(ipfs "${args[@]}" "$target")"

if [[ "$json_root" == "true" ]]; then
  # Last non-empty line is the root CID when -Q -r
  root_cid="$(printf '%s\n' "$out" | sed -n '/./p' | tail -n 1)"
  printf '{\"cid\":\"%s\"}\n' "$root_cid"
else
  printf '%s\n' "$out"
fi
