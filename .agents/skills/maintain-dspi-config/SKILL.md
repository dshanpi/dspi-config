---
name: maintain-dspi-config
description: Maintain dspi-config board-profile behavior, Overlay configuration, signed APT source management and cohort upgrades or rollback.
---

# maintain-dspi-config

Read root AGENTS.md and [DELIVERY_POLICY.md](../../../DELIVERY_POLICY.md). Run policy checks before editing and the repository hygiene checker after staging. See [the developer handoff](../../../docs/development-handoff.md) for tests and packaging boundaries.

- Read board data from BSP profiles; do not embed board-specific Overlay choices, kernel patches or a competing downloader/publisher in the client.
- Source writes use /run/dspi-config locks and atomic replacement. Preserve Signed-By. Legacy sources.list.d lock files may still be held by another process; do not blindly delete them.
- Upgrade and rollback must pass the complete exact cohort to APT. A version marker alone cannot restore a consistent system. Avoid pipefail/SIGPIPE regressions when consuming apt-cache output.
- README.md is part of the DEB payload. Put maintenance-only notes under docs; changes to packaged content require a new VERSION and corresponding dshanpi-build release metadata. Governance/tests alone may retain VERSION only after a before/after package hash comparison.
- Run bash tests/test.sh and shell syntax checks; the source-lock tests cover four profiles, not four physical boards. Hardware evidence belongs with the pinned release in dshanpi-build.
- Commit implementation separately from evidence, keep release history immutable, and update this skill when a new packaging or recovery invariant is established.
