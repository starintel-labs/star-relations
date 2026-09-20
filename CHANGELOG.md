# Changelog

## 0.1.0 - 2026-09-19

Initial bootstrap of `org.starintel/relations@1` (version 1.0.0).

- `spec/starintel-relations.star`: self-contained star-lang spec library
  with a minimal `base` document, root `document` kind, 15 thin marker
  documents (person, org, host, domain, file, network, network-device,
  wireless-network, wireless-station, pcap-capture, network-conversation,
  breach, location, user, source), the `relation-direction` enum, the 26
  frozen live OSINT predicates, and 16 new network/capture/leak relation
  predicates.
- `lock/starintel-relations.lock.json`: sha256 digest sidecar.
- `scripts/verify-local.sh`: lock-digest, structural, and star-lang
  compiler verification gate.
- README.org taxonomy tables with inverse/symmetric/transitive
  annotations and the `org.starintel/core@1` import swap plan.
