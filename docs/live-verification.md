# Development verification

Verified on 2026-09-08 against the local running Discourse installation.

## Automated checks

- 35 request examples: publication, privacy, metadata, routing, canonical URLs,
  redirects, feeds, themes, custom assets, safe mode, and administrator authorization.
- 5 QUnit acceptance tests: dashboard filters, metadata saving, publication
  confirmation, validation retry behavior, and the appearance/code-editing form.
- Ruby, JavaScript/Glimmer, stylesheet, and formatting checks run with `bin/lint --fix`.
- Core schema/annotation regeneration tasks ran without core working-tree changes;
  this external plugin's tables remain defined in its own migration.

## Browser checks

- Signed in as admin using the development shortcut on Discuss.
- Created a private topic through **Blog editor → New draft** and the standard
  composer; its selected category was Blog drafts.
- Opened publication controls, set a path/excerpt, confirmed publication, and
  verified the resulting article anonymously on the blog hostname.
- Returned the article to private drafts; anonymous article requests then returned
  a blog-styled 404, while the draft remained available to staff.
- Posted a reply directly from the blog's embedded discussion as admin.
- Opened an isolated, initially anonymous mobile browser context. The discussion
  rendered public replies and offered sign-in. Used the core sign-in handoff and
  the development user1 login shortcut, returned to the embedded composer, and
  posted a reply as the regular user. Production password/SSO authentication and
  other browser engines were not tested.
- Added a reply from another user while the blog discussion was open; it appeared
  through live updates without reloading the article.
- Checked closed-topic behavior. A closed empty discussion shows its closed state
  without an impossible first-reply prompt. Restored the demo topic to open.
- Verified the original article-only mobile load had no Discourse application or
  iframe loaded before reaching the discussion. Development profiler scripts are
  additional environment instrumentation, not plugin dependencies.
- Checked mobile/dark layouts at 390px and desktop/light layouts. No horizontal
  document overflow was present on the checked pages.
- Loaded **Admin → Plugins → Blog → Blog appearance** by direct URL; branding,
  theme/color controls, About editor, and CSS/JavaScript editors rendered.
- Saved actual CSS and JavaScript using the appearance form. The blog showed the
  custom CSS property and JavaScript DOM marker; the Discuss admin page did not.
- Opened `?blog_safe_mode=1`: the theme remained active, but both custom-code
  markers were absent and the recovery banner was visible.

## Seeded content

- 20 explicitly marked community topics, separate from blog publications:
  16 in General and 4 in Site Feedback.
- 3 published demo blog articles, with sample/live-tested replies.
- 2 private demo drafts for trying the editorial workflow.
- Re-running the community seed task still reported 20 community topics and 3
  published blog articles; it did not duplicate the content.

## URLs

- Blog: <https://blog.dev.home.arpa/>
- Editor: <https://blog-discuss.dev.home.arpa/blog/editor>
- Appearance: <https://blog-discuss.dev.home.arpa/admin/plugins/discourse-blog/appearance>
- Live discussion: <https://blog.dev.home.arpa/a-small-home-for-big-ideas#discussion>
- Feed: <https://blog.dev.home.arpa/feed.xml>
- Sitemap: <https://blog.dev.home.arpa/sitemap.xml>

The README documents deliberate v1 limitations, particularly private draft media,
complex cooked widgets, iframe presentation, scheduling, and staged published edits.

## Discussion appearance follow-up

- Added blog-scoped full-app embed styling using the configured paper, ink, and
  accent colors. Verified cream/green desktop and dark mobile (390px), with no
  horizontal overflow. Normal Discuss pages and other embeds keep their palette.
- Enabled core dynamic frame sizing with 280–1600px bounds. The invisible original
  post is clipped so its content cannot inflate the reported scroll height.
- Verified the anonymous empty state using an existing empty development topic
  in a temporary browser-only iframe substitution (no publication/data changes):
  280px frame, matching background, green login button, no horizontal overflow.
  Reloaded the article afterward to restore its actual discussion.
