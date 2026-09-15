# samsaffron.com reference theme

A version-2 Liquid blog theme reproducing the current samsaffron.com reader layout:
slate header, simple navigation, wide chronological-style post summaries, reference
sidebar links, readable article typography, and a one-column mobile layout.

The local blog name, description, articles, and public discussion remain its own.
The sidebar includes the reference site's external resources, but does not fetch
external activity feeds or install tracking scripts. System fonts intentionally
match the reference's effective fallback without depending on Discourse's delayed
Inter font load.

To import, place `blog-theme.json`, `blog.css`, and `templates/` at a public Git
repository root, then use Blog → Themes → Import from Git. Import creates a draft;
preview and activate separately. Blank optional template files fall back to the
built-in Liquid page. See `../../docs/liquid-templates.md` for the template contract.

Local saved theme ID: `dde33fe8-4766-4551-8129-1eb746e73664`.
The design it replaced is preserved as **term-llm Editorial — before samsaffron.com**
(ID `275908e8-d322-4bc7-a831-20b1210ef5ec`). No identity settings or articles were
changed to install this design.
