# Blog - SnapStack, 2025-09-05

Attendees: Bill, Pete

## Topics

- clients?
- the Apps Pete has mentioned
- how to get started with the Sharing of the SnapStack vault
- publishing MarkPub-written websites
    - main trick: use relative URLs

Pinata: pinning service
* see other notes about pinning: [Blog - Peter Kaminski, 2025-09-03](https://ipfs.io/ipfs/QmUL4qhBtnRKfTb3Rm4QNN3bQ9dC6DfheePV9791SYo9sZ/blogs/Blog%20-%20Peter%20Kaminski,%202025-09-03.md)

To be aware of
- ipfs is public and potentially eternal by default
- you can implement by privacy by using encryption

trade CIDs on updates

need a better name than "repo" or "vault"

## Pre-SnapStack Workflow

For Pre-SnapStack, we won't use IPNS, so we'll just announce our new CID.

Later, instead of "announce my new CID", it'll be "set the IPNS name to the new CID" and announce that there's a new version of the canonical wiki.

### Push / Add Wiki

- create a repository (just like an Obsidian vault or a Massive Wiki repo), let's call it "MyRepo"
- to "push", add the top-level directory, i.e., `ipfs add -rQ MyRepo`
- get the CID, and share to your friends

### Pull/ Get Wiki

- get to a dir where you can pull the latest version to, where you won't overwrite your current version
- `ipfs get <CID-from-friend>` (`get` is automatically recursive)
- kubo will error out if you try to `get` files that already exist
- (merging your version and the new version is currently left as an exercise)

Pulling a new version of an existing wiki:

- leave your version ("mine") alone
- pull / get the new CID to a new neighboring directory ("theirs")
- create a third merged ("merged") directory from your existing version ("mine") and their new version ("theirs")
- when you're happy with the merged version, if it's different from their version, push / add the merged version and announce the CID (or, maybe make a few changes first, then announce)

