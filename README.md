# Discourse Blog

A lightweight, server-rendered blog backed by Discourse topics. Write and revise in
Discuss; read articles on a dedicated blog hostname; reply in a deferred, interactive
Discourse discussion below each article.

## Try the local installation

- Blog: <https://blog.dev.home.arpa/>
- Editorial dashboard: <https://blog-discuss.dev.home.arpa/blog/editor>
- Themes and identity: <https://blog-discuss.dev.home.arpa/admin/plugins/discourse-blog/themes>
- Sample discussion: <https://blog.dev.home.arpa/a-small-home-for-big-ideas#discussion>
- Feed: <https://blog.dev.home.arpa/feed.xml>

Sign in to Discuss with an editorial role (staff by default) to use the dashboard. The local development
shortcut is `/session/admin/become` on the **Discuss** hostname. This shortcut is
not a production authentication mechanism.

The local installation is branded **term-llm**, with a matching community theme,
three product-focused articles, labeled starter discussions, and private drafts.
See [`branding/term-llm/README.md`](branding/term-llm/README.md) for the source,
repeatable development setup, admin controls, and deployment boundaries.

## Features

- Exactly one configured public Blog category; subcategories are not included.
- Separate editorial-only drafts category and native Discourse composer autosave.
- Editorial dashboard with server-side status filtering, title/path search, and
  explicit 30-item Load more pagination.
- An editor-only publication panel on the article's own topic: state, one-click
  publish or correction, an inline summary and diff of pending changes, inline
  article settings, and scheduling, approval, and withdrawal behind a menu.
  Public discussion topics show a thin banner pointing at the private working copy.
- Authenticated blog-layout preview.
- Explicit revision submission, approval, publication, scheduling, and withdrawal.
- Revocable seven-day draft review links with frozen article revisions and private,
  account-free FormKit feedback. Feedback is never published as topic replies; it
  is counted and readable inline in the working copy's publication panel.
  See [External draft review](docs/external-draft-review.md).
- Private working topics, frozen approved revisions, and preserved public discussions.
- Durable paths, including historical date-based paths; automatic 301 aliases when
  changing an article path. Topic title edits never change the published path.
- Excerpts, featured articles, author bylines, reading time, publication/updated
  dates, and card/social images from the topic's first image upload.
- Paginated homepage, searchable archive (titles/excerpts), public tag pages, and
  Markdown About page.
- RSS with stable item identifiers, sitemap, robots, social metadata, and
  `BlogPosting` structured data.
- Blog-primary canonical for the discussion landing page; later discussion pages
  keep their page-specific canonical.
- A configurable paper/ink/accent palette, graphic covers, and Liquid-based
  designs, with bundled Editorial-style and minimal-reference examples under
  `branding/`.
- Separate Settings, Themes, and Identity pages, with focused FormKit editors for named theme drafts, Git imports,
  syntax-highlighted CSS/JavaScript editors, expiring blog-origin previews, and explicit
  activation of immutable snapshots. Editing or pulling a draft never changes readers.
  See [Blog themes](docs/blog-themes.md) for the repository format and workflow.
- Automatic light/dark mode, responsive layouts, and a custom-code safe mode.
- The article requires no Ember boot. Full-app discussion loads near the comments.

## Installation

This first iteration requires a Discourse version with `embed_full_app` support.
It is currently tested against the development checkout accompanying this plugin.

1. Install this directory as `plugins/discourse-blog`, run migrations, and restart
   Discourse using your deployment's normal plugin installation process.
2. Route both HTTPS hostnames to the same Discourse installation/database. Keep
   Discuss as the primary/canonical Discourse hostname. On multisite deployments,
   register the blog hostname as an alias in the database connection's `host_names`
   configuration so the correct database is selected before the plugin runs. The
   plugin preserves its configured hostname after database selection; single-site
   deployments do not need a database hostname alias. DNS/TLS/proxy configuration
   must still preserve the original `Host` header. Do not disable hostname checking
   or forward arbitrary untrusted host headers.
3. Create one public **Blog** category. Suggested permissions: everyone can **See
   / Reply**, staff can **See / Reply / Create**. In Ruby these are `:create_post`
   and `:full`, respectively. Replies must be permitted for the audience you want
   to participate.
4. Create a separate **Blog editorial** category, granting access only to the staff,
   admins, and/or moderators automatic groups. A category open to any other group
   is rejected as the drafts category. Use a different category from core's shared
   drafts feature. Do not use the Blog category's description
   topic as an article.
