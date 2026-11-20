# Documentation style guide

**A practical design system for every project guide, manual and GitHub Wiki page.**

The documentation should feel like a product interface, not a wall of plain text. It must remain readable on desktop and handheld screens, usable by beginners and precise enough for developers.

## ✦ Page anatomy

A substantial documentation area should have a recognisable landing page:

1. A project banner or meaningful illustration, with useful alternative text.
2. A clear title and one-sentence explanation.
3. A compact status strip only when the status is real and verifiable.
4. A short page index grouped by task or subject.
5. Dedicated pages, each answering one practical or engineering question.
6. A clear route back to the hub and related topics.

Do not put an entire manual on one page. Split by task, and cross-link related pages.

## 🎨 Visual language

| Element | Convention |
|---|---|
| Page banner | Original SVG/PNG, useful rather than decorative, with strong contrast |
| Main hierarchy | One H1 per page, clear H2 sections, H3 only when needed |
| Status | Neutral wording; badges only for a real, specific state |
| Emoji | A small number of semantic cues in headings, not decoration on every line |
| Tables | Compact comparisons, requirements, statuses and parameter references |
| Diagrams | Mermaid for architecture, flow, lifecycle and decision paths |
| Callouts | GitHub alerts for important notes, warnings, tips and prerequisites |
| Expandable sections | HTML details/summary for optional or advanced material |
| Code | Fenced blocks with the correct language and reproducible commands |
| Images | Descriptive alt text; store source assets next to the documentation topic |

## 🧭 Callout vocabulary

Use GitHub's native alert syntax sparingly:

- `> [!NOTE]` — context that helps understanding.
- `> [!TIP]` — useful shortcut or optional improvement.
- `> [!IMPORTANT]` — prerequisite or fact that changes the next step.
- `> [!WARNING]` — risk of data loss, incompatibility or irreversible action.
- `> [!CAUTION]` — potentially destructive operation.

For this project, use **MUST KNOW!!** within an IMPORTANT / WARNING callout only for a mandatory prerequisite or compatibility boundary. Use **Optional** for enhancements that are not required.

## 🧩 Content patterns

### Requirements

| Requirement | Minimum | Recommended | Notes |
|---|---|---|---|
| Example | Required value | Preferred value | Explain any limitation |

### Procedures

Write numbered steps in the order the reader performs them. Put a verification result after the procedure so the reader knows what success looks like. Keep warnings immediately before the action they affect.

### Architecture and processes

Use Mermaid for flows with multiple stages or decision points. Every diagram should be followed by a short explanation of what is confirmed, what is intended and what remains pending.

### Advanced material

Use collapsible sections for long logs, implementation notes, optional configuration and troubleshooting branches. Never hide a prerequisite or a safety warning inside a collapsed section.

## 🖼️ Asset rules

- Keep documentation assets under a topic folder such as `docs/h700/assets/`.
- Prefer source SVG for clean diagrams and simple illustrations; use PNG for screenshots or raster artwork.
- Never store generated images over the only copy of a user-provided original.
- Give every meaningful image descriptive alt text.
- Avoid text embedded inside screenshots when the same information can be written as accessible Markdown.
- Use consistent proportions and visual identity across related pages.
- Optimise screenshots and images so pages remain usable on mobile connections.

## 📚 Wiki versus engineering docs

| GitHub Wiki | Repository docs |
|---|---|
| Installation and first launch | Architecture and design decisions |
| Disc setup and user data | Build and CI instructions |
| Mod management | API compatibility audits |
| FAQ and troubleshooting | Test protocols and performance reports |
| Player-facing how-to pages | Porting roadmap and source-level notes |

The canonical Wiki source is versioned in `wiki-source/`. The engineering documentation is versioned in `docs/`. Do not maintain competing copies of the same instructions.

## ✅ Quality gate before publishing

- The page answers one clear question.
- The title and opening paragraph tell the reader where they are.
- Steps are complete and reproducible.
- Requirements, optional features and destructive actions are clearly separated.
- Tables and diagrams have explanatory text.
- Images have alt text and internal links resolve.
- Status claims match the latest verified build or device report.
- No private logs, identifiers, access tokens, disc images or copyrighted assets are included.
- Wiki source validation passes with `python tools/validate_wiki.py`.

## Evidence before status

Use explicit evidence levels in engineering documentation:

1. **Source reviewed** — the path and call sites have been inspected.
2. **Compile passed** — the relevant translation units compile.
3. **Link passed** — symbols resolve against the intended target libraries.
4. **Device API passed** — the operation succeeds on physical hardware.
5. **Image validated** — output matches a reference or an agreed visual test.
6. **Gameplay validated** — the real game path works on the target.

Never promote a task to a stronger status without the corresponding evidence.
