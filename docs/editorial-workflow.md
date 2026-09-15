# Editorial workflow

## Editorial and public navigation

On the local site, category 35 is **Blog editorial** (private working topics) and
category 34 is **Blog** (public articles/discussions). Their existing slugs and
permissions are retained to avoid breaking category links or changing access.
The `discourse_blog_drafts_category` setting keeps its existing API name.

Published dashboard titles, introductions, and paths reflect the live revision,
not private working changes. Titles link to the blog; **Public discussion** links
to the public topic. **Edit privately** opens the editorial source, creating a
working copy on demand when needed. The article remains **Published** while a
separate **Draft correction** label identifies changed source content, title,
publication metadata, or a newer submitted revision. An unchanged retained
working copy is not labeled a pending correction. Never-published articles are
labeled **Draft**. The Drafts filter continues to list unpublished private articles;
corrections remain alongside their published article rather than duplicating it.

## User-facing contract

- Write in a private editorial topic using the native Discourse composer. Internal
  replies never move into the public discussion during publication.
- Saving metadata stages it. Submitting freezes a revision; preview that revision
  before approving it. A publisher may self-approve.
- Publishing copies the approved first-post content to a separate public topic, or
  updates the established discussion's first post. Existing public IDs and replies
  are preserved. Native first-post/title editing on linked public articles is
  blocked; edit their private working copy instead.
- Native category changes cannot move an editorial topic out of the drafts
  category, including before a publication record exists. This avoids bypassing
  approval by exposing the whole topic. Administrative data imports/SQL and other
  code bypassing normal model validation remain privileged operations.
- Scheduled releases pin an approved revision. A later submission does not replace
  the scheduled revision. Cancel or reschedule explicitly. A successful manual
  publication or withdrawal cancels the outstanding schedule.
- Withdrawal removes the blog page, not the public discussion. The legacy
  return-to-drafts endpoint also preserves public discussions and prepares a
  private source when needed.
- Existing external-review grants remain independent of internal approval. They
  refer to a private source snapshot, and publication revokes that source's grants.
  Private feedback is never copied into a public topic.

The modal groups revision review, publication, schedule status/cancellation, and
secondary actions separately. **Publish now** is the primary immediate-release
action; **Or schedule for later** is optional. Approving an already approved
revision is not offered again. Publishing now also clears an existing schedule.

The API exposes `published_revision_id` independently of the submitted and approved
revision IDs. Once an approved revision is live, the modal replaces its release
controls with a persistent published confirmation and direct blog-post link.
Preparing a newer revision restores the release controls as **Publish correction
now**, while a link to the current live article remains available. Blank dates
from a form opened before first publication preserve the established publication
date when submitting a correction.

## Roles and category permissions

The `discourse_blog_contributor_groups`, `discourse_blog_editor_groups`, and
`discourse_blog_publisher_groups` settings default to staff. Administrators retain
access. Disabled, suspended, or silenced users cannot exercise editorial roles.

| Role | Scope |
| --- | --- |
| Contributor | Edit, preview, share for feedback, and submit their own drafts |
| Editor | The same operations for any editorial topic they can see |
| Publisher | Editor operations plus approval, publication, scheduling, cancellation, and withdrawal |

Grant these groups native access to the private drafts category. Publishers also
need permission to create topics in the public blog category. The plugin does not
make these users staff or bypass category visibility. Keep the drafts category
restricted to editorial groups and staff. Configuring groups alone is not enough.

## Data and compatibility

`Publication.topic_id` is the stable original identity used by dashboard/API URLs.
`draft_topic_id` is the private source; `discussion_topic_id` is the public topic.
The controller accepts any of these topic IDs and resolves the same publication.

The migration snapshots existing published articles and links their existing
public topics without moving them. A private copy is created on demand. Previously
unpublished private topics are recognized as sources without a bulk topic-copy job. Downgrading this migration is intentionally blocked:
new publications have different source and discussion identities. Use a verified
backup/restore plan rather than reverting to the old move-topic implementation.

`Revision.data` is read-only after creation and captures raw/cooked content, title,
path, excerpt, featured state, publication date, author name, image URL, and public
tags. Upload references keep raw-content attachments alive while revisions exist.
The live blog reads the published snapshot, not the current private first post.
Approval provenance is idempotent: repeating approval does not replace the original
approver or timestamp. Topic/post revisions still provide native editing history.

Only counterpart topics may share a duplicate title when ordinary site policy
would reject it. A scoped, ensure-restored copy context excludes the source during
creation; unrelated duplicate titles and other content validations still apply.

## Scheduling and failure handling

Scheduling accepts an ISO instant at least one minute ahead and at most one year
ahead. The FormKit input uses the browser's local timezone and sends UTC. The
optional backdated publication date is separate from the release instant.

The schedule is stored transactionally and queued after commit. A unique token
invalidates replaced/canceled jobs. Execution holds the original topic lock,
checks the token and due time, and rechecks configuration, source eligibility,
scheduler access, and approver access. It publishes in a savepoint so failures do
not leave a partially created public discussion.

Expected validation/authorization failures clear the schedule and record an error
shown in the publication modal. Cleanup does not revalidate unrelated publication
metadata: a path collision must not leave a schedule permanently stuck.
`RecoverBlogSchedules` runs every five minutes, enqueueing up to 100 overdue
schedules per run to recover lost queue submissions. Duplicate jobs are harmless.
A running Sidekiq worker and scheduled-job execution are required; this is not a
hard real-time guarantee. Unexpected infrastructure errors use normal job retries.

## Regression coverage and limits

`spec/requests/editorial_workflow_spec.rb` covers frozen publication, private replies,
existing discussion preservation, role scoping, revision previews, stale approvals,
scheduling, cancellation, access revocation, path collisions, native category moves,
and overdue-job recovery. Existing article/summary/review/filtering tests cover the
new private/public identity split. The editor acceptance suite covers explicit
submit/approve/publish, local-time scheduling/cancellation, and invalid forms.

The workflow is not a confidential-media system: ordinary upload URLs remain
independently accessible. It does not add collaborative edit locks, inline approval
comments, or approval notifications. Configure and operate workers before relying
on scheduled releases in production.
