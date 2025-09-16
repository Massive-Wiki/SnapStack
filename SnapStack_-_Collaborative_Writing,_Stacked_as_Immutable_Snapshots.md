# SnapStack - Collaborative Writing, Stacked as Immutable Snapshots

## What IPFS gives you (in this context)

- **Immutable snapshots**: every `ipfs add -r folder/` returns a new **CID** that cryptographically matches the exact bytes of that version. ([docs.ipfs.tech](https://docs.ipfs.tech/quickstart/publish_cli/))
- **A moving pointer**: publish the *current* snapshot under an **IPNS** name, then update that pointer whenever you re-add your folder. Peers fetch via your stable IPNS address. ([docs.ipfs.tech](https://docs.ipfs.tech/concepts/ipns/))
- **Decide who persists it**: any peer (including you) can **pin** the CID to keep it around; you can also use remote pinning services. ([docs.ipfs.tech](https://docs.ipfs.tech/how-to/pin-files/), [docs.pinata.cloud](https://docs.pinata.cloud/ipfs-101/what-is-ipfs-pinning))

## Minimal setup (Kubo CLI)

1. Install Kubo (`ipfs`) and init:

```bash
# macOS
brew install ipfs
ipfs init
ipfs daemon
```

Docs: install, init, and basic CLI. ([docs.ipfs.tech](https://docs.ipfs.tech/install/command-line/))

1. Add your text collection and get a CID:

```bash
ipfs add -Qr /path/to/texts     # -Q = quiet (just the CID), -r = recursive
```

Re-running `ipfs add -r` after edits yields a **new top-level CID** (subfiles’ CIDs stay the same if unchanged). ([Stack Overflow](https://stackoverflow.com/questions/39803954/ipfs-how-to-add-a-file-to-an-existing-folder))

1. Create (once) and publish an IPNS name:

```bash
ipfs key gen --type=rsa --size=2048 texts-key
ipfs name publish --key=texts-key <CID_FROM_STEP_2>
# Output looks like: Published to k51q...: /ipfs/<CID>
```

IPNS is a mutable pointer you can republish to when the CID changes; nodes periodically rebroadcast the record. ([docs.ipfs.tech](https://docs.ipfs.tech/concepts/ipns/))

1. Peers fetch & pin:

```bash
# Using the CID directly
ipfs pin add <CID>

# Or follow your IPNS name to the current CID, then pin:
ipfs name resolve k51q...             # shows /ipfs/<currentCID>
ipfs pin add <currentCID>
```

About pinning (local or via a remote service). ([docs.ipfs.tech](https://docs.ipfs.tech/how-to/pin-files/), [docs.pinata.cloud](https://docs.pinata.cloud/ipfs-101/what-is-ipfs-pinning))

## Updating your shared set

Each time you edit files:

```bash
NEWCID=$(ipfs add -Qr /path/to/texts)
ipfs name publish --key=texts-key $NEWCID
```

That’s it—your **IPNS** address stays the same; it just points to the latest snapshot. (Under the hood, directory CIDs change when contents change.) ([Stack Overflow](https://stackoverflow.com/questions/39803954/ipfs-how-to-add-a-file-to-an-existing-folder))

## Optional niceties

- **Browser convenience**: install IPFS Companion so `ipfs://` and `ipns://` links resolve via your local node or a gateway. ([Chrome Web Store](https://chromewebstore.google.com/detail/ipfs-companion/nibjojkomfdiaoajekhjakgkdhaomnch?hl=en&utm_source=chatgpt.com))
- **Command quickstart references**: Kubo CLI basics & publish-from-CLI docs. ([docs.ipfs.tech](https://docs.ipfs.tech/how-to/kubo-basic-cli/))

## Trade-offs to know

- **Not a two-way sync/merge**: IPFS doesn’t resolve edit conflicts; think “publish signed snapshots,” not collaborative diffing.
- **IPNS latency**: updates are near-real-time but not instant; IPNS records propagate on a schedule (rebroadcast by default). For most small groups this is fine; if you need stricter SLAs, coordinate via chat and pin the new CID directly. ([docs.ipfs.tech](https://docs.ipfs.tech/concepts/ipns/))

love this direction. here’s a lightweight, low-drama set of “how we work” rules for a small group (3–10 people) using IPFS/IPNS as a publish-signed-snapshot workflow for a Markdown collection.

# Workflow rules for SnapStack

## 0) Ground rules (philosophy)

* **Snapshots, not merges.** We publish complete, immutable snapshots (CIDs). We avoid concurrent edits to the same files.
* **One stable pointer.** There is a single “main” IPNS name that always points to the latest accepted release.
* **Low ceremony, just enough structure.** Clear ownership and short checklists replace heavy tooling.

---

## 1) Roles

* **Maintainer of Record (MoR):** owns the *main* IPNS key and publishes accepted releases to it.
* **Contributors:** anyone who proposes a new snapshot (their own CID) for inclusion.
* **Backup Maintainer:** holds an escrow copy of the main IPNS key (sealed) and can rotate if MoR disappears.

> Tip: every contributor may also create a **personal IPNS** key to share work-in-progress or proposals.

---

## 2) Directory & docs (in the repo itself)

```
/ (root of the snapshot)
  /docs/…                # markdown content
  /assets/…              # images, diagrams
  /scripts/…             # helper scripts (publish, validate)
  CONTRIBUTING.md        # how to propose changes (this doc distilled)
  STYLE.md               # headings, links, filenames, TOC rules
  CHANGELOG.md           # human-readable release notes (top entry = tip)
  MANIFEST.json          # machine-readable: CID, parentCID, author, date, summary, version
  LICENSE
  README.md              # what this collection is, how to fetch latest
```

**MANIFEST.json** (one line JSON, easy to diff/view):

```json
{
  "cid": "bafy…", "parent_cid": "bafy…",
  "version": "2025.08.29-1",
  "timestamp": "2025-08-29T16:45:00-07:00",
  "author": "Alice <alice@example.org>",
  "summary": "Fix typos in 03-intro.md; add diagram alt text; linkcheck clean",
  "files_changed": ["docs/03-intro.md", "assets/flow-1.png"]
}
```

---

## 3) Versioning

* **Date-based + counter:** `YYYY.MM.DD-N` (e.g., `2025.08.29-1`). Reset `-N` each day.
* **SemVer is fine** if you think in features; for documents, date-based keeps it simple.
* The **MoR** increments version on publish to *main*.

---

## 4) The happy path (90% of the time)

### A) Prepare your proposal (Contributor)

1. **Sync latest:** resolve main IPNS → `CURRENT_CID`. Fetch/pin and work from that.
2. **Edit locally.** Follow `STYLE.md`.
3. **Self-check:**

   * run `scripts/validate.sh` (spelling, markdown lint, linkcheck)
   * update `CHANGELOG.md` (top entry) and `MANIFEST.json` (leave `cid` empty for now; set `parent_cid` to `CURRENT_CID`)
4. **Build your snapshot:** `NEW_CID=$(ipfs add -Qr .)`
5. **Freeze manifest:** write `NEW_CID` into `MANIFEST.json`’s `cid` field.
6. **Share proposal:** post `NEW_CID` + short summary (and a diff link if you keep a Git mirror—optional).

### B) Review & accept (MoR)

1. **Resolve proposal:** `ipfs get NEW_CID` (or browse via gateway).
2. **Run `scripts/validate.sh`** yourself (don’t trust; verify).
3. **Quick editorial review:** spot-check changed files; ensure `CHANGELOG.md` + `MANIFEST.json` sane.
4. **Publish to main:** `ipfs name publish --key=main-key NEW_CID`
5. **Announce:** post the new version string, `NEW_CID`, and the CHANGELOG entry.
6. **Pin policy:** ask everyone (or your pinning service) to pin `NEW_CID`. Optionally unpin `parent_cid` after grace period.

---

## 5) Light conflict avoidance

* **Soft locks in chat:** “I’m editing `docs/03-intro.md` for the next hour.” Keep locks short; edit small.
* **Small PRs:** prefer small, focused changesets to reduce overlap.
* **If you collide:** the version published to main wins. The other contributor rebases their edits on top of the new main (see §7).

---

## 6) Trust & keys

* **Main IPNS key custody:** stored offline by MoR; escrow sealed copy with Backup Maintainer.
* **Personal IPNS keys:** contributors use these for proposals or personal snapshots.
* **Key rotation:** if compromised, announce rotation, generate new main key, republish latest `NEW_CID` under the new IPNS. Update `README.md`.

---

## 7) Rebasing your local edits (when someone beats you to publish)

1. Note your **work-in-progress CID** (WIP\_CID).
2. Pull latest main → `BASE_CID`.
3. Reapply your changes on top of `BASE_CID` (manual since no merges). Keep edits small; copy over files you changed.
4. Produce a fresh `NEW_CID`, set `parent_cid` = `BASE_CID`, reshare proposal.

---

## 8) Pinning & retention

* **Everyone pins main’s latest CID.** That keeps content reliably fetchable.
* **Remote pinning:** at least one shared pinning service (e.g., community account) + one independent peer.
* **Retention window:** keep the last **5** releases pinned; older ones can be unpinned unless cited.

---

## 9) Quality gates (fast, local)

* **Markdown lint:** headings, links, trailing spaces.
* **Spellcheck:** allowlist project terms.
* **Linkcheck:** external links (skip on flaky networks with a flag).
* **Optional build:** if you generate HTML/PDF from docs, run it locally to catch broken assets.

Put these in `scripts/validate.sh`.

**Example `scripts/validate.sh` (bash):**

```bash
#!/usr/bin/env bash
set -euo pipefail

# 1) markdownlint (install locally or via container)
command -v markdownlint || echo "(!) install markdownlint for full checks"

# 2) basic spelling with codespell if present
if command -v codespell >/dev/null; then
  codespell -q 3 -S "assets/*,node_modules/*,vendor/*"
fi

# 3) rudimentary link check (skip gateways to avoid false negatives)
if command -v lychee >/dev/null; then
  lychee --exclude "ipfs://|ipns://|localhost" --offline false docs || true
fi

echo "✓ basic validation done"
```

---

## 10) Scripts (tiny helpers)

**`scripts/publish_latest.sh` (run by MoR):**

```bash
#!/usr/bin/env bash
set -euo pipefail

KEY_NAME="${KEY_NAME:-main-key}"

# Ensure MANIFEST.json cid matches the tree we’re about to publish
NEW_CID="$(ipfs add -Qr .)"
MANIFEST_CID="$(jq -r .cid MANIFEST.json || true)"

if [[ "$MANIFEST_CID" != "$NEW_CID" ]]; then
  echo "Updating MANIFEST.json cid to $NEW_CID"
  tmp="$(mktemp)"
  jq --arg cid "$NEW_CID" '.cid=$cid' MANIFEST.json > "$tmp" && mv "$tmp" MANIFEST.json
  NEW_CID="$(ipfs add -Qr .)"
fi

echo "Publishing $NEW_CID to IPNS key: $KEY_NAME"
ipfs name publish --key="$KEY_NAME" "$NEW_CID"

echo "Reminder: pin the new CID:"
echo "  ipfs pin add $NEW_CID"
```

**`scripts/adopt_new_release.sh` (for all peers):**

```bash
#!/usr/bin/env bash
set -euo pipefail

IPNS_ADDR="${1:?Usage: adopt_new_release.sh <ipns-name-or-peerid>}"

CURRENT="/ipfs/$(ipfs name resolve "$IPNS_ADDR" | sed 's|/ipfs/||')"
CID="${CURRENT#/ipfs/}"

echo "Latest main CID: $CID"
ipfs pin add "$CID"
echo "✓ pinned $CID"
```

---

## 11) Communications

* **Announce proposals:** `NEW_CID`, 1–2 sentence summary, list of changed files.
* **Announce releases:** version, `NEW_CID`, CHANGELOG excerpt, pin reminder.
* **Parking lot:** if you’ll be offline, note any soft locks you’re dropping.

---

## 12) Backups & mirrors (optional but handy)

* **Git mirror (read-only):** keep a Git repo that mirrors the current tree so reviewers can use normal diffs; store `MANIFEST.json` with the published CID for traceability.
* **CAR exports:** for archival, export a CAR of each accepted CID and stash offsite.
* **Static site mirror:** optionally build and publish HTML to a web host for easy browsing; link back to the authoritative CID.

---

## 13) SLAs & latency expectations

* **IPNS propagation:** “minutes, not milliseconds.” If timing matters, share the **CID** directly in chat first; MoR updates IPNS soon after.
* **Review window:** aim to accept/reject proposals within **24h** (or define your own cadence).

---

## 14) Security & recovery

* **Lost main key:** rotate (new key), publish last accepted `CID` to the new IPNS, update `README.md` and notify.
* **Compromise suspected:** freeze publishes, verify last good CID, rotate keys, resume.

---

## 15) Minimal checklist cards

**Contributor (before proposing):**

* [ ] Based on latest main (resolved today)
* [ ] Edited small, focused scope
* [ ] `validate.sh` passes (or notes recorded)
* [ ] `CHANGELOG.md` & `MANIFEST.json` updated
* [ ] Built `NEW_CID` and shared summary

**Maintainer (before publishing to main):**

* [ ] Fetched and validated `NEW_CID`
* [ ] Changelog sane; manifest fields correct
* [ ] Publish to IPNS (`main-key`)
* [ ] Announce + pin policy enforced

---

if you want, I can drop these files (`CONTRIBUTING.md`, `STYLE.md`, the two scripts, and a starter `MANIFEST.json`/`CHANGELOG.md`) into a ready-to-use skeleton you can `ipfs add -r` right away.

# Optional SnapStack Hashchain

1) “Signed snapshots” (recommended baseline)

Keep MANIFEST.json with cid, parent_cid, timestamp, author.

Sign the manifest (ssh-sig, minisign/age, or GPG). Publish the signed tree to IPFS; update IPNS.

Why it’s enough: anyone can verify the chain (parent_cid links) and the signature on each step.

This is essentially a hash-chain; no extra infra beyond your existing workflow.

2) Add public timestamps (cheap, no new infra)

Feed the CID (or manifest hash) into OpenTimestamps to anchor its existence time into Bitcoin via Merkle aggregation. You get a small .ots proof file that anyone can later verify. 
opentimestamps.org
Bitcoin Stack Exchange

When to add: you want “this snapshot existed no later than <date>” without running a chain.

Suggested “SnapStack” recipe (simple + strong)

Keep the MANIFEST.json with parent_cid chain (as you already planned).

Sign each manifest (team-wide shared policy for keys).

OpenTimestamps the manifest’s SHA-256 and store the .ots next to it. 
opentimestamps.org

(Optional) Also post the tuple {cid, manifest hash, signature} to Rekor so anyone can audit via a public transparency log. 