5. Configure:
   - `discourse_blog_url`: e.g. `https://blog.example.com`, no trailing slash/path.
   - `discourse_blog_category`: the single public category.
   - `discourse_blog_drafts_category`: the private editorial category.
   - `discourse_blog_title`, `discourse_blog_description`, `discourse_blog_about`.
   - `discourse_blog_enabled`: enable after configuration.
6. In **Admin → Customize → Embedding**, add the exact blog hostname. Enable
   `embed_full_app` and `embed_full_app_signin_flow`. Do not enable embedding from
   every origin merely to make this plugin work.
7. Visit `/blog/editor` on Discuss and create your first draft.

The supplied development container already proxies both local hostnames and does
not run hostname-enforcement middleware in development. No core middleware patch
is needed. In production, also make sure a proxy's existing `/robots.txt` or
`/sitemap.xml` handlers do not override the blog routes.

### Local demo provisioning

```sh
bin/rake discourse_blog:demo
bin/rake discourse_blog:seed_community
```

Development only. Configures the local origins, categories, branding, and embedding,
then adds sample articles if their paths do not already exist. Re-running resets
those demo site settings; it does not replace existing article bodies. It never
runs automatically during plugin installation or migration. The separate
`seed_community` task creates 20 marked community topics (16 in a general
discussion category, 4 in the feedback category), across the existing local
authors. It skips per-post rate limits only
for this development-only bulk seed, retains normal creation validation and
authorization, and is idempotent. It does not turn community topics into articles.

## Appearance and custom code

Open **Admin → Plugins → Blog**. **Themes** lists the saved designs and the one
currently shown to readers; **Identity** holds the blog name, tagline, and About
content. A design owns its whole look: palette, CSS, JavaScript, and Liquid
templates. Design and color changes are blog-only; they do not restyle Discuss.

Theme cards use a shared typographic specimen and the saved draft's paper, ink,
and accent colors. These covers are palette samples, not screenshots: they do not
load a draft's CSS, fonts, JavaScript, or templates into the admin page. Use the
card's **Preview** action to see the complete rendered design.

The template editor uses FormKit's custom-control slot with Ace bound directly to
`field.value` and `field.set`. Variable insertion changes the field programmatically;
the stock code control captures only its initial value. Keep this binding local to
the template editor rather than patching core or remounting Ace after insertion.
CSS and JavaScript fields use the stock code control.

Reader pages always load one built-in stylesheet, `blog.css`, which is a plain
reading layout, followed by the active design's CSS. The bundled designs under
`branding/` (for example `branding/term-llm`) show richer layouts built on that
base — large serif typography, graphic covers, and a warm palette.

Each theme draft carries its palette, Liquid templates, and two
syntax-highlighted code editors:

- **Custom CSS** loads after the built-in theme. It applies to reader pages and
  authenticated blog-layout previews. Use plain CSS, not SCSS or style tags.
  It cannot cross the discussion iframe boundary; that surface is tinted with the
  design's palette instead. Further discussion styling belongs in a forum theme,
  scoped to `html.discourse-blog-discussion body.embed-mode`.
- **Custom JavaScript** runs deferred, after the document is parsed, on blog-origin
  pages. It is served as a JavaScript file, so `<script>` markup would be a syntax
  error. To load another script, append the element instead:

  ```js
  const script = document.createElement("script");
  script.src = "https://example.com/widget.js";
  document.head.append(script);
  ```

  The file loads with a CSP nonce and the blog's policy uses `strict-dynamic`, so a
  script it appends runs without allowlisting that origin. The code deliberately does
  **not** run in authenticated previews on the Discuss origin, in normal Discuss
  pages, or inside the cross-origin discussion iframe.

Both are administrator-only and publicly downloadable. They are executable/trusted
customizations, not a place for secrets. Saves go through the theme editor and then
through explicit activation, and are audited in staff action logs.
Each code field is limited to 65,536 characters. Invalid CSS/JavaScript is not
silently repaired: test your code before deploying it to readers.

**Recovery:** open a blog URL with `?blog_safe_mode=1` to skip both custom snippets
for that view. The Identity page links to the blog and to that recovery view, and
remains on the separate Discuss hostname even if a customization breaks the blog.
Clear the relevant code field in the theme editor, save the draft, and activate it
to remove a customization. The built-in theme still loads in safe mode. CSS and
JavaScript assets are uncached so a reload picks up saved changes.

Stable styling hooks include `.blog`, `.blog__header`, `.blog__brand`,
`.blog__intro`, `.blog-card`, `.blog-article`, `.blog-article__body`, and
`.blog-discussion`. The body exposes `data-blog-page`.
The palette exposes `--blog-accent-color`, `--blog-paper-color`, and
`--blog-ink-color`. Both themes also expose `--blog-canvas`,
`--blog-foreground`, `--blog-muted`, `--blog-rule`, and `--blog-link-color`.

