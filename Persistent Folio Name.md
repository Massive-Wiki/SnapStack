# Persistent Folio Name

_This page was mostly written by Claude Sonnet 4.5 in 2025-10, under the supervision of Peter Kaminski. Peter Kaminski takes responsiblity for its content._

For your information, the page [[IPNS name]] is a bridge from early SnapStack documents that use that phrase and the newer discussion here of "Persistent Folio Name".

## The Persistent Name Goal, and IPNS Solution

Content-addressed systems like IPFS generate new hashes whenever content changes. For mutable websites or applications, this means the address changes with every update. IPNS (InterPlanetary Name System) was designed to solve this by providing persistent addresses that point to changing content, but implementing reliable IPNS in practice reveals significant operational challenges.

## The IPNS Republishing Problem

IPNS records expire and require periodic republishing (typically every 24 hours). Unlike IPFS content pinning, which has mature infrastructure and commercial services, IPNS republishing services are scarce. The IPNS record itself must be actively maintained by a node that has the private key, creating an availability requirement that contradicts IPFS's goal of decentralized persistence.

Standard IPFS pinning services don't solve this. They keep your content available but don't handle IPNS republishing. You can pin content at `/ipfs/Qm...` but your `/ipns/k51...` pointer still needs active republishing.

## Current Solutions

### 1. Self-Hosted Persistent Node

Run your own IPFS node that stays online 24/7 and handles IPNS republishing automatically.

**Pros:**
- Full control
- No third-party dependencies
- Free (after infrastructure costs)

**Cons:**
- Requires persistent infrastructure (VPS, home server, etc.)
- Monitoring and maintenance overhead
- Single point of failure unless you implement redundancy
- Must secure the IPNS private key

**Publisher ease: Low** | **Persistence: Medium** | **Management: High**

### 2. w3name

Web3.Storage's IPNS republishing service provides managed IPNS records.

**Pros:**
- Managed service handles republishing
- API-driven updates
- No infrastructure to maintain

**Cons:**
- Single vendor dependency
- Service continuity risk
- API integration required
- Potential costs or rate limits

**Publisher ease: Medium** | **Persistence: Medium** | **Management: Low**

### 3. DNSLink

Use a TXT record in DNS to point to IPFS content. Format: `dnslink=/ipfs/Qm...` or `dnslink=/ipns/k51...`

**Pros:**
- Leverages existing DNS infrastructure
- Mature, well-understood technology
- Many DNS providers and automation options
- Can be automated via DNS APIs
- Human-readable addresses (your.domain instead of hashes)

**Cons:**
- Requires domain ownership
- DNS centralization (registrar and nameserver dependencies)
- Not truly decentralized
- Propagation delays (though typically seconds to minutes)
- Annual domain renewal

**Publisher ease: High** | **Persistence: High** | **Management: Low**

### 4. ENS (Ethereum Name Service)

Blockchain-based naming system that can point to IPFS content via contenthash records.

**Pros:**
- Decentralized and censorship-resistant
- No servers to maintain
- Human-readable names (yourname.eth)
- Record updates are permanent until changed

**Cons:**
- Requires Ethereum wallet and ETH for gas fees
- Transaction costs for every update
- Learning curve for blockchain interaction
- Requires ENS-compatible tools/browsers or gateways
- Annual ENS name renewal (blockchain transaction)

**Publisher ease: Low** | **Persistence: High** | **Management: Medium**

## The Reality: No Perfect Solution

Each approach sacrifices something:

- **Self-hosted nodes** give control but require constant maintenance
- **w3name** reduces management but introduces vendor lock-in
- **DNSLink** is practical but defeats decentralization
- **ENS** is decentralized but adds cost and complexity

For most publishers prioritizing ease and persistence over ideological purity, **DNSLink emerges as the pragmatic choice**. It uses boring, reliable DNS infrastructure and can be automated with any DNS provider's API. Yes, it's centralized—but it's centralized on infrastructure that already exists, that you already understand, and that has decades of operational maturity.

For projects where decentralization is paramount and costs are acceptable, **ENS** provides the most decentralized option, though updates require blockchain transactions.

The uncomfortable truth is that truly decentralized, low-maintenance, easy-to-use persistent addressing remains unsolved. IPNS was the vision, but its execution requires infrastructure that undermines its goals. The ecosystem isn't ready or widely available yet. Until IPNS republishing becomes as commoditized as content pinning, we're left choosing which compromises we can tolerate.

## Practical Recommendation

**For most use cases:** Start with DNSLink using a DNS provider with API support (Cloudflare, Route53, etc.). Automate updates via CI/CD or deployment scripts. Accept the DNS centralization as a reasonable tradeoff.

**For decentralization-critical projects:** Use ENS and budget for gas fees. Implement update batching to minimize transaction costs.

**If vendor lock-in is acceptable:** w3name provides the easiest managed IPNS option, assuming the service remains available.

**Only if you have ops capacity:** Run your own IPFS nodes with monitoring, backups, and ideally geographic redundancy.

The state of the art is, as of late 2025, still evolving. Persistent addressing in decentralized systems is harder than it looks.