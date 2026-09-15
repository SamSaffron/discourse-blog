import { click, visit } from "@ember/test-helpers";
import { test } from "qunit";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import formKit from "discourse/tests/helpers/form-kit-helper";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

acceptance("Blog review management", function (needs) {
  needs.user({ admin: true });
  needs.settings({ discourse_blog_enabled: true });

  let reviews;
  needs.hooks.beforeEach(() => {
    reviews = [];
    const draft = {
      id: 40,
      source_topic_id: 40,
      source_url: "/t/private-article/40",
      title: "Private article",
      draft: true,
      published: false,
      live: false,
      path: "/private-article",
      excerpt: "",
      featured: false,
    };
    pretender.get("/blog/editor.json", () =>
      response({
        topics: [draft],
        more: false,
        blog_url: "https://blog.example.com",
      })
    );
    pretender.get("/blog/publications/40.json", () => response(draft));
    pretender.get("/blog/publications/40/reviews.json", () =>
      response({ reviews, more: false })
    );
  });

  test("creates, reads private feedback, and revokes a review link separately from publication", async function (assert) {
    pretender.post("/blog/publications/40/reviews.json", (request) => {
      assert.strictEqual(
        new URLSearchParams(request.requestBody).get("label"),
        "Editorial round",
        "the optional label is saved"
      );
      const review = {
        id: 1,
        label: "Editorial round",
        post_version: 1,
        active: true,
        feedback_count: 1,
      };
      reviews = [review];
      return response({
        review,
        url: "https://blog.example.com/review?review_token=secret",
      });
    });
    pretender.get("/blog/publications/40/reviews/1/feedback.json", () =>
      response({
        feedback: [
          {
            id: 1,
            name: "Guest",
            email: "",
            message: "<script>not executable</script>",
            created_at: "2030-01-01T00:00:00Z",
          },
        ],
        more: false,
      })
    );
    pretender.delete("/blog/publications/40/reviews/1.json", () => {
      reviews = [
        { ...reviews[0], active: false, revoked_at: "2030-01-01T00:00:00Z" },
      ];
      assert.step("revoked");
      return response(204);
    });
    await visit("/blog/editor");
    await click('[data-topic-id="40"] button');
    await click(".blog-publication__reviews");
    assert
      .dom(".blog-reviews")
      .includesText(
        "Anyone with the link",
        "the sharing boundary is explained before creation"
      );
    await formKit(".blog-reviews__create")
      .field("label")
      .fillIn("Editorial round");
    await formKit(".blog-reviews__create").submit();
    assert
      .dom(".blog-reviews__open")
      .hasAttribute(
        "href",
        "https://blog.example.com/review?review_token=secret",
        "the one-time link is shown"
      );
    await click('[data-review-id="1"] button:first-of-type');
    assert
      .dom(".blog-reviews__feedback p")
      .hasText(
        "<script>not executable</script>",
        "untrusted feedback is escaped"
      );
    assert
      .dom(".blog-reviews__feedback script")
      .doesNotExist("feedback never becomes executable HTML");
    await click('[data-review-id="1"] button:last-of-type');
    assert.verifySteps([], "revocation requires confirmation");
    await click(".dialog-footer .btn-primary");
    assert.verifySteps(["revoked"], "the selected grant is revoked");
    assert
      .dom(".blog-reviews__open")
      .doesNotExist("a revoked link is no longer offered for sharing");
    assert
      .dom('[data-review-id="1"]')
      .includesText(
        "Expired or revoked",
        "the old review remains available for private feedback"
      );
  });
  test("asks before discarding unsaved publication settings", async function (assert) {
    await visit("/blog/editor");
    await click('[data-topic-id="40"] button');
    await formKit(".blog-publication form")
      .field("excerpt")
      .fillIn("Unsaved publication excerpt");
    await click(".blog-publication__reviews");
    assert
      .dom(".dialog-body")
      .includesText(
        "Discard unsaved publication settings",
        "sharing does not silently discard metadata edits"
      );
    assert
      .dom(".blog-reviews")
      .doesNotExist("review management waits for confirmation");
    await click(".dialog-footer .btn-primary");
    assert
      .dom(".blog-reviews")
      .exists("confirmation opens the saved-article sharing workflow");
  });
});