```css
.blog-article__body {
  font-size: 1.2rem;
}
```

```js
const brand = document.querySelector(".blog__brand");
brand?.setAttribute("title", "Written in our community");
```

The unbranded demo setup includes small, editable CSS/JS examples to demonstrate that the
customization pipeline is active. Article cover uploads take precedence over a
design's decorative graphic covers.

## Reader templates and the reference design

Reader pages use Liquid templates with optional per-theme overrides. See
[Liquid template authoring](docs/liquid-templates.md). The `samsaffron.com` theme is
bundled under `branding/samsaffron/` and saved on the development blog as a design
that demonstrates a structurally different sidebar layout. Switch themes through the
normal preview/activation interface; no articles or editorial data need to change.

## Editorial workflow

1. **New draft** opens the native composer in the private drafts category. Saving
   the topic does not publish it. Internal replies stay on this private topic.
2. Every draft topic shows an editor-only **publication panel** above the first
   post. It states whether the article is a draft, live, live with pending
   changes, scheduled, or unpublished, and offers one primary action.
3. For an existing public article, the public discussion topic shows a banner
   with **Edit privately**, which creates a private working copy and links to it.
   The existing public discussion and its replies keep their IDs.
4. **Article settings** (path, excerpt, date, featured) are edited inline in the
   panel. **Save settings** stages metadata without changing the live article.
5. **Publish** (or **Publish correction** once live) requires confirmation and
   freezes the current draft and settings as a revision, approves it, and copies
   only that frozen article into a separate public discussion (or updates its
   existing first post). It never moves an editorial topic or copies its replies.
   Contributors and editors see **Submit for approval** instead; a publisher then
   previews the submitted revision and chooses **Approve and publish**.
   Publishers may approve their own work.
6. When a live article's working copy drifts, the panel lists which fields
   changed and can show an inline diff against the live revision. While the
   working copy matches the live article there is nothing to publish, so the
   panel offers only **Options → Unpublish**.
7. The panel menu holds the rarer paths: **Schedule…** freezes the draft as it is
   now and releases it at a local date/time; later edits do not change that
   scheduled release unless it is cancelled and rescheduled. The article's optional
   backdated publication date is separate from its scheduled release time.
   **Submit for approval** is also available to publishers who want a second
   sign-off.
8. **Unpublish** withdraws the blog page and cancels scheduling but leaves the
   public discussion accessible. The legacy return-to-drafts endpoint now has the
   same withdrawal semantics and prepares a private working copy; it never moves
   an existing public discussion.

Old paths become redirects only when their replacement revision is published.
Configure contributor/editor/publisher group settings and native category permissions
as described in [Editorial workflow internals](docs/editorial-workflow.md).

## Privacy and security

- Editorial role, ownership where applicable, and topic visibility are checked server-side.
  Personal messages and topics outside the two configured categories cannot be
  published with this interface.
- The public blog always evaluates **anonymous** visibility, even when an editor
  is signed in. Publication alone cannot expose a restricted, unlisted, deleted,
  or hidden source. The first post must also be visible and regular.
- Articles, listings, feed, sitemap, redirects, and topic canonicals use the same
  publication visibility query. A topic moved out of the Blog category disappears
  from the blog; it can become available again if restored while still published.
- Public responses use `private, no-store` in v1 so visibility revocation takes
  effect on the next request. Do not add a CDN cache without a purge/revocation
  design. Already delivered pages, feeds, screenshots, and search copies cannot
  be recalled.
- Preview is authenticated on Discuss, `noindex` and `no-store`; it does not change
  Guardian permissions or enable anonymous share tokens.
- **Secure uploads and login-required sites are unsupported in this version.**
  Draft text is private, but upload URLs are not access-controlled when secure
  uploads are disabled. Do not put confidential attachments into these drafts.
  Supporting private draft media needs an explicit media-publication design.
- Discourse authentication remains on Discuss. No API key is exposed to the blog
  browser and cookies are not broadened to the parent domain.

## Rendering and discussion scope

Ordinary cooked Markdown/HTML, images, links, tables, quotes, code blocks, native
`details`, and normal media are server rendered. Internal links and media URLs are
made absolute. The stylesheet intentionally does not import the entire Discourse
theme or application bundle.

Complex cooked-content widgets (poll interaction, client-side math, galleries,
syntax highlighting, and arbitrary plugin decorators) are not a complete match
for the full topic renderer yet. The article links to Discuss for that experience.
The full discussion does use the existing Discourse application and its features.

