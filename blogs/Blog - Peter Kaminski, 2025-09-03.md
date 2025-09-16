# Blog - Peter Kaminski, 2025-09-03

## Published to IPFS!

First publication of SnapStack docs to IPFS!

CID: QmPWweP44kueHdDzJyEd6KTv6rqj2rrgHWSJNAjNsyFJey

The docs are pre-release and really rough, but I wanted to share them with Bill Anderson, and of course, IPFS is the way to go.

## ipfs add: no dotfiles?

I'm using Obsidian to maintain this repository, so I wanted to ignore the `.obsidian` directory. I used the `--ignore-rules-path` flag and set it up to read `.gitignore`, but `ipfs add` also didn't add `.gitignore` or the `.snapstack` directory I set up (with a helper script for adding). So, it appears to ignore all dotfiles.

## Pinning

As soon as the docs were up, my thoughts turned to pinning. As of 2025-09-03, the services I found:

- Pinata
	- $20/month, generous free tier, but web dashboard doesn't allow pin-by-CID for non-paid accounts
- Filebase
	- $20/month, generous free tier
- web3.storage, transitioning to Storacha
	- Looks fancy and cool, but it was complicated to figure out how to pin by CID
	- Also, it's a little hard to tell what's Storacha, what's web3.storage, what's w3up, etc. as they go through integration / rebrand.

At some point, we might want to run a community IPFS node for pinning.

The services that didn't resonate:

- Infura (now part of MetaMask): "Restricted access - New IPFS key creation is disabled for all users. Only IPFS keys that were active in late 2024 continue to have access to the IPFS network." <https://docs.metamask.io/services/reference/ipfs/>
- Fleek: Complicated by other services (compute, AI agent hosting, web app hosting, etc.)
- Temporal - dead for years
- Eternum - dying or dead

I ended up pinning through Pinata's API. ChatGPT gave me v1 API commands (v3 is apparently the latest):

Pin by CID
```bash
curl --request POST \
  --url https://api.pinata.cloud/pinning/pinByHash \
  --header 'Authorization: Bearer <your_pinata_jwt>' \
  --header 'Content-Type: application/json' \
  --data '{
    "hashToPin": "QmYourCID"
  }'
```

To get your JWT, sign into Pinata, then click on [API Keys](https://app.pinata.cloud/developers/api-keys) in the left nav.

Check job status
```bash
curl -s --request GET \
  --url "https://api.pinata.cloud/pinning/pinJobs?ipfs_pin_hash=QmPWweP44kueHdDzJyEd6KTv6rqj2rrgHWSJNAjNsyFJey" \
  --header "Authorization: Bearer <YOUR_JWT>"
```

Pin by CID, provide host nodes (if status is "searching" for a long time)
```bash
# get your node’s multiaddrs
ipfs id | jq .Addresses

# re-submit with hostNodes
curl --request POST \
  --url https://api.pinata.cloud/pinning/pinByHash \
  --header "Authorization: Bearer <YOUR_JWT>" \
  --header "Content-Type: application/json" \
  --data '{
    "hashToPin": "QmPWweP44kueHdDzJyEd6KTv6rqj2rrgHWSJNAjNsyFJey",
    "pinataOptions": {
      "hostNodes": ["/ip4/…/tcp/4001/p2p/…", "/dns4/…/tcp/443/wss/p2p/…"]
    }
  }'
```

I got back `{"count":0,"rows":[]}` from `pinJobs` when it completed. The repository showed up in my Pinata dashboard.