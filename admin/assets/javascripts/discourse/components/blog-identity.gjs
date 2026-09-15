import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import AdminConfigAreaCard from "discourse/admin/components/admin-config-area-card";
import SiteSetting from "discourse/admin/models/site-setting";
import Form from "discourse/components/form";
import { popupAjaxError } from "discourse/lib/ajax-error";
import DBreadcrumbsItem from "discourse/ui-kit/d-breadcrumbs-item";
import DPageSubheader from "discourse/ui-kit/d-page-subheader";
import { i18n } from "discourse-i18n";

export default class BlogIdentity extends Component {
  @service toasts;

  @tracked saving = false;

  get formData() {
    const settings = this.args.settings;
    return Object.fromEntries(
      [
        "discourse_blog_title",
        "discourse_blog_description",
        "discourse_blog_about",
      ].map((key) => [key, settings[key] || ""])
    );
  }

  get safeUrl() {
    return `${this.args.settings.discourse_blog_url}/?blog_safe_mode=1`;
  }

  @action
  async save(data) {
    this.saving = true;
    try {
      await SiteSetting.bulkUpdate(
        Object.fromEntries(
          Object.entries(data).map(([key, value]) => [key, { value }])
        )
      );
      this.toasts.success({
        data: { message: i18n("discourse_blog.admin.saved") },
      });
    } catch (error) {
      popupAjaxError(error);
      throw error;
    } finally {
      this.saving = false;
    }
  }

  <template>
    <div class="blog-identity" ...attributes>
      <DBreadcrumbsItem
        @path="/admin/plugins/discourse-blog/identity"
        @label={{i18n "discourse_blog.admin.identity"}}
      />
      <DPageSubheader
        @descriptionLabel={{i18n "discourse_blog.admin.identity_description"}}
        @titleLabel={{i18n "discourse_blog.admin.identity"}}
      />
      <div class="blog-identity__links">
        <a
          href={{@settings.discourse_blog_url}}
          target="_blank"
          rel="noopener noreferrer"
        >{{i18n "discourse_blog.admin.open_blog"}} ↗</a>
        <a
          href={{this.safeUrl}}
          target="_blank"
          rel="noopener noreferrer"
        >{{i18n "discourse_blog.admin.safe_mode"}} ↗</a>
      </div>
      <AdminConfigAreaCard @heading="discourse_blog.admin.identity">
        <:content>
          <Form
            class="blog-identity__form"
            @commitOnSubmit={{false}}
            @data={{this.formData}}
            @onSubmit={{this.save}}
            as |form|
          >
            <form.Field
              @format="full"
              @name="discourse_blog_title"
              @title={{i18n "discourse_blog.admin.blog_title"}}
              @type="input"
              @validation="required"
              as |field|
            ><field.Control /></form.Field>
            <form.Field
              @format="full"
              @name="discourse_blog_description"
              @title={{i18n "discourse_blog.admin.tagline"}}
              @type="textarea"
              as |field|
            ><field.Control @rows={{2}} /></form.Field>

            <form.Field
              @format="full"
              @name="discourse_blog_about"
              @title={{i18n "discourse_blog.admin.about"}}
              @type="composer"
              as |field|
            ><field.Control @height={{220}} /></form.Field>
            <form.Actions><form.Submit
                @disabled={{this.saving}}
                @label="discourse_blog.admin.save"
              /></form.Actions>
          </Form>
        </:content>
      </AdminConfigAreaCard>
    </div>
  </template>
}