The embed is deferred, not weightless: interaction loads Discourse. It currently
waits for a trusted, post-render readiness message before revealing the iframe,
so the initial unstyled document does not flash against the blog. Script failures
or a 30-second readiness timeout show an accessible fallback instead of leaving
a blank frame. It uses a plugin-managed content-resizing iframe (280px minimum, no maximum height). The iframe expands with its content, including live changes, rather than
creating a second scrolling region. The embedded conversation uses the configured
paper, ink, and accent colors of the active design, which the blog sends to the
frame, with dark-mode support. Styles are scoped
to `html.discourse-blog-discussion body.embed-mode`; ordinary forum pages and
other embeds are unchanged. Historical small-action rows, the topic map, progress counters, redundant topic
footer actions, and development overlays are hidden in this reading view; the full history remains in Discuss.

Existing login, composer, live
updates, moderation, and closed-topic behavior are reused. An **Open in Discuss**
link always remains available. Same-site HTTPS subdomains are the intended v1
setup; unrelated domains and browser storage restrictions need separate testing.

The sitemap currently contains at most 50,000 article entries; very large archives
need a paginated sitemap index before deployment. There is no WordPress importer,
newsletter, subscription system, page builder, or multilingual publishing in this
iteration.

## Development and tests

```sh
bin/rake db:migrate
RAILS_ENV=test bin/rake db:migrate
bin/rspec plugins/discourse-blog/spec/requests/
bin/qunit plugins/discourse-blog/test/javascripts/acceptance/
```

The plugin includes standalone lint configuration. Pass its source files explicitly
to `bin/lint --fix`; do not include `node_modules`. Core's structure/annotation tasks
only include bundled plugins, so this external plugin's schema is carried by its
own migration rather than changes to core's `db/structure.sql`.

See [design notes](docs/design.md) and [live verification](docs/live-verification.md).

### Sample conversations

Run `bin/rake discourse_blog:seed_replies` after setting up the local demo.
This development-only task adds labeled sample replies to all three published
articles using the existing admin, user1, and user2 accounts. It is repeatable
and skips replies already present; it never publishes drafts.

## Compact articles in the forum

Published articles of at least 250 words receive a compact first-post presentation
when viewed as forum topics: the editorial excerpt, a link to the blog, and an
**Expand article here** button. The same button can collapse the article again.
Expansion yields the original cooked-content renderer, preserving code, images,
links, decorators, and normal quoting behavior. Expansion state is retained in the
post's decorator state while its component lives.

The complete raw/cooked post is never replaced or truncated. Short announcements,
unpublished topics, private drafts, blog-layout previews, and embedded discussion
rendering are unchanged. Search/context URLs and article-heading fragment links
show the complete post directly. The existing blog-primary canonical is unchanged.
The presentation uses the `post-content-cooked-html` wrapper outlet; themes can
style `.blog-post-summary` without reaching into cooked article content.

## Finding articles in the editor

`/blog/editor` does not infinitely scroll or download the whole library. It fetches
up to 30 results and offers **Load more** only while another page exists.

The All articles, Drafts, Published, and Not on the blog filters run on the server
before pagination. Not on the blog means discussions in the public publication
category which are not currently live articles; private drafts have their own
filter. Search matches titles, slugs, and stored article paths case-insensitively,
across the entire authorized editorial collection, not just downloaded entries.
Search and status remain active for Load more and Refresh; changing either starts
at the first page. Search input is bounded to 100 characters and SQL wildcards are
escaped. Ordering uses update time and ID, with duplicate rows suppressed when
appending pages if entries move between requests.

The publication panel's settings and schedule forms, theme editor, identity form, and editor search use FormKit. Article
path and excerpt use `@format="full"`, rather than custom input-width CSS. The
public archive's lightweight GET search remains semantic server-rendered HTML;
booting Ember/FormKit there would defeat the no-application-required reader page.

### Theme import and export

The Themes page supports importing a public HTTPS Git repository or a blog theme ZIP
(up to 2 MB and 1,000 archive entries). Both create a new, inactive draft. Export in
the theme editor downloads the **last saved draft**, not unsaved edits or the active
snapshot. Save changes before exporting.

Exports use the same version-2 source layout as Git imports:

- `blog-theme.json`: `version`, `name`, `accent_color`, `paper_color`, `ink_color`
- `blog.css` and `blog.js`
- `templates/{layout,index,article,about,not_found}.liquid`

Empty template files retain the built-in fallback. Archives may contain these files
at the root or inside one enclosing directory. Import applies the same per-file size
and template validation as Git imports; archive contents are never extracted to disk.
Theme IDs, revisions, Git source metadata, activation state, and site identity settings
are not exported. An imported ZIP is an independent draft with no Git connection.
Core Discourse forum theme ZIPs use a different format and cannot be imported here.
