# SnapStack: Collaborative Writing with Immutable Snapshots

*A lightweight workflow for small teams to collaboratively maintain document collections using IPFS/IPNS*

## How It Works (The Simple Version)

Imagine you and your friends are writing a book together, but instead of emailing files back and forth, you use a magical filing system:

1. **Every version gets a special fingerprint**: When you save your work, the computer creates a unique "fingerprint" for that exact version. If you change even one word, you get a completely different fingerprint.

2. **There's always a "latest version" pointer**: You have a special bookmark that always points to the newest approved version of your book. When someone makes improvements, you move the bookmark to point to the new fingerprint.

3. **Everyone can keep copies**: Your friends can make copies of any version they want and keep them safe on their computers. The more people who keep copies, the safer your work is.

4. **No mysterious changes**: Because of the fingerprints, you always know exactly what changed between versions and who made the changes.

5. **Take turns, don't step on toes**: Instead of everyone editing at once (which gets messy), you take turns making changes and then everyone agrees on the new "official" version.

That's SnapStack! It's like having a super-reliable, tamper-proof filing system for team writing projects.

## Typical Use Case

SnapStack is designed for **small collaborative writing projects** with 2-5 contributors who don't expect frequent editing conflicts. Think technical documentation teams, research collaboratives, or small publishing projects where:

- Contributors can coordinate informally (chat, email, brief calls)
- Most edits are additive rather than heavily overlapping
- You value cryptographic integrity and decentralized distribution
- You prefer explicit coordination over automatic conflict resolution

This isn't meant for large teams with constant concurrent edits - it's optimized for thoughtful, coordinated collaboration.

## Core Concept

SnapStack treats collaborative writing as **publishing signed snapshots** rather than merging concurrent edits. Think "version control for documents" but with cryptographic integrity and decentralized distribution built in.

### Key Principles

- **Immutable snapshots**: Every version gets a unique cryptographic identifier (CID)
- **One stable pointer**: A single IPNS address always points to the latest accepted version
- **Conflict avoidance**: Coordinate edits rather than merge them
- **Low ceremony**: Simple roles and lightweight processes

## How IPFS/IPNS Enables This

**IPFS** gives you immutable snapshots. Every time you add a folder to IPFS, you get a CID (Content Identifier) that cryptographically matches those exact bytes. Change one file, get a completely new top-level CID.

**IPNS** provides a moving pointer. You publish your current snapshot under an IPNS name, then update that pointer when you have a new version. Collaborators fetch via your stable IPNS address.

**Pinning** controls persistence. Any peer can pin a CID to keep it available, and you can use remote pinning services for reliability.

## Team Structure

### Roles

- **Maintainer of Record (MoR)**: Owns the main IPNS key and publishes accepted releases
- **Contributors**: Propose new snapshots for inclusion  
- **Backup Maintainer**: Holds an escrow copy of the main IPNS key

Everyone can create personal IPNS keys to share work-in-progress or experimental versions.

### Repository Structure

```
/ (root of the snapshot)
  /docs/…                # markdown content
  /assets/…              # images, diagrams
  /scripts/…             # helper scripts
  CONTRIBUTING.md        # workflow rules
  STYLE.md               # formatting guidelines
  CHANGELOG.md           # human-readable release notes
  MANIFEST.json          # machine-readable metadata
  LICENSE
  README.md              # project overview and access info
```

The **MANIFEST.json** tracks the snapshot chain:

```json
{
  "cid": "bafy…", 
  "parent_cid": "bafy…",
  "version": "2025-08-29-001",
  "timestamp": "2025-08-29T16:45:00-07:00",
  "author": "Alice <alice@example.org>",
  "summary": "Fix typos in intro; add diagram alt text",
  "files_changed": ["docs/03-intro.md", "assets/flow-1.png"]
}
```

## Standard Workflow

### Contributing Changes (Contributors)

1. **Sync to latest**: Resolve the main IPNS name to get the current CID
2. **Edit locally**: Make focused changes following the style guide
3. **Self-validate**: Run quality checks (linting, spell-check, link validation)
4. **Update metadata**: Add entry to CHANGELOG.md and update MANIFEST.json
5. **Create snapshot**: Add your folder to IPFS to get a new CID
6. **Propose changes**: Share the CID with a summary of what changed

### Publishing Releases (MoR)

1. **Fetch proposal**: Get the contributor's CID and review the changes
2. **Validate**: Run the same quality checks independently
3. **Editorial review**: Spot-check changes and verify metadata is sensible
4. **Publish**: Update the main IPNS name to point to the new CID
5. **Announce**: Share the new version info and ask everyone to pin it

