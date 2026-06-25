---
id: field-ordering-matters
repo: terraform-guardium-datastore-va
skills:
  - guardium-registration-flow
tags:
  - json
  - guardium
  - datasource
applies_to:
  - developer
  - qa
  - applier
---

# JSON Field Ordering Matters

## Problem
Some Guardium datasource payload handling is sensitive to field ordering or exact payload structure.

## Guidance
- Preserve known-good field ordering in datasource templates
- Compare failing payloads against working examples
- Treat payload structure as part of compatibility, not just field presence

## Impact
Prevents repeated API failures caused by subtle template formatting differences.