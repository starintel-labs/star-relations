# star-relations agent contract

- This repository holds declarative star-lang relation rules only
  (`spec/*.star`) plus documentation and verification glue. No runtime
  code lives here.
- star-lang is a closed parser: only `spec-library`, `import`, `scalar`,
  `enum`, `document`, `predicate`, and `message` heads exist. Never invent
  syntax; check the local star-lang checkout when unsure.
- Document field names are ASCII lower camelCase. Predicate identifiers
  are snake_case relation names from the live OSINT vocabulary and are
  frozen.
- Imports need exact name@version plus a full `sha256:<64hex>` digest.
  Until `org.starintel/core@1` publishes with a real digest, this library
  stays self-contained (minimal `base`/`document` plus thin markers); see
  the swap plan in README.org.
- Run `scripts/verify-local.sh` before committing spec changes, and
  refresh `lock/starintel-relations.lock.json` whenever the `.star` file
  changes.
