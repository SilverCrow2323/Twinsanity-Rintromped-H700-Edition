# Wiki source and publishing

The tracked pages in `wiki-source/` are the canonical source for the GitHub Wiki. The live Wiki is the reading surface for practical player guides, FAQs and troubleshooting.

## Page rules

- Give each subject its own page.
- Start with a short explanation of what the subject is and when it is useful.
- Use one concept per bullet.
- Use **MUST KNOW!!** only for required prerequisites, safety constraints and compatibility limits.
- Use **Optional** only for enhancements that are not required.
- Leave basic concepts unlabelled.
- Keep internal implementation details in `docs/`; keep the Wiki focused on using the game.
- Keep all platform claims aligned with the README, release notes and tested builds.
- Mark the H700 port as unvalidated until there is device evidence.

## First-time activation

GitHub creates the special Wiki repository after its first page is saved.

1. Open the project's Wiki.
2. Create a page named **Home**.
3. Paste the contents of `wiki-source/Home.md` and save it.
4. From a local clone with Git credentials, run:

```sh
sh tools/publish_wiki.sh
```

The publisher copies the tracked Markdown pages to the special Wiki repository and pushes them.

## Editing

- Edit the tracked files here, not only the live Wiki.
- Use extension-free page links.
- Keep pages short and actionable.
- Do not upload disc images, copyrighted game files, private paths or device identifiers.
