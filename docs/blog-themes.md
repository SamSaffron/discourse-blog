# Blog themes: drafts, Git, preview, and activation

Manage designs at **Admin → Plugins → Blog → Themes**. Blog themes are independent of Discourse community themes: the reader is server-rendered and does not boot Ember or execute Discourse theme modules.

## Navigation

The plugin has three sections: **Settings** (configuration), **Themes** (the design list), and **Identity** (name, tagline, About content). The Themes index contains no forms or code editors: each design is a card with a preview built from its own palette, its saved revision, badges for the live design and for local Git edits, an **Edit** button, and a menu for previewing the saved design, activating, pulling from Git, and deleting. Activate and Delete are unavailable on the live design. Clicking a theme opens `/admin/plugins/discourse-blog/themes/:id/edit` with only that theme's form and a **Back to themes** link, following the focused admin editor pattern. Creation and Git import have separate pages. The list and identity pages keep the standard admin breadcrumb trail and end it with the current page. JavaScript and Git-source controls are collapsed until needed. FormKit warns before navigating away from unsaved edits.

The old `/admin/plugins/discourse-blog/appearance` bookmark redirects to the Themes index. Saved designs, revisions, active snapshots, and preview behavior are unchanged by this navigation split.

## Workflow

1. **New theme** opens a dedicated creation page and copies the design currently shown to readers.
2. Give it a name and edit the palette, CSS, plain JavaScript, and Liquid templates with the FormKit editor.
3. **Save draft** persists a new draft revision without changing the live blog.
4. **Preview draft** opens the working preview on the blog origin, including unsaved changes. Navigation, archive search, and article links retain the preview, and changing the page or sample article re-previews it. A card's **Preview** instead opens that design's saved revision, which needs no activation.
5. **Activate saved draft** asks for confirmation, then copies that exact revision into the active snapshot. Subsequent edits and Git pulls do not affect readers.
6. Switch to another saved theme and activate it to change designs. **New theme** also lets you preserve the active revision before replacing a draft.

The built-in design remains the live fallback until the first activation. After activation, the saved snapshot owns the palette, CSS, JavaScript, and templates. Sites that only ever configured the removed appearance settings keep their look: the upgrade carries that design into an activated theme. Blog name, tagline, and About content remain global identity settings, saved separately and applied immediately.

Up to 30 named themes are supported. Deleting an active theme is blocked. Draft saves, Git pulls, activation, and deletion are audited in staff action logs. Revision checks reject stale saves or activation from another editor tab.

## Liquid templates

Built-in reader pages now use Liquid, and themes can override the layout,
homepage/archive, article, About, and not-found templates. Each template has its own
tab next to **Design**, starting from its visible built-in source.
**Preview draft** renders unsaved changes without saving or activating, and
**Variables and examples** opens a searchable reference with public sample data and
insertion controls. Blank overrides use the
built-in version. Saving and immutable activation remain separate actions.
See [Liquid template authoring](liquid-templates.md) for the data contract, automatic
escaping, resource limits, safe-mode fallback, and authenticated-preview boundary.

The bundled `branding/samsaffron/` theme demonstrates a structurally different
layout with a sidebar. Theme CSS/HTML do not alter the public/private publication
workflow or the core-owned discussion embed.

## Git repository format

Use **Import from Git** with a public HTTPS repository URL and an optional branch (blank uses the repository default). Put these files at the repository root:

```text
blog-theme.json    # required, up to 4,096 bytes
blog.css           # optional, plain CSS, up to 65,536 bytes
blog.js            # optional, plain JavaScript, up to 65,536 bytes
```

Example `blog-theme.json`:

```json
{
  "version": 1,
  "name": "My reading theme",
  "accent_color": "16634e",
  "paper_color": "fcfcfa",
  "ink_color": "222b28"
}
```

