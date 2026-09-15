import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import Form from "discourse/components/form";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import DButton from "discourse/ui-kit/d-button";
import DFlashMessage from "discourse/ui-kit/d-flash-message";
import DModal from "discourse/ui-kit/d-modal";
import { i18n } from "discourse-i18n";
import BlogReviews from "./blog-reviews";

export default class BlogPublication extends Component {
  @service dialog;
  @service modal;

  @tracked busy = false;
  #form;
  #submitRequested = false;
  @tracked _publication;

  get publication() {
    return this._publication || this.args.model.publication;
  }

  get formData() {
    const publication = this.args.model.publication;
    return {
      path: publication.path,
      excerpt: publication.excerpt || "",
      featured: publication.featured,
      published_at: publication.published_at?.slice(0, 10) || "",
    };
  }

  get approvedRevisionIsLive() {
    return (
      this.publication.live &&
      this.publication.approved_revision?.id ===
        this.publication.published_revision_id
    );
  }

  get publishLabel() {
    return this.publication.live
      ? "discourse_blog.editorial.publish_correction"
      : "discourse_blog.editorial.publish";
  }

  get canApprove() {
    return (
      this.publication.can_publish &&
      this.publication.submitted_revision?.id !==
        this.publication.approved_revision?.id
    );
  }

  get scheduleLabel() {
    return i18n("discourse_blog.editorial.scheduled", {
      id: this.publication.scheduled_revision_id,
      date: new Date(this.publication.scheduled_at).toLocaleString(),
    });
  }

  @action
  registerForm(api) {
    this.#form = api;
  }

  @action
  async prepare() {
    await this.#mutate("/prepare");
  }

  @action
  async save(data) {
    this.busy = true;
    try {
      let result = await ajax(
        `/blog/publications/${this.publication.id}.json`,
        {
          type: "PUT",
          data: {
            publication: {
              ...data,
              published_at:
                data.published_at ===
                this.publication.published_at?.slice(0, 10)
                  ? this.publication.published_at
                  : data.published_at || null,
            },
          },
        }
      );
      this.#form.commit();
      this._publication = result;
      if (this.#submitRequested) {
        result = await ajax(
          `/blog/publications/${this.publication.id}/submit.json`,
          { type: "POST" }
        );
      }
      this._publication = result;
      this.args.model.onChanged?.();
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.busy = false;
      this.#submitRequested = false;
    }
  }

  @action
  async submitRevision() {
    this.#submitRequested = true;
    try {
      await this.#form.submit();
    } finally {
      this.#submitRequested = false;
    }
  }

