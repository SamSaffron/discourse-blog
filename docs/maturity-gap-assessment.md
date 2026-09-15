# Maturity gap assessment

Assessment of the implemented blog plugin against mature publishing products, including WordPress's plugin/hosting ecosystem rather than assuming every capability exists in stock WordPress. This is a prioritization proposal, not an implementation commitment.

## 1. Editorial workflow and publication safety

Current: native Discourse authoring/history, private drafts, explicit publication, and frozen external review with private feedback.

Gaps: scheduled publication, contributor/editor/publisher permissions independent of forum staff, approval states, staged revisions of published articles, and safer separation of internal editorial discussion from public replies. Saving a published first post changes the live article. Publishing a draft moves the entire topic and its replies; external review feedback is correctly separate, but ordinary editorial replies still require care.

Priority: highest. Model the approved/published revision explicitly before adding scheduling and review approvals. WordPress has granular publishing roles and both products support scheduling; staging edits to already published content may require additional tooling in WordPress.

### Editorial implementation follow-up

Private editorial topics, frozen submitted/approved revisions, publisher self-approval,
role groups, scheduled publication, and execution-time permission checks are now
implemented. Existing public discussion IDs are preserved; internal replies stay
private. See [Editorial workflow](editorial-workflow.md). The original gap list above
records the assessment before this implementation, not the current feature set.

## 2. Audience growth, distribution, and measurement

Current: public web articles, RSS, and Discourse community notifications/digests.

Gaps: publication-specific email signup without a forum account, newsletter delivery, subscriber preferences/segments, unsubscribe/bounce handling, and blog-specific readership/referral/conversion analytics. Forum topic views do not measure the complete SSR article audience. Paid membership is also unsupported but is not necessarily a priority for a community/product blog.

Priority: a basic newsletter integration and privacy-conscious article analytics before building a membership business stack. Ghost is a particularly strong comparator here.

## 3. Publication-oriented media and content authoring

Current: Discourse uploads and editor, ordinary cooked content rendering, image-derived article covers.

Gaps: a blog-oriented media library/reuse workflow, independent cover/social-image selection, convenient crop/focal-point/credit controls, and confidential draft/review media. Some rich cooked widgets do not have full SSR rendering parity. Core Discourse already supplies upload processing; this is a publishing UX and access-control gap, not an absence of image infrastructure.

Priority: explicit article cover/social metadata and coherent private-to-public media handling. A review capability protects article text, not existing upload URLs.

## 4. Site structure and real theme extensibility

Current: one publication category, archives/tags, a global About page, two base layouts, and safely previewed/activated CSS/JavaScript theme snapshots.

Gaps: arbitrary standalone pages, navigation management, custom home/landing layouts, author/series collections, reusable content sections, and theme packages containing templates and local assets. Git import currently deploys plain CSS/JavaScript over existing server markup, not a WordPress/Ghost-style complete theme. Multilingual publishing is not integrated.

Priority: pages/navigation and a bounded template contract rather than a general page builder or arbitrary server-code execution from Git.

## 5. Adoption and production maturity

Current: Discourse infrastructure and backups are inherited; the plugin has tests and development deployment documentation.

Gaps: WordPress/Ghost importers, publication-scoped export with media/paths/aliases, migration rehearsal and verification, production setup diagnostics, tested upgrade/restore procedures, and an explicit cache/CDN invalidation strategy. Public responses deliberately use no-store for immediate visibility revocation. The full-app discussion adds substantial deferred payload; large archives also need sitemap indexing beyond the current 50,000-entry cap.

Priority: end-to-end migration validation and a tested production deployment before treating feature tests as evidence of mature operational readiness. Caching needs permission-aware purge/revocation semantics, not a generic CDN toggle.

## Existing strengths

Native discussion, moderation, accounts, and editing history are substantial inherited capabilities. SEO foundations already include canonical URLs, redirects, sitemap, social metadata, and structured article data. External review and draft theme activation now exist. Do not list these as absent or rebuild them merely to imitate another CMS.

## Reference checks

- Ghost publishing/scheduling: https://ghost.org/help/publishing-content/
- Ghost native analytics: https://ghost.org/help/native-analytics/
- WordPress roles/capabilities: https://wordpress.org/documentation/article/roles-and-capabilities/
- WordPress media library: https://wordpress.org/documentation/article/media-library-screen/
