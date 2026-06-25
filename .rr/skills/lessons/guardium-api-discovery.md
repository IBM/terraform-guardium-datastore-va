---
id: guardium-api-discovery
repo: terraform-guardium-datastore-va
skills:
  - guardium-registration-flow
tags:
  - guardium
  - api
  - datasource
applies_to:
  - developer
  - qa
  - applier
---

# Guardium API Discovery First

## Problem
Datasource registration failures are often caused by undocumented or non-obvious API expectations.

## Guidance
- Inspect actual API behavior before assuming template correctness
- Validate payload shape, required fields, and accepted values
- Use API findings to drive template fixes

## Impact
Shortens debug cycles for datasource registration issues.