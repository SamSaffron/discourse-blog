# External draft review

Editors can share a frozen draft with someone who has no Discourse account, collect private feedback, and revoke access without publishing the article.

## Using it

1. Open `/blog/editor`, find the draft, and open **Blog publication**.
2. Choose **Share for review and feedback**.
3. Optionally label the reviewer or review round, then choose **Create seven-day review link**.
4. Copy the link before closing the dialog. The raw token is shown only at creation; the database stores its digest, not a recoverable link.
5. Send the link to your reviewer. They can read the shared article and submit general text feedback, with optional name and email, without signing in.
6. Return to the same dialog and select **Feedback** for that review link. Use **Revoke link** to stop further views and submissions. Revocation does not delete already collected feedback.

Later draft edits do not change an existing review. Create another link for a new revision/round and revoke older links when appropriate. Each link captures the first post's version, sanitized cooked HTML, and current topic title. Feedback remains associated with that immutable snapshot.

The reader sees only the shared article and a feedback form, not staff replies, topic history, a category listing, or the native discussion. Publishing revokes existing grants; private review feedback is kept separate from the topic's replies and is never published with it. The management dialog remains available on published articles so editors can still read earlier feedback.

## Access and privacy

- Review URLs use the dedicated blog origin, `/review?review_token=…`. Possession of the link grants access; it can be forwarded. Reviewer labels and submitted names/emails are not proof of identity.
- Tokens contain 256 bits of randomness, are stored as SHA-256 digests, and expire after seven days. Every read and feedback submission checks expiry, revocation, current draft eligibility, and the creator's continuing editorial access.
- Moving, deleting, unlisting, or changing a topic's type revokes grants through model callbacks. Hiding or deleting the first post also revokes grants. Read-time checks independently reject inaccessible content. Hard-deleting a topic destroys its stored review snapshots and feedback.
- Management and feedback-reading endpoints require an authorized editorial user who can see and manage the associated topic. The review ID is scoped to that topic. A public token cannot read other reviewers' feedback.
- Anonymous feedback requires both a normal CSRF token and the configured blog origin. The review origin exposes an anonymous CSRF bootstrap endpoint for FormKit's AJAX client; it returns no draft or account data.
- Pages and JSON responses use `private, no-store`, `noindex, nofollow`, and `Referrer-Policy: no-referrer`. The application filters `review_token` request parameters from its logs. Treat proxy/access logs and browser history as sensitive because they may retain full URLs.
- Revocation cannot erase copies a recipient already read, downloaded, or photographed.
- **Uploads are not made confidential by this feature.** Ordinary existing upload URLs remain independently accessible. Do not use this workflow for confidential attachments without a separate protected-media design.
- `.dev.home.arpa` is a development/network-local hostname. External reviewers still need a reachable deployment or access to the development network.

## Reader implementation

The review surface boots the core Ember runtime to use FormKit, unlike the lightweight server-rendered public blog. Its dedicated layout loads only core assets and the blog plugin's assets. Other plugin runtimes, themes, custom blog JavaScript, analytics markup, and service-worker registration are excluded. The server boot uses anonymous user context even when an authenticated request reaches the review origin.

Snapshot HTML is sanitized and strips scripts, iframes, objects, forms, and other executable/embed elements. Relative media/link URLs are made absolute at snapshot creation. Linked media itself is not versioned or copied.

`Review.issue!` and feedback submission use topic/record locks. Publication and revocation use the same topic lock, preventing a submission from crossing a concurrent publication/revocation boundary. Snapshots are capped at 1 MiB; labels and optional names at 100 characters, emails at 254, and feedback text at 10,000. A draft can have at most 20 currently unexpired, unrevoked grants. A grant accepts up to 200 feedback entries, with additional limits of 30 submissions per IP per hour and 60 per grant per hour.

Review links and private feedback are fetched in pages of 30. Feedback counts are grouped for the list and refreshed when opening a review's responses. Feedback is retained for editorial reference; there are no automatic emails, reviewer accounts, inline annotations, or public comment threads in this version.

## Verification

Request coverage includes permission checks, digest-only storage, frozen revisions, sanitized snapshots, origin isolation, real CSRF enforcement, expired/tampered/revoked grants, publication revocation, creator access removal, topic deletion, feedback validation/rate limits/pagination, and restricted reader asset loading. Frontend tests cover account-free submission, expiry during submission, unavailable links, and the create/read/revoke management workflow with escaped feedback text.

For an existing public article, first create its private working copy in **Blog publication**. Review links and feedback belong to that private source, including after later publication. External feedback does not itself approve an internal publication revision.
