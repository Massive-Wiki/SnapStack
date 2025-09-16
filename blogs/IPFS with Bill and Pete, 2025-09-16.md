# IPFS with Bill and Pete, 2025-09-16

## What's a folio?

We're using "folio" to refer to a group of files in a folder and subfolders. The same thing as a "wiki" in Massive Wiki, or a "vault" in Obsidian, or a "repo" in Git.

## Publishing a folio (quickstart)

- run your local IPFS daemon so you have an IPFS node running
- do `ipfs add` of your folio top-level folder to get a CID
- pin the CID with a pinning service like Pinata
    - requires an "pin by CID" or "upload from IPFS" facility in the pinning service
    - for Pinata, we do this via an API call via `curl` or other means
- confirm that the CID is pinned
- at this point, the pinning service has taken responsibility for sharing the folio, and if your IPFS node goes offline (because you stop it, or your computer goes to sleep, etc) your folio is still available
- share the CID

## Publishing a folio directly with a pinning service

Pinning services usually have a way to upload your folio to their service, and then you'll get a CID that way.

This is convenient, but not as general, so we prefer to teach people the "Publishing a folio (quickstart)" method.

## How to share a published folio

For people who don't know what IPFS is, it's often best to share a web URL they can use to view or download your folio.

Here are some fairly canonical gateways:

* **ipfs.io** — the original public IPFS gateway, run by Protocol Labs.
  Example: `https://ipfs.io/ipfs/<CID>`

* **dweb.link** — a public IPFS gateway maintained by the IPFS Foundation.
  Example: `https://dweb.link/ipfs/<CID>`

The next step up the learning curve is to let people know:

- Folios (and any information in IPFS) can be retrieved via "gateways", which work like web sites on the viewing side, and know how to retrieve data from IPFS.
- Gateways are more or less interchangeable.
- That a CID is a unique identifier for a folio. (In SnapStack, we'll also use IPNS to make the identifier persistent over versions.)
- With these data points, you can share one or two gateways URLs and the CID; hopefully your recipient will notice how URLs are constructed from the gateway prefix and the CID.