Colors are exactly six hexadecimal digits, without `#`. Version 2 additionally imports optional `templates/{layout,index,article,about,not_found}.liquid` files, each up to 65,536 bytes. Version 1 remains supported. Theme names have a 100-character limit. Unknown manifest fields are ignored. CSS loads after the base stylesheet. JavaScript is deferred and must not contain `<script>` tags or depend on the Discourse/Ember runtime. There is no build step, Sass compiler, dependency installation, or repository-provided command execution. Build source locally and commit the generated plain files if needed.

Use `.blog`, `.blog__header`, `.blog-card`, `.blog-article`, and `.blog-discussion` selectors. Palette variables are `--blog-accent-color`, `--blog-paper-color`, and `--blog-ink-color`. Custom CSS cannot cross into the Discourse conversation iframe. Repository-relative assets are not deployed; reference absolute HTTPS asset URLs when needed. Never put secrets into theme code.

The bundled term-llm example is in `branding/term-llm/blog-theme.json` alongside its `blog.css`. Copy these files to a repository root to use it as a Git source.

Imports create drafts only. **Pull latest from Git** refreshes the saved draft from its stored URL/branch and records the commit SHA. It asks before replacing local edits and leaves the active snapshot alone. A failed import, oversized file, or stale revision leaves the previous draft intact. Git credentials and private repositories are not supported by this initial workflow; URLs containing credentials or query strings are rejected.

## Preview security and recovery

- Working previews store unsaved form snapshots in Redis for 15 minutes, retaining only the latest three per administrator. They do not modify saved drafts or the active theme. Unlike saved-draft previews, their expiry is independent of draft revisions.

- Saved-draft preview links are signed bearer capabilities, valid for one hour. Anyone with the link can view the design; do not share one unintentionally. Reload the theme editor to obtain a fresh link.
- Saving a new draft revision or deleting the theme invalidates previous saved-draft preview links. Expired, tampered, or superseded links fail closed.
- Preview assets require the same capability. Previews use `no-store`, `noindex, nofollow`, and `Referrer-Policy: no-referrer`.
- Theme previews only show already-public articles. They do not grant access to private drafts or restricted topics.
- Custom JavaScript runs on the dedicated blog origin, including theme previews. It never runs in authenticated article previews on the Discuss origin.
- `?blog_safe_mode=1` omits custom CSS and JavaScript, including when combined with a theme preview. The admin appearance page is unaffected by blog theme code.

## Implementation notes

`BlogTheme` stores bounded named drafts, the active copy, and the 20 most recently activated immutable asset snapshots in PluginStore. HTML pins stylesheet and script URLs to a retained activation snapshot, so activation between requests cannot mix old HTML with newly activated assets. Snapshot URLs from more than 20 activations ago may return 404; a page refresh uses the current snapshot.

Mutations use a multisite-aware distributed mutex, a database transaction, and optimistic draft revisions. Public rendering never clones repositories, compiles assets, or imports framework theme modules.

`ThemeImporter::GitSource` reuses Discourse's URL normalization, public-IP checking, pinned HTTPS cloning, command timeout, and cleanup. It rejects HTTPS-to-HTTP downgrade, restricts Git transport to HTTPS, and skips framework compatibility-ref processing so no secondary unpinned fetch is needed. Repository allowlists are enforced through Guardian. Imported files must resolve inside the checkout and satisfy size and format limits.

The color row must use `Form.Row`'s yielded `row.Col` wrappers. FormKit positions row labels above their fields; a direct child `form.Field` lacks the positioned column and can place labels above the page header.

## Discourse Blog reference design

`branding/discourse-blog/` provides another complete version-2 theme, inspired by
blog.discourse.org's September 2026 design: lavender background, a prominent lead
story, rounded cards, a responsive three-column grid, and serif reading text.
It uses the local identity and public content, with no external fonts, scripts,
or copied marketing navigation. The development site has a separate saved draft
named **Discourse Blog**; installation does not activate it. See the bundled README
for import instructions and the deliberate differences from the reference.