- Verified populated threads as admin and anonymously; the existing docked editor
  and anonymous sign-in controls remain present. Historical small-action rows,
  profiler badges, and developer toolbars are hidden inside the blog embed.
- Ran `discourse_blog:seed_replies` twice: counts stayed at 8, 4, and 4 replies for
  the three published articles. Added replies are labeled sample conversations.
- Regression checks: 35 request examples and 9 QUnit tests pass, including four
  new palette/scoping tests. Source lint and explicit public-JS lint pass.

## term-llm brand and loading follow-up

- Installed the editable `term-llm Community` theme with official-site-derived
  light/dark palettes, translated hero copy, and configurable product/blog/docs/
  source links. Verified the theme's admin page and its four destination settings.
- Replaced generic public copy with three term-llm articles and 20 labeled starter
  topics in Help, Workflows, Providers, and Development. Revised the welcome topic.
  The single Blog category remains public; both private drafts remain private.
- Updated seeded replies to match the articles; other replies were retained. Old
  article URLs still return 301 redirects (verified the writing-in-public alias).
- Shared the official favicon across community and blog, with request coverage.
- Verified logged-out desktop community and mobile dark community at 390px with
  no horizontal overflow. Blog and discussion share the site palette in dark mode.
- Removed the embedded topic map, progress counter, floating progress button, and
  redundant topic-footer controls. The actual docked composer/sign-in entry remains.
- First-paint trace: hidden iframe at 319ms, styled/visible at 990ms, constant parent
  background `rgb(252, 252, 250)`. Source+origin checked before revealing. Added a
  visible failure fallback for script errors or a 30-second readiness timeout.
- Final checks: 36 request examples, 9 QUnit tests, 3 standalone loader tests; lint
  passes. Brand setup was rerun without duplicating themes, categories, or topics.
- Source and operating instructions: `branding/term-llm/README.md`. No production
  DNS, TLS, external hosting, or public product-site content was changed.

## Typography, scrolling, and reload alignment

- Removed negative tracking from the monospace wordmark on both sites. The mark
  and name now use explicit spacing; display type is less oversized and sans-serif
  headings use modest tracking. Reduced the mobile hero's repeated content.
- Removed the iframe height cap and changed forced scrolling to automatic. Added
  an ongoing blog-scoped resize observer with cleanup, rather than relying on the
  limited initial core notifications. At 320px, the iframe grew from 1626px to
  1722px and shrank back with content; its document never exceeded its viewport.
- Reproduced the recurring misalignment with an iframe-only reload. The server
  class disappeared when the referrer changed, restoring an implicit sidebar grid
  column. The initializer now restores this cosmetic class from the exact embed
  URL marker; authorization and framing rules are unchanged.
- Verified before and after iframe-only reload: the iframe grid is one 960px
  column, avatar left is 0 inside the frame, and heading/frame left are both 240px
  on the parent page. Added a regression test for restoring the class and palette.
- 11 QUnit tests and 5 standalone loader tests pass. Relevant lint passes. The
  earlier 36 request tests are unaffected by these client-only changes.

## Conversation reading width

- Unified article and discussion width via `--blog-reading-width`, removing the
  independent 960px discussion limit. Editorial now uses 760px for both.
- Signed-in desktop measurements: article, discussion, iframe, and composer all
  760px wide; reply text 692px. The iframe content height equaled its viewport.
- At a 320px viewport, article/discussion measured 280px and document width stayed
  320px, with no horizontal overflow. Public stylesheet lint passes.

## Category organization

- Public category page and default sidebar now show exactly Blog, Help,
  Workflows, Feedback, and Development, in that order. No subcategories added.
- The publication category keeps its name Blog and its ID 34; publication
  configuration and three published articles are unchanged. Members can reply but
  cannot create announcement topics. They can create topics in the other four
  public categories.
