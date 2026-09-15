import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import Form from "discourse/components/form";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import DBreadcrumbsItem from "discourse/ui-kit/d-breadcrumbs-item";
import DPageSubheader from "discourse/ui-kit/d-page-subheader";
import { i18n } from "discourse-i18n";

export default class BlogThemeImport extends Component {
  @service router;

  #formApi;

  @action
  registerApi(api) {
    this.#formApi = api;
  }

  @action
  async importTheme(data) {
    try {
      const theme = await ajax("/blog/themes/import.json", {
        type: "POST",
        data,
      });
      this.#formApi.commit();
      this.router.transitionTo(
        "adminPlugins.show.discourse-blog-themes.edit",
        theme.id
      );
    } catch (error) {
      popupAjaxError(error);
      throw error;
    }
  }

  <template>
    <section class="blog-theme-import admin-detail">
      <DBreadcrumbsItem
        @path="/admin/plugins/discourse-blog/themes/import/new"
        @label={{i18n "discourse_blog.admin.import_git"}}
      />
      <DPageSubheader
        @titleLabel={{i18n "discourse_blog.admin.import_git"}}
        @descriptionLabel={{i18n "discourse_blog.admin.git_description"}}
      />
      <Form
        class="blog-theme-import__form"
        @onRegisterApi={{this.registerApi}}
        @onSubmit={{this.importTheme}}
        as |form|
      >
        <form.Field
          @format="full"
          @name="repository"
          @title={{i18n "discourse_blog.admin.repository"}}
          @type="input"
          @validation="required"
          as |field|
        ><field.Control @maxlength={{1000}} /></form.Field>
        <form.Field
          @format="full"
          @name="branch"
          @title={{i18n "discourse_blog.admin.branch"}}
          @type="input"
          as |field|
        ><field.Control @maxlength={{200}} /></form.Field>
        <form.Actions><form.Submit
            @label="discourse_blog.admin.import_git"
          /></form.Actions>
      </Form>
    </section>
  </template>
}
