# term-llm community and blog

This is the editable source for the local term-llm brand, not a production deployment.
No DNS, certificate, external hosting, or `term-llm.com` content was changed.

## Story and identity

**Open source. Terminal-first. Browser-ready.** The community is a workshop for
questions, reproducible workflows, and contributions. The blog explains practical
workflows and trade-offs rather than inventing launch announcements or adoption.

Brand sources checked:

- <https://term-llm.com/>
- <https://term-llm.com/getting-started/providers-and-setup/>
- <https://term-llm.com/guides/web-ui-and-api/>
- <https://term-llm.com/reference/built-in-tools/#approval-modes>
- <https://github.com/SamSaffron/term-llm>
- Official CSS: `docs-site/static/styles.css` in that repository.
- `favicon.svg` is the official asset from <https://term-llm.com/favicon.svg>.

Light: off-white `fcfcfa`, ink `222b28`, green `16634e`.
Dark: `171c1a`, text `e1e8e2`, green `98d5b2`.
System sans and local monospace fonts; no external font requests. The `>_` mark,
terminal artwork, and understated green surfaces connect the two sites.

## Files and admin controls

- `theme/`: standalone Discourse theme, installed as **term-llm Community**.
  Change CSS, templates, translated hero copy, navigation destinations, and light/
  dark palettes through **Admin → Appearance → Themes**. Local theme ID: `1`.
  <https://blog-discuss.dev.home.arpa/admin/customize/themes/1>
- `blog.css` and `blog-theme.json`: a Git-ready blog design. Copy both to a repository
  root, or edit a draft through **Admin → Plugins → Blog → Themes**.
  Save, preview, then explicitly activate; the brand needs no custom JavaScript.
  The setup task saves and activates a managed blog theme with this design.
  See [Blog themes](../../docs/blog-themes.md).
  <https://blog-discuss.dev.home.arpa/admin/plugins/discourse-blog/themes>
- `content.json`: three articles, example replies, and 20 starter-topic outlines.
  Edit actual articles and discussions in Discourse; authoring stays native.
- The community favicon is shared by the blog. Palette controls flow into the
  blog embed; arbitrary blog CSS/JS still cannot cross the account-origin iframe.

The brand does not hide developer tools globally. Use the development toolbar's
own controls when you want a clean screenshot. The embed hides its developer
chrome because it is a reader surface.

## Repeatable development setup

Prerequisites: the blog demo and its 20 seeded community topics must already exist.
The original setup commands are `discourse_blog:demo`,
`discourse_blog:seed_community`, and `discourse_blog:seed_replies`.

```sh
bin/rake discourse_blog:brand_term_llm
```

This task preflights the required seed before making changes. It:

1. Imports/updates the same named theme and assigns its light/dark palettes.
2. Sets the theme's blog link from the configured blog origin.
3. Sets site/blog copy, palette, favicon, About page, and blog custom CSS.
4. Replaces the redundant built-in welcome banner with the theme hero.
5. Organizes Blog, Help, Workflows, Feedback, and Development; retains
   the same blog-publication category ID and the staff-only draft category.
6. Revises the known demo articles and starter topics through the post revisor.
   New article paths keep aliases for their old addresses.
7. Revises only replies marked as seeded examples; other replies are preserved.
8. Updates the default welcome topic and default sidebar categories. Existing user
   sidebar preferences are not overwritten.

**This intentionally overwrites branded settings, theme files, and seeded copy.**
It is a setup/reset task, not a synchronization or deployment tool. Save admin
edits back into these source files before rerunning it. Reload open browser pages
after importing a theme; development hot reload can otherwise retain stale CSS.
Private drafts remain private. No accounts were invented and example discussions
are labeled; this is not evidence of real community activity.

## Checks

```sh
bin/rspec plugins/discourse-blog/spec/requests/
bin/qunit plugins/discourse-blog/test/javascripts/
node --test plugins/discourse-blog/test/browser/discussion-loader.test.mjs
```

