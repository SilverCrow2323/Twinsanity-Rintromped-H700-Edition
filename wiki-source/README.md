# Wiki source and publishing

The tracked pages in wiki-source/ are the canonical source for the GitHub Wiki. The live Wiki is the practical reading surface for installation, disc setup, mods, FAQs and troubleshooting. Detailed renderer and build implementation belongs in docs/.

## ✦ Page design rules

- Give each practical subject its own page.
- Start with a short explanation of what the reader can do on that page.
- Use clear section headings, short paragraphs, tables and GitHub callout boxes.
- Use MUST KNOW!! only for prerequisites, safety constraints and compatibility limits.
- Use Optional only for enhancements that are not required.
- Keep every claim aligned with the current README, releases and tested hardware evidence.
- Never describe a compile or graphics probe as proof of gameplay.
- Never include disc images, copyrighted game files, private paths or device identifiers.

## First-time activation

GitHub creates the special Wiki repository after its first page is saved.

1. Open the project's [GitHub Wiki](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/wiki).
2. If GitHub has not created the Wiki repository yet, create a page named **Home**.
3. Paste the contents of wiki-source/Home.md and save it.
4. From a local repository clone with Git credentials, run:

~~~sh
sh tools/publish_wiki.sh
~~~

The publisher copies the tracked Markdown pages to the special Wiki repository and pushes them.

## Editing workflow

1. Edit the tracked Markdown file in wiki-source/.
2. Run python tools/validate_wiki.py.
3. Check every internal link and factual claim.
4. Commit the page to the project branch.
5. Publish with sh tools/publish_wiki.sh from a local authenticated clone.

Do not edit only the live Wiki: the tracked source is canonical.
