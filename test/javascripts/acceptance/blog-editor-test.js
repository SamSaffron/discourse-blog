import { click, visit } from "@ember/test-helpers";
import { test } from "qunit";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import formKit from "discourse/tests/helpers/form-kit-helper";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

acceptance("Blog editor", function (needs) {
  needs.user({ admin: true, moderator: false });
  needs.settings({
    discourse_blog_enabled: true,
    discourse_blog_category: 1,
    discourse_blog_drafts_category: 2,
    discourse_blog_url: "https://blog.example.com",
  });

  let draft;
  let published;

  needs.hooks.beforeEach(() => {
    draft = {
      id: 123,
      can_publish: true,
      source_topic_id: 123,
      source_url: "/t/an-unfinished-story/123",
      title: "An unfinished story",
      path: "/an-unfinished-story",
      url: "https://blog.example.com/an-unfinished-story",
      excerpt: "",
      featured: false,
      draft: true,
      published: false,
      live: false,
      replies: 0,
      topic_url: "/t/an-unfinished-story/123",
      preview_url: "/blog/preview/123",
    };
    published = {
      ...draft,
      id: 124,
      title: "A published story",
      draft: false,
      published: true,
      live: true,
      published_at: "2026-09-01T14:20:00.000Z",
      replies: 2,
    };
    pretender.get("/blog/editor.json", (request) => {
      const status = request.queryParams.filter;
      return response({
        topics: {
          all: [draft, published],
          drafts: [draft],
          published: [published],
          unpublished: [],
        }[status || "all"],
        blog_url: "https://blog.example.com",
      });
    });
    pretender.get("/blog/publications/123.json", () => response(draft));
    pretender.get("/blog/publications/124.json", () => response(published));
  });

  test("filters private drafts and published articles", async function (assert) {
    await visit("/blog/editor");
    assert
      .dom(".blog-dashboard__entry")
      .exists({ count: 2 }, "both editorial states are listed");
    await click(".blog-dashboard__filters button:nth-child(2)");
    assert.dom('[data-topic-id="123"]').exists("private drafts are shown");
    assert
      .dom('[data-topic-id="124"]')
      .doesNotExist("published articles are filtered out");
    await click(".blog-dashboard__filters button:nth-child(3)");
    assert.dom('[data-topic-id="124"]').exists("published articles are shown");
    assert
      .dom('[data-topic-id="123"]')
      .doesNotExist("private drafts are filtered out");
    await click(".blog-dashboard__filters button:nth-child(4)");
    assert
      .dom(".blog-dashboard__entry")
      .doesNotExist("unpublished filtering can return an empty result");
  });

  test("separates published articles from private correction work", async function (assert) {
    published = {
      ...published,
      title: "Private correction title",
      public_title: "The live article title",
      public_excerpt: "The published introduction",
      public_path: "/live-article",
      url: "https://blog.example.com/live-article",
      discussion_url: "/t/live-article/200",
      source_url: "/t/private-correction/201",
      draft_correction: true,
    };
    await visit("/blog/editor");
    assert
      .dom('[data-topic-id="124"] h2 a')
      .hasText(
        "The live article title",
        "published entries use the live title rather than the working copy"
      );
    assert
      .dom('[data-topic-id="124"] h2 a')
      .hasAttribute(
        "href",
        published.url,
        "the main link opens the actual blog article"
      );
    assert
      .dom('[data-topic-id="124"] .blog-dashboard__edit-private')
      .hasAttribute(
        "href",
        published.source_url,
        "private editing is a separate action"
      );
    assert
      .dom('[data-topic-id="124"] a[href="/t/live-article/200"]')
      .hasText(
        "Public discussion",
        "the public forum topic is separately accessible"
      );
    assert
      .dom('[data-topic-id="124"] .blog-dashboard__status')
      .hasText(
        "Published",
        "corrections do not mark a live article unpublished"
      );
    assert
      .dom('[data-topic-id="124"] .blog-dashboard__correction')
      .hasText("Draft correction", "pending editorial changes are identified");
    assert
      .dom('[data-topic-id="123"] .blog-dashboard__status')
      .hasText("Draft", "never-published articles are drafts");
    assert
      .dom('[data-topic-id="123"] .blog-dashboard__correction')
      .doesNotExist("new drafts are not corrections");
  });

  test("marks exactly one article filter as selected", async function (assert) {
    await visit("/blog/editor");
    const filters = ".blog-dashboard__filters";
    assert
      .dom(`${filters} button[aria-pressed="true"]`)
      .hasText("All articles", "all articles is selected initially");

    for (const [index, label] of [
      "Drafts",
      "Published",
      "Not on the blog",
      "All articles",
    ].entries()) {
      const position = index === 3 ? 1 : index + 2;
      await click(`${filters} button:nth-child(${position})`);
      assert
        .dom(`${filters} button[aria-pressed="true"]`)
        .exists({ count: 1 }, "exactly one filter is selected");
      assert
        .dom(`${filters} button[aria-pressed="true"]`)
        .hasText(label, "the clicked filter stays selected");
      assert
        .dom(`${filters} button[aria-pressed="false"]`)
        .exists({ count: 3 }, "the other filters are explicitly unselected");
    }
  });

  test("searches the server and preserves filters through load more and refresh", async function (assert) {
    const requests = [];
    pretender.get("/blog/editor.json", (request) => {
      requests.push({ ...request.queryParams });
      return response({
        topics:
          request.queryParams.page === "1"
            ? [{ ...draft, id: 125, title: "Another matching draft" }]
            : [draft],
        more:
          request.queryParams.q === "workflow" &&
          request.queryParams.page !== "1",
      });
    });
    await visit("/blog/editor");
    await click(".blog-dashboard__filters button:nth-child(2)");
    await formKit(".blog-dashboard__search").field("q").fillIn("workflow");
    await formKit(".blog-dashboard__search").submit();
    assert.deepEqual(
      requests.at(-1),
      { filter: "drafts", q: "workflow" },
      "search is combined with the server-side status filter"
    );
    await click("[data-blog-load-more]");
    assert.deepEqual(
      requests.at(-1),
      { filter: "drafts", q: "workflow", page: "1" },
      "load more preserves the entire query"
    );
    assert
      .dom(".blog-dashboard__entry")
      .exists({ count: 2 }, "additional matching entries are appended");
    assert
      .dom("[data-blog-load-more]")
      .doesNotExist("loading stops when there are no more matches");
    await click(".blog-dashboard__links button");
    assert.deepEqual(
      requests.at(-1),
      { filter: "drafts", q: "workflow" },
      "refresh keeps filters and returns to the first page"
    );
    assert
      .dom(".blog-dashboard__entry")
      .exists({ count: 1 }, "refresh replaces previous pages");
  });

  test("saving metadata does not publish and preserves publication time", async function (assert) {
    pretender.put("/blog/publications/124.json", (request) => {
      const data = new URLSearchParams(request.requestBody);
      assert.strictEqual(
        data.get("publication[excerpt]"),
        "A revised introduction",
        "the excerpt is saved"
      );
      assert.strictEqual(
        data.get("publication[published_at]"),
        published.published_at,
        "saving a date field does not reset the publication time"
      );
      return response(published);
    });
    await visit("/blog/editor");
    await click('[data-topic-id="124"] button');
    assert
      .dom(".blog-publication .d-modal__title")
      .hasText("Blog publication", "the modal title is translated");
    assert
      .dom('.blog-publication [data-name="path"]')
      .hasClass("--full", "article path uses the full FormKit width");
    assert
      .dom('.blog-publication [data-name="excerpt"]')
      .hasClass("--full", "excerpt uses the full FormKit width");
    await formKit(".blog-publication form")
      .field("excerpt")
      .fillIn("A revised introduction");
    await formKit(".blog-publication form").submit();
    assert
      .dom(".blog-publication")
      .exists("the workflow stays open after saving");
    assert
      .dom('[data-topic-id="124"] .blog-dashboard__status')
      .hasText("Published", "the existing publication stays live");
  });

  test("an invalid submission does not turn a later settings save into a submission", async function (assert) {
    let saves = 0;
    let submissions = 0;
    pretender.put("/blog/publications/123.json", () => {
      saves += 1;
      return response(draft);
    });
    pretender.post("/blog/publications/123/submit.json", () => {
      submissions += 1;
      return response(draft);
    });
    await visit("/blog/editor");
    await click('[data-topic-id="123"] button');
    await formKit(".blog-publication form").field("path").fillIn("");
    await click(
      ".blog-publication .form-kit__actions button:not([type='submit'])"
    );
    assert.strictEqual(saves, 0, "an invalid form is not saved");
    await formKit(".blog-publication form")
      .field("path")
      .fillIn("/still-private");
    await formKit(".blog-publication form").submit();
    assert.strictEqual(
      saves,
      1,
      "settings can be saved after correcting the path"
    );
    assert.strictEqual(
      submissions,
      0,
      "Save settings does not unexpectedly submit a revision"
    );
  });

  test("saves and submits a frozen revision before explicit approval and publication", async function (assert) {
    pretender.put("/blog/publications/123.json", (request) => {
      assert.step("save");
      assert.strictEqual(
        new URLSearchParams(request.requestBody).get("publication[path]"),
        "/ready-to-share",
        "the chosen path is saved"
      );
      return response(draft);
    });
    pretender.post("/blog/publications/123/submit.json", () => {
      assert.step("submit");
      draft = {
        ...draft,
        submitted_revision: {
          id: 7,
          preview_url: "/blog/preview/123?revision_id=7",
        },
      };
      return response(draft);
    });
    pretender.post("/blog/publications/123/approve.json", (request) => {
      assert.strictEqual(
        new URLSearchParams(request.requestBody).get("revision_id"),
        "7",
        "approval targets the submitted snapshot"
      );
      assert.step("approve");
      draft = { ...draft, approved_revision: draft.submitted_revision };
      return response(draft);
    });
    pretender.post("/blog/publications/123/publish.json", (request) => {
      assert.strictEqual(
        new URLSearchParams(request.requestBody).get("revision_id"),
        "7",
        "publication targets the approved snapshot"
      );
      assert.step("publish");
      draft = {
        ...draft,
        draft: false,
        published: true,
        live: true,
        published_revision_id: 7,
      };
      return response(draft);
    });
    await visit("/blog/editor");
    await click('[data-topic-id="123"] button');
    assert
      .dom(".blog-publication__publish")
      .doesNotExist("unapproved drafts cannot be published");
    await formKit(".blog-publication__metadata")
      .field("path")
      .fillIn("/ready-to-share");
    await click(".blog-publication__submit");
    assert.verifySteps(
      ["save", "submit"],
      "submission freezes saved metadata without publication"
    );
    assert
      .dom(".blog-publication__approval a")
      .hasAttribute(
        "href",
        "/blog/preview/123?revision_id=7",
        "preview shows the submitted revision"
      );
    await click(".blog-publication__approve");
    assert.verifySteps(["approve"], "approval is explicit");
    assert
      .dom(".blog-publication__approve")
      .doesNotExist(
        "an approved revision does not offer a redundant approval action"
      );
    assert
      .dom(".blog-publication__publish")
      .hasText("Publish now", "immediate publication is clearly labeled");
    assert
      .dom(".blog-publication__publish")
      .hasClass("btn-primary", "immediate publication is the primary action");
    await click(".blog-publication__publish");
    assert
      .dom(".dialog-body")
      .includesText("remain private", "the privacy boundary is explained");
    assert.verifySteps([], "publication waits for confirmation");
    await click(".dialog-footer .btn-primary");
    assert.verifySteps(["publish"], "only the approved revision is published");
    assert
      .dom(".blog-publication__success")
      .includesText(
        "Published — revision 7 is live",
        "publication is visibly confirmed"
      );
    assert
      .dom(".blog-publication__view-post")
      .hasAttribute(
        "href",
        draft.url,
        "the confirmation links directly to the blog post"
      );
    assert
      .dom(".blog-publication__publish")
      .doesNotExist("the live revision cannot be accidentally republished");
    assert
      .dom(".blog-publication__schedule")
      .doesNotExist("a live revision no longer offers scheduling");
    assert
      .dom('[data-topic-id="123"] .blog-dashboard__status')
      .hasText("Published", "the dashboard reflects publication");
  });

  test("schedules a frozen approval in local time and allows cancellation", async function (assert) {
    draft.approved_revision = { id: 7 };
    pretender.post("/blog/publications/123/schedule.json", (request) => {
      const data = new URLSearchParams(request.requestBody);
      assert.strictEqual(
        data.get("revision_id"),
        "7",
        "the approved revision is scheduled"
      );
      assert.strictEqual(
        data.get("scheduled_at"),
        new Date("2030-04-05T14:30").toISOString(),
        "local time is sent as an unambiguous UTC instant"
      );
      draft = {
        ...draft,
        scheduled_at: data.get("scheduled_at"),
        scheduled_revision_id: 7,
      };
      return response(draft);
    });
    pretender.delete("/blog/publications/123/schedule.json", () => {
      draft = { ...draft, scheduled_at: null, scheduled_revision_id: null };
      assert.step("cancel");
      return response(204);
    });
    await visit("/blog/editor");
    await click('[data-topic-id="123"] button');
    await formKit(".blog-publication__schedule")
      .field("scheduled_at")
      .fillIn("2030-04-05T14:30");
    await formKit(".blog-publication__schedule").submit();
    assert
      .dom(".blog-publication")
      .includesText(
        "Revision 7 is scheduled",
        "the frozen release is identified"
      );
    await click(".blog-publication__cancel-schedule");
    assert.verifySteps(["cancel"], "the schedule can be canceled");
    assert
      .dom(".blog-publication__cancel-schedule")
      .doesNotExist("the cancellation is reflected");
  });
  test("approval preserves unsaved metadata without including it in the revision", async function (assert) {
    draft.submitted_revision = { id: 7 };
    pretender.post("/blog/publications/123/approve.json", () => {
      draft = { ...draft, approved_revision: draft.submitted_revision };
      return response(draft);
    });
    await visit("/blog/editor");
    await click('[data-topic-id="123"] button');
    await formKit(".blog-publication__metadata")
      .field("excerpt")
      .fillIn("An unsaved introduction");
    await click(".blog-publication__approve");
    assert
      .dom(".blog-publication__metadata textarea")
      .hasValue(
        "An unsaved introduction",
        "approval does not discard in-progress settings"
      );
    assert
      .dom(".blog-publication")
      .includesText(
        "Approved revision 7",
        "approval still targets the saved revision"
      );
  });

  test("contributors can submit without being offered publisher actions", async function (assert) {
    draft.can_publish = false;
    draft.submitted_revision = { id: 7 };
    draft.approved_revision = { id: 7 };
    await visit("/blog/editor");
    await click('[data-topic-id="123"] button');
    assert
      .dom(".blog-publication__submit")
      .exists("contributors can submit a new revision");
    assert
      .dom(".blog-publication__approve")
      .doesNotExist("approval requires a publisher");
    assert
      .dom(".blog-publication__publish")
      .doesNotExist("publication requires a publisher");
    assert
      .dom(".blog-publication__schedule")
      .doesNotExist("scheduling requires a publisher");
  });
  test("publishes a correction while retaining the live link and confirms the replacement revision", async function (assert) {
    published = {
      ...published,
      published_revision_id: 6,
      submitted_revision: { id: 6 },
      approved_revision: { id: 6 },
      url: "https://blog.example.com/published-story",
    };
    pretender.put("/blog/publications/124.json", (request) => {
      published = {
        ...published,
        excerpt: new URLSearchParams(request.requestBody).get(
          "publication[excerpt]"
        ),
      };
      return response(published);
    });
    pretender.post("/blog/publications/124/submit.json", () => {
      published = {
        ...published,
        submitted_revision: {
          id: 7,
          preview_url: "/blog/preview/124?revision_id=7",
        },
        approved_revision: null,
      };
      return response(published);
    });
    pretender.post("/blog/publications/124/approve.json", () => {
      published = {
        ...published,
        approved_revision: published.submitted_revision,
      };
      return response(published);
    });
    pretender.post("/blog/publications/124/publish.json", (request) => {
      assert.strictEqual(
        new URLSearchParams(request.requestBody).get("revision_id"),
        "7",
        "the correction publishes the newly approved revision"
      );
      published = { ...published, published_revision_id: 7 };
      return response(published);
    });
    await visit("/blog/editor");
    await click('[data-topic-id="124"] button');
    assert
      .dom(".blog-publication__success")
      .includesText(
        "revision 6 is live",
        "the persisted published state is clear on opening"
      );
    await formKit(".blog-publication__metadata")
      .field("excerpt")
      .fillIn("A corrected introduction");
    await click(".blog-publication__submit");
    assert
      .dom(".blog-publication__success")
      .doesNotExist("the new correction is not incorrectly marked published");
    assert
      .dom(".blog-publication__live-link a")
      .hasAttribute(
        "href",
        published.url,
        "the existing article remains accessible during correction review"
      );
    await click(".blog-publication__approve");
    assert
      .dom(".blog-publication__publish")
      .hasText(
        "Publish correction now",
        "updating an existing article is explicit"
      );
    await click(".blog-publication__publish");
    await click(".dialog-footer .btn-primary");
    assert
      .dom(".blog-publication__success")
      .includesText(
        "revision 7 is live",
        "the corrected revision is confirmed"
      );
    assert
      .dom(".blog-publication__view-post")
      .hasAttribute(
        "href",
        published.url,
        "the correction retains the article URL"
      );
    assert
      .dom(".blog-publication__publish")
      .doesNotExist("the released correction no longer offers publication");
  });
});
