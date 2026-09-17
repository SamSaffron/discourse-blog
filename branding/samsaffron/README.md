# samsaffron.com theme

A version-2 Liquid theme retaining the blog's slate header, blue links, chronological
post summaries, and reference sidebar, with a shared alignment grid and a quieter
reading layout.

## Layout

- Header identity, navigation, articles, and footer share the same responsive gutters.
- Summary titles have their own typography and spacing, independent of cooked article
  headings. Each summary has an absolute publication date, reading time, excerpt, and
  a compact reading/discussion action row.
- The desktop sidebar uses a light divider rather than a stack of boxed panels. It
  moves below the articles on smaller screens; intermediate widths use two columns.
- Article pages reserve their full 776px desktop reading width before adding the
  sidebar at 1160px. Below that, the sidebar follows the article; the homepage and
  archive retain their 960px sidebar breakpoint.
- Article content retains the built-in handling for images, code, tables, and embeds.
  Discussion and search controls align with the article column.
- Colours derive from the saved blog palette and Discourse's light/dark palette.
  Focus indicators remain visible on both the paper and slate surfaces.

## Sidebar links

The **On social** section links to:

- Mastodon: <https://ruby.social/@samsaffron>
- Bluesky: <https://bsky.app/profile/samsaffron1.bsky.social>
- Twitter: <https://twitter.com/samsaffron>

**Community activity** links to <https://meta.discourse.org/u/sam/activity>, not the
local discussion homepage. Talks/interviews and the About section are retained;
the Stack Overflow block has been removed. No external activity feed, tracking
script, font download, or social embed is loaded.

The site title, description, About content, article data, and discussion origin
remain configurable. Labels use the plugin's translations, including `on_social`.
The profile destinations above are specific to this reference theme.

## Editorial corrections

When proofreading Sam's articles, fix clear typos, repeated or missing words, and
broken phrasing rather than rewriting his voice. Never introduce em dashes in a
correction. Preserve code, quotations, historical technical claims, original
publication dates, and URLs. Keep an exact before-and-after log and retain the
previous published revisions.

## Import and activation

Place `blog-theme.json`, `blog.css`, and `templates/` at a public Git repository root,
then use Blog → Themes → Import from Git. Import creates a draft; preview it before
activation. Version-2 theme ZIP imports are also supported. Blank optional template
files fall back to built-in pages.

In the local migration rehearsal, the saved **samsaffron.com** design has ID
`cc747746-b767-4796-8230-b8253f3eeaf4`. The previous appearance is saved separately as
**samsaffron.com — original layout** for rollback. Appearance changes do not alter
article bodies, publication paths, comments, or private drafts.

The bundled-theme request spec in `spec/requests/themes_spec.rb` exercises the
homepage, archive, tag, article, About, and missing-page templates with strict
preview diagnostics, profile links, heading structure, and the original discussion.