  @action
  approve() {
    this.#mutate("/approve", {
      revision_id: this.publication.submitted_revision.id,
    });
  }

  @action
  publish() {
    const revisionId = this.publication.approved_revision.id;
    this.dialog.confirm({
      message: i18n("discourse_blog.editorial.publish_confirm", {
        id: revisionId,
      }),
      didConfirm: () => this.#mutate("/publish", { revision_id: revisionId }),
    });
  }

  @action
  async schedule(data) {
    await this.#mutate("/schedule", {
      revision_id: this.publication.approved_revision.id,
      scheduled_at: new Date(data.scheduled_at).toISOString(),
    });
  }

  @action
  cancelSchedule() {
    this.#mutate("/schedule", {}, "DELETE");
  }

  @action
  unpublish() {
    this.dialog.confirm({
      message: i18n("discourse_blog.unpublish_confirm"),
      didConfirm: () => this.#mutate("", {}, "DELETE"),
    });
  }

  @action
  shareForReview() {
    const open = () =>
      this.modal.show(BlogReviews, {
        model: {
          topicId: this.publication.source_topic_id || this.publication.id,
          draft: true,
        },
      });
    if (this.#form?.isDirty) {
      this.dialog.confirm({
        message: i18n("discourse_blog.review.discard_metadata"),
        didConfirm: open,
      });
    } else {
      open();
    }
  }

  async #mutate(suffix, data = {}, type = "POST") {
    this.busy = true;
    try {
      const result = await ajax(
        `/blog/publications/${this.publication.id}${suffix}.json`,
        { type, data }
      );
      this._publication =
        result ||
        (await ajax(`/blog/publications/${this.publication.id}.json`));
      this.args.model.onChanged?.();
    } catch (error) {
      popupAjaxError(error);
      return false;
    } finally {
      this.busy = false;
    }
  }

  <template>
    <DModal
      class="blog-publication"
      @closeModal={{@closeModal}}
      @submitOnEnter={{false}}
      @title={{i18n "discourse_blog.manage"}}
    >
      <:body>
        <h2>{{this.publication.title}}</h2>
        {{#if this.publication.live}}
          <p class="blog-publication__live-link">
            <a
              href={{this.publication.url}}
              target="_blank"
              rel="noopener noreferrer"
            >{{i18n "discourse_blog.editorial.view_live"}}</a>
          </p>
        {{/if}}
        <DFlashMessage
          @flash={{i18n "discourse_blog.editorial.notice"}}
          @type="info"
        />
        {{#if this.publication.source_url}}
          <p><a
              class="blog-publication__source"
              href={{this.publication.source_url}}
              target="_blank"
              rel="noopener noreferrer"
            >{{i18n "discourse_blog.editorial.edit_draft"}}</a></p>
        {{else}}
          <DButton
            class="btn-default"
            @action={{this.prepare}}
            @disabled={{this.busy}}
            @label="discourse_blog.editorial.prepare"
          />
        {{/if}}
        <Form
          class="blog-publication__metadata"
          @data={{this.formData}}
          @onRegisterApi={{this.registerForm}}
          @onSubmit={{this.save}}
          as |form|
        >
          <form.Field
            @description={{i18n "discourse_blog.path_hint"}}
            @format="full"
            @name="path"
            @title={{i18n "discourse_blog.path"}}
            @type="input"
            @validation="required"
            as |field|
          ><field.Control maxlength="240" /></form.Field>
          <form.Field
            @description={{i18n "discourse_blog.excerpt_hint"}}
            @format="full"
            @name="excerpt"
            @title={{i18n "discourse_blog.excerpt"}}
            @type="textarea"
            as |field|
          ><field.Control maxlength="1000" @rows={{4}} /></form.Field>
          <form.Field
            @description={{i18n "discourse_blog.date_hint"}}
            @name="published_at"
            @title={{i18n "discourse_blog.date"}}
            @type="input"
            as |field|
          ><field.Control @type="date" /></form.Field>
          <form.Field
            @name="featured"
            @title={{i18n "discourse_blog.featured"}}
            @type="checkbox"
            as |field|
          ><field.Control /></form.Field>
          <form.Actions>
            <form.Submit @disabled={{this.busy}} @label="discourse_blog.save" />
            <DButton
              class="blog-publication__submit btn-default"
              @action={{this.submitRevision}}
              @disabled={{this.busy}}
              @label="discourse_blog.editorial.submit"
            />
            <a
              href={{this.publication.preview_url}}
              target="_blank"
              rel="noopener noreferrer"
            >{{i18n "discourse_blog.preview"}}</a>
          </form.Actions>
        </Form>
        {{#if this.publication.submitted_revision}}
          <section class="blog-publication__section blog-publication__approval">
            <h3>{{i18n
                "discourse_blog.editorial.submitted"
                id=this.publication.submitted_revision.id
              }}</h3>
            <div class="blog-publication__actions">
              <a
                href={{this.publication.submitted_revision.preview_url}}
                target="_blank"
                rel="noopener noreferrer"
              >{{i18n "discourse_blog.editorial.preview_revision"}}</a>
              {{#if this.canApprove}}
                <DButton
                  class="blog-publication__approve btn-default"
                  @action={{this.approve}}
                  @disabled={{this.busy}}
                  @label="discourse_blog.editorial.approve"
                />
              {{/if}}
            </div>
          </section>
        {{/if}}
        {{#if this.publication.approved_revision}}
          <section class="blog-publication__section blog-publication__release">
            <h3>{{i18n "discourse_blog.editorial.release"}}</h3>
            {{#if this.approvedRevisionIsLive}}
              <div class="blog-publication__success" role="status">
                <DFlashMessage
                  @flash={{i18n
                    "discourse_blog.editorial.published_success"
                    id=this.publication.published_revision_id
                  }}
                  @type="success"
                />
                <a
                  class="blog-publication__view-post btn btn-primary"
                  href={{this.publication.url}}
                  target="_blank"
                  rel="noopener noreferrer"
                >{{i18n "discourse_blog.editorial.view_post"}}</a>
              </div>
            {{else}}
              <p class="blog-publication__hint">{{i18n
                  "discourse_blog.editorial.approved"
                  id=this.publication.approved_revision.id
                }}</p>
              {{#if this.publication.can_publish}}
                <div class="blog-publication__actions">
                  <DButton
                    class="blog-publication__publish btn-primary"
                    @action={{this.publish}}
                    @disabled={{this.busy}}
                    @label={{this.publishLabel}}
                  />
                </div>
                <Form
                  class="blog-publication__schedule"
                  @onSubmit={{this.schedule}}
                  as |form|
                >
                  <form.Field
                    @name="scheduled_at"
                    @format="full"
                    @title={{i18n "discourse_blog.editorial.schedule_label"}}
                    @description={{i18n
                      "discourse_blog.editorial.schedule_hint"
                    }}
                    @type="input"
                    @validation="required"
                    as |field|
                  ><field.Control @type="datetime-local" /></form.Field>
                  <form.Actions><DButton
                      class="btn-default"
                      type="submit"
                      @disabled={{this.busy}}
                      @label="discourse_blog.editorial.schedule"
                    /></form.Actions>
                </Form>
              {{/if}}
            {{/if}}
          </section>
        {{/if}}
        {{#if this.publication.scheduled_at}}
          <section class="blog-publication__scheduled">
            <DFlashMessage @flash={{this.scheduleLabel}} @type="info" />
            {{#if this.publication.can_publish}}
              <div class="blog-publication__actions">
                <DButton
                  class="blog-publication__cancel-schedule btn-default"
                  @action={{this.cancelSchedule}}
                  @disabled={{this.busy}}
                  @label="discourse_blog.editorial.cancel_schedule"
                />
              </div>
            {{/if}}
          </section>
        {{/if}}
        {{#if this.publication.schedule_error}}<DFlashMessage
            @flash={{this.publication.schedule_error}}
            @type="error"
          />{{/if}}
        <div class="blog-publication__secondary-actions">
          {{#if this.publication.source_topic_id}}
            <DButton
              class="blog-publication__reviews btn-default"
              @action={{this.shareForReview}}
              @disabled={{this.busy}}
              @label="discourse_blog.review.manage"
            />
          {{/if}}
          {{#if this.publication.can_publish}}
            {{#if this.publication.published}}
              <DButton
                class="blog-publication__unpublish btn-danger"
                @action={{this.unpublish}}
                @disabled={{this.busy}}
                @label="discourse_blog.unpublish"
              />
            {{/if}}
          {{/if}}
        </div>
      </:body>
    </DModal>
  </template>
}
