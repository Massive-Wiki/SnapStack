# IPFS + Pinata Helper Scripts

This folio includes three Bash helper scripts for working with [IPFS](https://ipfs.tech) and [Pinata](https://www.pinata.cloud):

* `bin/add.sh` — add a directory to IPFS with ignore rules.
* `bin/pin.sh` — pin an existing CID to Pinata.
* `bin/status.sh` — check the pin status of a CID on Pinata.

Each script uses a consistent style:

* `--help` shows usage.
* Defaults are sensible, but you can override with flags.
* Pinata JWT is read from either the environment variable `PINATA_JWT` or a file (default: `~/.config/pinata/jwt`).

---

## Quick Usage

```bash
# Add current folio to IPFS, respecting .gitignore
bin/add.sh

# Pin a CID to Pinata
bin/pin.sh pin pinata QmYourCID

# Check status of a Pinata pin
bin/status.sh pinata QmYourCID
```

---

## JWT Setup

All Pinata commands require a JWT. You can provide it in two ways:

1. **Environment variable**:

   ```bash
   export PINATA_JWT='eyJ...'
   ```

2. **JWT file** (default: `~/.config/pinata/jwt`):

   ```bash
   mkdir -p ~/.config/pinata
   echo 'eyJ...' > ~/.config/pinata/jwt
   chmod 600 ~/.config/pinata/jwt
   ```

You can override the file location with `--jwt-file <path>`.

---

## `bin/add.sh`

Add the current directory (or a given target) to IPFS with sensible defaults.

### Summary

* Default command is equivalent to:

  ```bash
  ipfs add --ignore-rules-path .gitignore -Qr .
  ```
* Supports JSON output for scripting.
* Useful when your folio root already has a `.gitignore`.

### Usage

```bash
bin/add.sh [--ignore-file <path>] [--quiet|--no-quiet]
           [--recursive|--no-recursive] [--wrap|--no-wrap]
           [--json|--json-all] [<dir>]
bin/add.sh help
```

### Options

* `--ignore-file <path>`: Ignore file (default `.gitignore`).
* `--quiet / --no-quiet`: Minimal output (default: quiet).
* `--recursive / --no-recursive`: Add recursively (default: recursive).
* `--wrap / --no-wrap`: Wrap with a directory node (default: no wrap).
* `--json`: Emit a JSON object with the root CID.
* `--json-all`: Emit a JSON array of all added entries (`cid`, `path`) — requires `jq`.

### Examples

```bash
# Default add (quiet, recursive, ignore .gitignore)
bin/add.sh

# Return just root CID as JSON
bin/add.sh --json

# Return all entries as JSON array
bin/add.sh --json-all

# Wrap with directory node, custom ignore file
bin/add.sh --ignore-file .ipfsignore --wrap .
```

---

## `bin/pin.sh`

Pin an existing CID to [Pinata](https://www.pinata.cloud).

### Summary

* Wraps the Pinata `pinByHash` API.
* Reads JWT from `$PINATA_JWT` or `~/.config/pinata/jwt`.
* Can supply host nodes manually or via `ipfs id`.

### Usage

```bash
bin/pin.sh pin pinata [--addrs-from-ipfs] [--host-node <multiaddr>]...
                     [--jwt-file <path>] <CID>
bin/pin.sh help
```

### Options

* `--addrs-from-ipfs`: Use addresses from `ipfs id` (requires `jq`).
* `--host-node <addr>`: Add specific host node (repeatable).
* `--jwt-file <path>`: Path to JWT file (default `~/.config/pinata/jwt`).

### Examples

```bash
# Pin a CID with default JWT
bin/pin.sh pin pinata QmYourCID

# Pin with host nodes from your own IPFS daemon
bin/pin.sh pin pinata --addrs-from-ipfs QmYourCID

# Pin with custom host nodes
bin/pin.sh pin pinata \
  --host-node /ip4/203.0.113.9/tcp/4001/p2p/PeerID \
  --host-node /dns4/gateway.example/tcp/443/wss/p2p/PeerID \
  QmYourCID
```

---

## `bin/status.sh`

Check the status of a CID pinned to Pinata.

### Summary

* Wraps the Pinata `v3/files/public/pin_by_cid` endpoint.
* Shows known statuses:
  `prechecking`, `retrieving`, `expired`, `over_free_limit`, `over_max_size`,
  `invalid_object`, `bad_host_node`, `backfilled`.
* Can run once or in `--watch` mode.

### Usage

```bash
bin/status.sh pinata [--watch] [--interval <secs>]
                    [--jwt-file <path>] [--json] <CID>
bin/status.sh help
```

### Options

* `--watch`: Poll until status is no longer transitional.
* `--interval <secs>`: Poll interval (default 5s).
* `--jwt-file <path>`: Path to JWT file (default `~/.config/pinata/jwt`).
* `--json`: Print raw JSON response instead of a summary.

### Examples

```bash
# Check status once
bin/status.sh pinata QmYourCID

# Watch until complete
bin/status.sh pinata --watch --interval 3 QmYourCID

# Print raw JSON
bin/status.sh pinata --json QmYourCID
```

---