- Moved three Providers topics into Help and one seeded feature proposal into
  Feedback. Removed the now-empty Providers and General categories; verified the
  old Providers URL responds with a 301 to Help. No user discussions were deleted.
- Repaired the invalid built-in Uncategorized ID, disabled uncategorized posting,
  and cleared the composer default. The built-in record remains but is not listed.
- Staff and Blog drafts retain their original staff-only permissions. Total
  non-category-definition topics remained 28. Rerunning organization moved zero
  topics; rerunning community seeding still reported 20 starters and 3 articles.
- Updated branding/setup sources to preserve this structure. 36 request tests and
  Ruby lint pass. Operational details are in branding/term-llm/README.md.

## Compact forum article presentation

- The first post of a published article (250+ words) now shows its editorial
  excerpt, blog link, and inline expansion control in the forum. Short posts,
  drafts, unpublished articles, and embedded discussions retain normal rendering.
- Verified the live `/t/a-home-for-people-building-with-term-llm/36` topic as an
  anonymous reader: initially compact; clicking expands the original article and
  its code block; clicking again collapses it. The button exposes aria-expanded.
- Backend coverage checks that full cooked content is unchanged and metadata is
  absent for short posts, drafts, and withdrawn publications. Acceptance coverage
  checks native rendering on expansion, normal replies, embed exclusion, and
  search-context bypass.
- Full regression suites: 40 request tests and 15 QUnit tests pass; lint passes.

## Resize handling after reply submission

- Consolidated sizing under the blog's origin/source-checked message handler.
  Core resize messages no longer also write the iframe height. The observer sends
  `discourse-blog-resize` and remains active after the readiness handshake.
- Observe the root border box, measure both intrinsic and bounding-box height,
  round upward, and allow one pixel for fractional layout rounding. Valid resize
  messages also restore automatic rather than forced iframe scrolling.
- Verified a real signed-in submission: the composer cleared, the frame grew
  through the optimistic and confirmed post layouts, and settled at 2041px for
  2040px of content with no remaining overflow. Removed both temporary test replies;
  the user's existing reply was left intact.
- Regression coverage includes repeated sizing after readiness, growth/shrinkage,
  malformed messages, wrong origins/frames, and border-box observation. 15 QUnit
  tests, 6 loader tests, and lint pass. Existing open blog pages need a refresh to
  load the updated parent-side resize handler.

## Editor forms, filtering, and pagination

- Audited the plugin forms: publication, admin appearance, and editor search use
  FormKit. The reader archive remains a plain SSR GET search form, without Ember.
- Publication path and excerpt now use FormKit's full-width format. Live modal
  measurements showed both controls filling their 552px field area; no settings
  were changed during verification. Removed a redundant code-control width rule.
- Added title/slug/article-path search and moved all status filters to the server,
  ahead of the 30-result page limit. Load more and refresh preserve the query;
  switching search/status starts from page zero. Added a public-unpublished filter.
- Live search for terminal-to-workspace returned only article 37. Request tests
  cover a matching published article beyond the initial page, 31 matching drafts
  across two pages, stable ordering, literal SQL wildcard search, validation, and
  unpublished-state separation. Acceptance tests cover query propagation, refresh,
  load-more exhaustion, and full-width FormKit fields.
- 45 request tests, 16 QUnit tests, and relevant lint pass.

## Blog theme drafts, Git import, and preview

- Fixed the appearance color row using FormKit's yielded column components; labels remain within their row at 1440px desktop and 390px mobile widths.
- Moved identity fields inside their card's FormKit form rather than placing the card in the form grid. The full admin page now measures 390px document width at a 390px viewport (no horizontal overflow).
- Saved the existing design unchanged as **term-llm Editorial** and activated that identical snapshot. Verified all six layout/palette/code fields matched the previously live site settings before activation.
- Saved **term-llm Minimal study** as a separate draft, then changed its layout and saved another revision. The active Editorial snapshot remained unchanged.
- Opened the Minimal draft's signed link in a fresh, unauthenticated browser context. It rendered Minimal, showed a theme-preview banner, listed the three public articles, and retained the token on article/navigation links. An ordinary request in the same context still rendered Editorial. No horizontal overflow was present.
- Theme Git import/pull endpoints, revision conflicts, bounded files, manifest validation, repository allowlisting, HTTPS downgrade rejection, blocked destinations, symlink isolation, and cleanup are covered by automated tests. Network cloning is replaced at the external boundary in import-format tests; no external repository was created or modified.
- The developer workflow and Git-ready manifest are documented in `docs/blog-themes.md` and `branding/term-llm/blog-theme.json`.

