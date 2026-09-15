# Liquid reader templates

The blog reader renders HTML on the server using Liquid. It is a traditional
multi-page site, not a browser-side Liquid interpreter or an Ember application.
Article HTML responses remain uncached (`private, no-store`) so withdrawal and
permission changes take effect immediately. RSS, sitemap, SEO metadata, CSP,
preview notices, and the discussion embed remain controlled by Rails.

## Editing and installing a theme

Open **Admin → Plugins → Blog → Themes → your theme**. The editor keeps a tab per
template, next to the design fields:

- **Design**: ordinary layout, palette, CSS, and JavaScript settings.
- **Site layout, Homepage and archive, Article, About page, Not found page**: one
  tab per template. A blank override shows the effective built-in source, named as
  built-in above it. **Customize this template** copies that source into an editable
  field; **Restore default** clears the override again. The tab itself is marked
  while a template is customized. Switching tabs preserves unsaved form data.
- **Preview draft**, below the editor: renders the page the current template serves,
  with unsaved changes. Changing the page or the sample article updates it; desktop
  or mobile only changes the viewport. It also links to the same preview in a new tab.

**Variables and examples** opens the searchable variable reference from the template
notice. It shows sample values from a selected public article and distinguishes
escaped values from trusted HTML. **Insert** appends the Liquid snippet to the
current template and closes the reference. If there are no public articles, the
reference uses example article values; article previews require a public article.
The article picker lists the latest 30 public articles.

Working preview links are bearer capabilities valid for 15 minutes. Only the latest
three snapshots per administrator are retained. Treat their URLs as shareable
access to the unsaved design, not as authentication. The preview iframe runs on the
blog origin, and only the Discuss origin may frame a signed preview. Private drafts
are never used as theme-preview samples.

Syntax errors identify the template and line in the preview. The first executed
undefined variable produces a warning, followed by a lenient rendering so other
content remains visible. Runtime failures are explicit in signed previews; normal
live rendering retains its built-in fallback. An invalid Liquid template may be
previewed for diagnosis but cannot be saved. Save and activate remain separate,
explicit actions.

Git imports accept the existing version-1 format or version 2:

```text
blog-theme.json
blog.css
templates/layout.liquid
templates/index.liquid
templates/article.liquid
templates/about.liquid
templates/not_found.liquid
```

Set `"version": 2` in the manifest to import templates. Every template is optional,
UTF-8, at most 65,536 bytes, and read through the same repository boundary checks
as CSS and JavaScript. No template filenames supplied by a browser or by Liquid
are resolved against the filesystem. Images/fonts still use absolute asset URLs;
this format does not install arbitrary repository assets or run a build step.

Template source belongs to the saved theme and immutable activation snapshot.
Draft edits and Git pulls do not modify the active templates. Admin-only authoring
and the existing stale-revision checks remain in force.

## Data contract

All values below are primitives, arrays, or explicitly constructed hashes—not
ActiveRecord models, controllers, requests, sessions, or arbitrary site settings.

- `site`: `title`, `description`, `url`, `archive_url`, `about_url`, `feed_url`,
  `community_url`, `editor_url`, `about_html`.
- `page`: `title`, `heading`, `eyebrow`, `archive`, `query`,
  `preview_token`, `previous_url`, `next_url`.
- `articles`: the current public, paginated listing. Each entry has `title`, `url`,
  `excerpt`, `standfirst`, `author`, `published_at`, `date`, `relative_date`,
  `reading_time`, `featured`, `image_url`, `discussion_url`, `replies`,
  `replies_label`, `index`, and `updated_label`.
- `article`: the current approved/published article, with the same fields plus
  `body_html` and `tags` (each tag has `name` and `url`). Body HTML is not included
  in list entries. Reader data comes from the immutable published revision.
- `labels`: the plugin's translated top-level reader strings, e.g. `labels.about`,
  `labels.continue_reading`, `labels.comments`, and `labels.pagination`.
- `content_html`: layout only—the rendered page and, for articles, its core-owned
  discussion section. The layout should include this fragment exactly once in a
  `<main id="main">` element so keyboard skip links continue to work.

Use the supplied URLs rather than reconstructing them. They retain the signed
preview parameter when navigating between public theme-preview pages. GET search
forms must also submit `page.preview_token` as a hidden `blog_theme_preview` input
when present, since browser GET submission replaces an action URL's query string.

```liquid
<main id="main">{{ content_html }}</main>
```

```liquid
{% for article in articles %}
  <article>
    <h2><a href="{{ article.url }}">{{ article.title }}</a></h2>
    <p>{{ article.excerpt }}</p>
    <a href="{{ article.url }}#discussion">{{ labels.comments }}</a>
  </article>
{% endfor %}
```

## Escaping and execution boundaries

Variable output is HTML-escaped automatically, including output after filters.
Do not add `escape` to ordinary variables: that would escape them twice. Only the
server-created `content_html`, `article.body_html`, and `site.about_html` fragments
bypass this output escaping. No raw-output filter is registered. Capturing markup
into a Liquid string does not turn it into a trusted HTML fragment.

This is HTML escaping, not universal context-aware encoding. Put supplied URL
fields in quoted URL attributes; do not interpolate arbitrary text into CSS,
JavaScript, or executable URL contexts. Template source itself is administrator-
authored HTML and must be trusted just like custom theme JavaScript.

A separate Liquid environment allows `if`, `unless`, `case`, `for`, `break`,
`continue`, `assign`, `capture`, `comment`, `raw`, `cycle`, `increment`, and
`decrement`. Standard filters are available, but unknown filters fail rendering.
Includes, render tags, filesystem loaders, Ruby evaluation, and global workflow
registrations are not available. Changes here do not modify workflow Liquid behavior.

Limits: 2 MiB rendered output, 100,000 render score, 256 KiB assignment score, and
matching cumulative limits. Ranges are additionally limited to 1,000 elements
before Liquid can materialize them into arrays. The parser enforces its nesting
limit. These are application resource guards, not OS-level memory/CPU isolation;
only trusted administrators should author templates.

Syntax errors reject saves. Runtime Liquid errors/resource-limit failures log the
template name/error class and fall back to the corresponding built-in template.
`?blog_safe_mode=1` bypasses custom templates as well as CSS/JavaScript. Authenticated
editorial previews always use built-in templates, even when the active reader theme
has overrides, so custom theme HTML never receives a private draft or runs in an
authenticated Discuss page. External draft-review pages remain separate.

## Reference theme and navigation verification

`branding/samsaffron/` contains the version-2 reference theme, based on the current
public samsaffron.com layout. It keeps the local blog identity/articles and uses
reference sidebar links; no external activity feeds or tracking scripts are copied.
Install it by copying `blog-theme.json`, `blog.css`, and `templates/` to a public
repository root and using **Import from Git**. On the development blog the design it
replaced remains saved as **term-llm Editorial — before samsaffron.com**.

The reference stylesheet names Inter, but the reference page does not load that
font. On Discourse, naming Inter instead activated the forum's downloadable font:
Chrome captured an initial frame with invisible text and a 22px header shift.
The theme now uses system fonts directly, matching the reference's effective
fallback and avoiding text dependence on that font load. Repeat local navigation
measured CLS 0.00 and LCP about 100 ms (unthrottled development measurements, not a
production performance guarantee). Navigation is still an ordinary document load.