## Conflict Management

**Prevention over resolution**: Use soft coordination rather than complex merging.

- Announce in chat when editing specific files ("working on intro.md for the next hour")
- Keep edits small and focused to reduce overlap
- If changes collide, the version that gets published to main wins - others rebase on top

**Rebasing process**: Start from the new main CID, manually reapply your changes, create a fresh snapshot.

## The Rebasing Process

When someone else's changes get published to main while you're working, you need to rebase your edits on top of the new version:

1. **Save your work-in-progress CID** for reference
2. **Fetch the new main** by resolving the IPNS address to get the latest CID  
3. **Download the new base** and extract it to a clean working directory
4. **Reapply your changes** on top of this new base - this is manual work, but you can use merge tools to help
5. **Create a fresh snapshot** with the correct parent_cid pointing to the new main
6. **Resubmit your proposal** with the updated CID

### Using Merge Tools for Rebasing

Some contributors find visual merge tools helpful for the reapplication step:

- **kdiff3**: Three-way comparison showing original, new main, and your version
- **meld**: Side-by-side diff with merge capabilities  
- **diffuse**: Lightweight option with good text handling

Set up the comparison as: `[new main] [your original base] [your modified version]`, then manually apply your changes to the new main version.

## Why Not Automatic 3-Way Merges?

SnapStack deliberately avoids automatic merging for several reasons:

**Semantic conflicts**: Merge algorithms can't understand when changes are semantically incompatible even if they don't textually conflict. Human judgment is essential for maintaining document coherence.

**Accountability**: Manual conflict resolution makes it clear who made each decision and why, creating better audit trails for collaborative documents.

**Simplicity**: No complex merge state, no "merge commits", no partially-merged working directories. Each snapshot is clean and complete.

**Cryptographic integrity**: Every CID represents a completely validated state that someone explicitly approved, rather than a potentially untested automatic merge result.

The trade-off is requiring more coordination, but for small teams working on documents (rather than code), this explicit approach often produces better results.

## Versioning and Quality

### Version Scheme

Use date-based versioning: `YYYY-MM-DD-NNN` (e.g., `2025-08-29-001`). Reset the counter each day. The MoR increments versions when publishing to main.

### Quality Gates

Keep validation fast and local:
- Markdown linting for consistent formatting
- Spell-checking with project-specific allowlists  
- Link validation for external references
- Optional builds (HTML/PDF generation) to catch asset issues

## Pinning and Persistence

**Everyone pins the latest main CID** to ensure reliable access. Use both personal nodes and shared remote pinning services for redundancy.

**Retention policy**: Keep the last 5 releases pinned by default. Older versions can be unpinned unless they're specifically referenced.

## Security and Backup

### Key Management

- Main IPNS key stored offline by MoR with sealed backup copy
- Contributors use personal IPNS keys for proposals
- Key rotation process for compromised keys

## Optional SnapStack Hashchain

The basic SnapStack workflow already creates a hashchain through the `parent_cid` links in MANIFEST.json. For teams wanting stronger cryptographic guarantees, here are layered security enhancements:

### Level 1: Signed Snapshots (Recommended Baseline)

Keep your existing MANIFEST.json with `cid`, `parent_cid`, `timestamp`, and `author` fields. Then cryptographically sign each manifest using:

- **ssh-keygen signatures** (`ssh-keygen -Y sign`)
- **minisign/age** for lightweight signing
- **GPG** for traditional PGP workflows

Publish the signed tree to IPFS and update IPNS as usual.

**Why this is sufficient**: Anyone can verify both the hashchain (via `parent_cid` links) and the signature on each step. This creates a tamper-evident audit trail without additional infrastructure.

### Level 2: Public Timestamps (Cheap, No New Infrastructure)

Feed the CID (or manifest hash) into **OpenTimestamps** to anchor its existence time into Bitcoin's blockchain via Merkle aggregation. You get a small `.ots` proof file that anyone can later verify independently.

**When to add this**: You want provable "this snapshot existed no later than `<date>`" guarantees without running your own blockchain infrastructure.

**How it works**: OpenTimestamps aggregates many timestamp requests into Merkle trees, then commits the root hash to Bitcoin. Your `.ots` file contains the Merkle path proving your hash was included.

### Suggested SnapStack Security Recipe

For teams wanting strong but practical security:

