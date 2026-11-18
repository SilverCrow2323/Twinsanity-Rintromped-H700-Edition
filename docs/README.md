# Engineering documentation

Player-facing instructions are maintained in the **MuOS-only H700 Field Guide**: [open the guide](../site/index.html).

This directory contains implementation and validation notes for contributors working on the Allwinner H700 / MuOS target.

## Guides

- [H700 / MuOS porting plan](H700_PORTING_PLAN.md) — engineering stages and physical-device acceptance gates.
- [H700 renderer audit](H700_RENDERER_AUDIT.md) — source-level graphics compatibility findings.
- [Launcher screenshots](launcher/screenshots/) — existing launcher captures retained as repository history; they are not presented as MuOS device screenshots.

## Validation rule

The H700 target remains experimental until a physical device report is reviewed. The diagnostic preflight package is not a playable game build. A successful host or CI build is not hardware acceptance.
