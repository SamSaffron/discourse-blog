# Initial design decisions

This records the decisions the first iteration was built on. Later work superseded
some of them: [Editorial workflow](editorial-workflow.md), [Blog themes](blog-themes.md),
and [Liquid template authoring](liquid-templates.md) describe the shipped behavior.

## Source of truth

A topic's first post is an article; its replies are the discussion. Publication
records contain editorial metadata, not duplicated raw/cooked content. Publishing
uses the existing category transition. Revisions and uploads stay in Discourse.

`discourse_blog_publications` has one row per topic. `discourse_blog_paths` owns the
unique URL namespace, retaining both current paths and old redirect aliases.

## Why not PublishedPage or TopicEmbed?

Core published pages offer a lightweight rendering precedent, but canonicalize
back to the topic and can explicitly expose otherwise restricted content. Those
semantics differ from this blog's publication and public-discussion contract.

TopicEmbed models imported external articles. Creating synthetic import records
would couple Discourse-authored articles to an unnecessary scraping/update flow.
The blog embeds by topic ID and scopes its canonical override to blog publications.

The original reference implementation was cloned from `samsaffron/blog`, revision
`deb220bcadec105e1396ca41ea335c54708b71c8`. Its one-database/two-host renderer was
preserved as an architectural idea. Hardcoded production domains, implicit global
publication callbacks, and wholesale hostname middleware replacement were not.

## Boundaries

- One public category, exact ID match, not a subtree or arbitrary category list.
- Private staff-only drafting in a separate category.
- Explicit publication makes the entire topic public.
- Post-publication editing goes through a private working copy and an explicitly
  approved revision; readers only ever see the approved revision.
- Unpublish and privatize are separate operations.
- Blog rendering and canonical resolution fail closed on current source visibility.
- Host-specific routes precede core routes, without changing global URL generation.
- The Discuss origin remains the account/application origin.
- Blog layout is independent of Ember; full-app discussion loads near the viewport.

## Deployment and caching

A trusted host alias is deployment configuration, not permission to honor arbitrary
forwarded hosts. Misconfiguring the blog origin to equal Discuss must never hijack
Discuss routes and lock administrators out of the settings interface.

This version chooses immediate next-request revocation over public response caching.
A future cache needs invalidation for deletion, hiding, category permissions, moves,
publication changes, first-post edits, paths, and media changes. Content versioning
alone is insufficient for permission revocation.

## Follow-up work

- Private draft media with a safe public publication transition.
- Rich-content renderer enhancements and a less framed discussion presentation.
- Notification delivery for scheduled releases.
- Paginated sitemap indexes for large archives.
- Historical-content import (paths, dates, bylines, and topic associations are
  deliberately separate so import does not need to re-author content).
- Cross-browser authentication testing beyond same-site Chromium.

Staged revisions and scheduled publication were listed here originally and are now
implemented. See [Editorial workflow](editorial-workflow.md).

## Appearance and custom code

Editorial-styled designs are the bundled examples, not a separate mode: reader
pages load one built-in stylesheet, `blog.css`, then the active design's CSS.
The bundled `branding/term-llm` design shows an Editorial treatment (large serif
typography, graphic covers) built on top of that base; a design without such CSS
renders the plain base.

The plugin admin area splits **Themes** (named drafts, immutable activation
snapshots, template overrides, and preview capabilities) from **Identity** (name,
tagline, and About copy, saved through the bulk site settings API). Forms use
FormKit, including native code editors; authorization, auditing, and input limits
stay in the existing configuration and staff-action machinery.

Administrator-authored CSS and JavaScript are served as separate typed resources,
not interpolated into HTML. This avoids closing-tag parsing hazards. Only the
public JavaScript asset is exempt from Rails' cross-origin script-response guard;
all state-changing endpoints retain CSRF protection. The script is loaded with a
CSP nonce; the policy is not globally weakened.

Custom JavaScript is never executed by authenticated previews hosted on Discuss.
Otherwise a blog customization could execute in the account/application origin.
Custom code is public and must not contain credentials. Code recovery skips custom
assets for a single page view, without turning off the publication or built-in theme.