1. **Keep the MANIFEST.json parent_cid chain** (you're already doing this)
2. **Sign each manifest** with a team-wide key policy  
3. **OpenTimestamp the manifest's SHA-256** and store the `.ots` file alongside it
4. **(Optional)** Post the tuple `{cid, manifest_hash, signature}` to **Rekor** for public transparency logging

This gives you a cryptographically verifiable, publicly auditable document history using existing free services, with no custom infrastructure to maintain.

## Communications and Expectations

### Announcing Changes

- **Proposals**: Share CID, brief summary, list of changed files
- **Releases**: Include version number, CID, changelog excerpt, and pinning reminder

### Performance Expectations

- **IPNS updates**: Take minutes, not seconds - share CIDs directly in chat for immediate access
- **Review window**: Aim for 24-hour turnaround on proposal acceptance/rejection

## Trade-offs to Consider

**Not real-time collaborative editing**: This works best for teams that can coordinate who edits what, when. It's not Google Docs - it's more like a lightweight, decentralized version control system.

**IPNS propagation delays**: Updates aren't instant. For time-sensitive coordination, share CIDs directly while IPNS catches up.

**Manual conflict resolution**: No automatic merging - humans decide how to reconcile conflicting changes.

## Getting Started

The minimal setup involves installing IPFS (Kubo), initializing your node, adding your document collection to get a CID, creating an IPNS key, and publishing that CID under the IPNS name. Contributors can then resolve your IPNS address to get the latest version and pin it locally.

This approach gives you cryptographically verifiable document versioning with decentralized distribution, while keeping the human coordination simple and lightweight.

## Appendix: Technical Background

### IPFS/IPNS Fundamentals

For those new to IPFS (InterPlanetary File System), here's what you need to understand:

#### Content Addressing (IPFS)

Unlike traditional file systems that use location-based addresses (like `/home/user/document.txt`), IPFS uses **content addressing**. Every file and folder gets a unique identifier called a **CID** (Content Identifier) that's derived from the actual bytes of the content.

**Key properties:**
- **Immutable**: The same content always produces the same CID
- **Verifiable**: You can cryptographically verify that content matches its CID
- **Deduplication**: Identical content shares the same CID across the network
- **Change detection**: Modify even one byte and you get a completely different CID

When you add a folder to IPFS, you get a CID for the entire folder structure. Change any file inside, and the folder gets a new CID (though unchanged files keep their original CIDs).

#### Mutable Pointers (IPNS)

Since CIDs change whenever content changes, you need a way to point to "the latest version" of something. That's what **IPNS** (InterPlanetary Name System) provides.

**How it works:**
- You create an IPNS name (which looks like a long string starting with `k51q...`)
- You can publish any CID to that IPNS name
- Others can resolve your IPNS name to get the current CID
- You can update the IPNS name to point to new CIDs as your content evolves

Think of IPNS like a domain name that always points to your latest content, while CIDs are like specific snapshots.

#### Persistence and Pinning

IPFS is designed as a peer-to-peer network where content stays available as long as someone has it. **Pinning** is how you tell your IPFS node "keep this content available."

**Without pinning:** Content might disappear if no one else has it pinned
**With pinning:** Your node keeps the content and serves it to others who request it

**Pinning strategies:**
- **Local pinning**: Your own IPFS node keeps the content
- **Remote pinning services**: Third-party services (like Pinata or Web3.Storage) keep your content available
- **Collaborative pinning**: Team members all pin the same important CIDs

#### Why This Matters for SnapStack

This foundation enables SnapStack's core benefits:

**Immutable snapshots**: Each version gets a permanent, verifiable CID that can never change
**Stable sharing**: The IPNS address stays the same even as content evolves  
**Decentralized**: No single server controls your content - it's distributed across participating nodes
**Cryptographic integrity**: You can always verify that content hasn't been tampered with

### Glossary

**CID (Content Identifier)**: A unique cryptographic fingerprint for any piece of content. Same content = same CID, different content = different CID.

**Contributor**: A team member who proposes changes by creating new snapshots and sharing their CIDs.

**Hashchain**: A sequence of linked snapshots where each one references its predecessor, creating a tamper-evident history.

**IPFS (InterPlanetary File System)**: A distributed system for storing and sharing content using cryptographic addresses instead of server locations.

**IPNS (InterPlanetary Name System)**: A way to create stable, updateable pointers to IPFS content that changes over time.

**Maintainer of Record (MoR)**: The team member who controls the main IPNS key and publishes accepted versions.

**MANIFEST.json**: A metadata file in each snapshot containing version info, authorship, change summary, and parent snapshot reference.

**Pinning**: The process of telling an IPFS node to keep specific content available and serve it to others who request it.

**Rebasing**: Manually reapplying your changes on top of a newer version when someone else's work got published first.

**Snapshot**: A complete, immutable version of the document collection, identified by its CID.