Browser checks covered public desktop and mobile dark community pages, matching
blog pages, embedded discussion footer controls, theme admin settings, and iframe
readiness. A recorded first-paint trace showed the iframe hidden at 319ms and
visible at 990ms, with the blog background staying `rgb(252, 252, 250)`.
The loader tests reject wrong-origin/wrong-frame messages and cover script failure
and the readiness timeout. The iframe has no maximum height and grows with live content changes; it no
longer forces an internal scrollbar. Profile very large threads before production.

Before production, decide the community/blog hostnames, update configuration and
links, review the copy, remove development seed labels/content as appropriate,
and separately configure DNS, TLS, mail, authentication, backups, and abuse controls.

## Design review: typography and scrolling

The first pass over-tightened a monospace wordmark with `-0.06em` tracking.
Monospace brand text now uses normal tracking; the prompt mark has an explicit
0.5em gap rather than a trailing text-space. Blog and forum use the same 24px,
700-weight wordmark with a slightly smaller prompt mark.

The oversized blog title was also over-tightened (`-0.075em`). It now uses natural
monospace spacing and a smaller responsive display size. Sans-serif editorial
headings use modest negative tracking rather than the logo's styling. The mobile
community hero keeps its command example but removes the repeated terminal note
and reduces panel padding so the topic list appears sooner. Muted discussion
controls receive stronger contrast without changing active reaction colors.

For a design-only refresh (does not rewrite articles or starter topics):

```sh
bin/rails runner plugins/discourse-blog/branding/term-llm/apply-design.rb
```

This replaces the Discourse theme's source and re-saves the blog design from
`blog.css` and `blog-theme.json`, then activates it. Save any admin edits back
into the source first. Reload open pages afterward.

The former iframe height cap and forced `scrolling=yes` produced a second
scrollbar. The cap is removed, scrolling is automatic, and a scoped observer keeps
sending updated content heights after the initial core resize notifications stop.
A 320px-wide browser check grew from 1626px to 1722px and back to 1626px while the
frame always matched its content. No overflow is hidden to fake this result.

Iframe-only reloads can lose the server-rendered embed class because the request
referrer changes. The client restores the cosmetic class only when embed mode and
the exact blog class marker are requested, with the plugin enabled. This keeps
the single-column layout after development reloads without changing framing or
authorization. Regression coverage checks the restored class and palette.

### Reading width

The article and entire discussion (heading, replies, and composer) share
`--blog-reading-width`. The built-in base sets 720px and this design's CSS raises it
to 760px. The discussion no longer expands to a separate 960px column. Override this
single property in blog custom CSS to adjust both surfaces together. Mobile remains
fluid.

## Category structure

| Public category | Purpose                                                         | Who can start topics?    |
| --------------- | --------------------------------------------------------------- | ------------------------ |
| Blog            | Staff news, releases, and blog articles                         | Staff; members can reply |
| Help            | Setup, troubleshooting, model/provider connections, permissions | Members                  |
| Workflows       | Reproducible agents, prompts, shell pipelines, MCP, widgets     | Members                  |
| Feedback        | Feature proposals, usability, and community improvements        | Members                  |
| Development     | Reproducible bugs, contributions, tests, and documentation      | Members                  |

No subcategories yet. Separate by the reason for posting, not by every provider or
interface. Use Help for uncertainty, Development for a reproducible defect, and
Feedback for a proposal. Existing Staff and Blog editorial permissions remain private.

```sh
bin/rake discourse_blog:organize_term_llm
```

This development-only operation can be rerun independently of branding without
rewriting article/reply bodies. It moves Providers discussions to Help, moves the
seeded feature-proposal topic to Feedback, and removes only the empty Providers and
General categories. Their category URLs redirect to Help. Site Feedback becomes
Feedback; Blog keeps its name, ID, and publication setting.
It aborts if General gains discussions or a public target is actually private.

Uncategorized is disabled, and there is no default composer category: members
choose where to post. The built-in Uncategorized record is retained, not deleted.
The local database had lost its built-in category reference (`-1`); setup repairs
that reference so the existing core hiding/creation rules work correctly.
Public ordering and sidebar defaults match the table. Personal sidebar choices
are not overwritten. The full branding task applies this structure as its final
step, so subsequent setup does not recreate the old public buckets.
