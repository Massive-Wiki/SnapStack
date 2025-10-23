# MANIFEST

This is a crude prototype of the `MANIFEST.json` file that was represented in the early SnapStack specifications. It uses Markdown syntax rather than JSON, to be easier for humans to maintain.

After the manifest concepts are proven, we look forward to automating the manifest generation and deciding whether to use Markdown (more human-friendly) or JSON (more certainty around parsing).

(WLA-2025-10-22): is "yaml" an option?

Note in the early SnapStack docs, `cid` was specified as the first field. Obviously that's not practical, because when generating a CID it's nearly impossible to include the CID as part of the content to hash. Let's try replacing the `cid` field with a randomly generated UUID, as shown below.

(Geeky note: It *would* be possible to specify a random CID and then twiddle some additional bits to "mine," bitcoin-style, a set of bits that would make the CID work out, but it would take a lot of compute to do that.)

Tips:
- to get ISO 8601 date on a Mac (local timezone)
	- `date +"%Y-%m-%dT%H:%M:%S%z" | sed -E 's/([+-][0-9]{2})([0-9]{2})$/\1:\2/'`
- one source for v4 (random) UUIDs: <https://www.browserling.com/tools/random-uuid>

(WLA-2025-10-22): on macOS `date -Iseconds` yields the same ISO data format

Content below should be updated whenever we're about to publish and obtain a new CID. It's currently updated by hand, please be tolerant of human errors, e.g., `parent_cid` may be wrong.

## Manifest

- **uuid**: 1f346843-650b-4d92-a958-55343d76e772
- **parent_cid**: Qmc4siKRESDcbDed9HPcfSZo7CA9L9PwAX3UbnTz9vdszA
- **version**: 2025-10-22-001
- **timestamp**: 2025-10-23T07:48:24-05:00
- **author**:
	- Peter Kaminski [kaminski@istori.com](mailto:kaminski@istori.com)
	- Bill Anderson [band@praxis101.net](mailto: band@praxis101.net)  
- **summary**: Edits and copyedits on "MANIFEST" and "Persistent Folio Name; update "Manifest" content
- **files_changed**:
	- MANIFEST.md
	- Persistent Folio Name.md
- **files_added**:
