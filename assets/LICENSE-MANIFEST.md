# Asset License Manifest

Tracked record of license verification for every third-party asset pack before it is
promoted from `inbox/` to `assets/`. `inbox/` is git-ignored, so this file is the durable
record that a clean checkout can audit.

| Pack | Source / author | License | Verified on | Evidence | Status |
|---|---|---|---|---|---|
| Warped City | TBD | TBD | — | — | Pending |
| Gothicvania | TBD | TBD | — | — | Pending |

## Promotion rule

- [ ] License text or store-page URL recorded in the `Evidence` column
- [ ] Commercial-use and modification rights confirmed
- [ ] Attribution requirements captured
- [ ] Verified by a human, with the date recorded
- [ ] Original license file copied to `assets/<pack>/LICENSE`
- [ ] Only then copy the pack into `assets/`

Do not promote a pack while its status is `Pending`. If a license changes or a pack is
replaced, add a new row rather than overwriting the previous verification.
