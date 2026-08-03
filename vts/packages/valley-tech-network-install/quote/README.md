# Automated quote (direction)

**Intent:** Site discovery data → **detailed itemized quote** (not vague “notes for pricing”).

| Stage | Status |
|-------|--------|
| `discovery.example.json` schema | v2 scaffold |
| `quote-template.md` manual fill | v2 ready |
| Script: `discovery.json` → filled quote markdown/PDF | **TODO** |
| On-router or laptop collector (interfaces, neighbors, SSIDs via controller API) | **TODO** |

Discovery is for **sales and scoping**. It does **not** perform LAN segmentation on a client PC; segmentation is applied when the **VyOS appliance** is provisioned in the lab.