## Focused admin navigation

- Split the combined appearance screen into Settings, Themes, and Identity tabs. The Themes index shows two existing designs and no forms; it fits within the desktop viewport.
- Clicking a theme opens its own `/themes/:id/edit` route. Browser verification showed one title, one FormKit form, no themes list, and no top-level tab/header duplication. JavaScript starts collapsed; Git source is a separate disclosure when applicable.
- The editor renders at 390px with a 390px document width and all three color labels within their row. Direct reload of the nested editor succeeds.
- Creation and Git import have separate routes and transition to the persisted editor after success. FormKit's built-in dirty-navigation warning is covered by acceptance tests.
- Identity remains independently editable. Existing theme records and the active Editorial snapshot were not modified by this restructuring.

## Account-free draft review

- Created an **External review** grant for private topic 40 through the Blog publication dialog. The first-post snapshot is revision 1 and the link expires seven days after creation. The topic remained in Blog drafts and was not published.
- Opened the capability link in a fresh browser context with no Discourse session. It rendered the frozen title/body and a FormKit feedback form, without forum header/sidebar or a discussion iframe.
- Inspected reader assets: only `discourse-blog` was included in plugin entrypoints, no theme assets were loaded, and forum service-worker registration was omitted. The dedicated layout excludes analytics markup and custom blog JavaScript.
- Submitted temporary feedback anonymously using the normal CSRF bootstrap. The reader displayed a private-save confirmation; the staff review dialog displayed the same feedback. No topic reply was created. Removed that exact temporary feedback entry afterward; the usable review grant remains.
- Added coverage for real CSRF validation, wrong-origin submissions, token expiry/revocation, creator permissions, category moves, publication, hard deletion, HTML sanitization, rate/storage limits, and feedback pagination. Normal forum categories and the public blog still return HTTP 200.
- Ran the schema dump and core/plugin clean annotation tasks. This external plugin's schema is maintained by its migrations; the core schema dump remained unchanged.


## Editorial workflow verification

- Existing live publications retain public discussion IDs 36, 37, and 38.
- Created the real private working copy for article 36 through **Blog publication**:
  topic 67 is in private drafts category 35, has exactly one post, and initially
  matches the public article. Public discussion 36 was not edited or moved.
- Drafts 39 and 40 remain in category 35 and unpublished. The active external
  review for draft 40 is unaffected.
- Verified the live FormKit modal exposes submission separately from publication.
  Existing public articles first offer **Create private working copy**.
- Backend and frontend regression suites cover approval, scheduling, cancellation,
  role restrictions, frozen content, private replies, and preserved discussion IDs.
- Scheduled publication requires Sidekiq and its periodic scheduler; the local
  development Redis reports an active worker. Production operation still needs
  worker monitoring and backup/restore validation.


### Publication confirmation and correction UX

Verified with an isolated temporary article using the live publication modal:
first publication showed the published revision and direct blog link; editing the
private source did not change the live body; submitting and approving the correction
exposed **Publish correction now**; releasing it updated the same public URL and
discussion while preserving the initial publication date. The modal then confirmed
the new live revision and removed redundant publish/schedule controls. This also
covered publishing a correction without closing the original draft modal, catching
and fixing the blank-date validation failure. Both temporary topics and their
publication snapshots were deleted after verification. Existing user articles were
not edited or published by this check.
