import Component from "@glimmer/component";
import { fn, hash } from "@ember/helper";
import { action } from "@ember/object";
import { service } from "@ember/service";
import Form from "discourse/components/form";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { eq } from "discourse/truth-helpers";
import DBreadcrumbsItem from "discourse/ui-kit/d-breadcrumbs-item";
import DPageSubheader from "discourse/ui-kit/d-page-subheader";
import DPickFilesButton from "discourse/ui-kit/d-pick-files-button";
import { i18n } from "discourse-i18n";

export default class BlogThemeImport extends Component {
  @service router;

  #formApi;

  @action
  registerApi(api) {
    this.#formApi = api;
  }

  @action
  selectFile(field, files) {
    field.set(files[0]);
  }

  @action
  async importTheme(data) {
    let requestData;
    if (data.source === "file") {
      requestData = new FormData();
      requestData.append("file", data.file);
    } else {
      requestData = { repository: data.repository, branch: data.branch };
    }

    try {
      const theme = await ajax("/blog/themes/import.json", {
        type: "POST",
        data: requestData,
        ...(data.source === "file"
          ? { processData: false, contentType: false }
          : {}),
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
    <section class="blog-theme-import admin-detail" ...attributes>
      <DBreadcrumbsItem
        @path="/admin/plugins/discourse-blog/themes/import/new"
        @label={{i18n "discourse_blog.admin.import"}}
      />
      <DPageSubheader
        @titleLabel={{i18n "discourse_blog.admin.import"}}
        @descriptionLabel={{i18n "discourse_blog.admin.import_description"}}
      />
      <Form
        class="blog-theme-import__form"
        @data={{hash source="git"}}
        @onRegisterApi={{this.registerApi}}
        @onSubmit={{this.importTheme}}
        as |form data|
      >
        <form.Field
          @name="source"
          @title={{i18n "discourse_blog.admin.import_source"}}
          @type="radio-group"
          @validation="required"
          as |field|
        >
          <field.Control as |group|>
            <group.Radio @value="git">{{i18n
                "discourse_blog.admin.import_git"
              }}</group.Radio>
            <group.Radio @value="file">{{i18n
                "discourse_blog.admin.import_file"
              }}</group.Radio>
          </field.Control>
        </form.Field>
        {{#if (eq data.source "git")}}
          <form.Field
            @description={{i18n "discourse_blog.admin.git_description"}}
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
        {{else}}
          <form.Field
            @description={{i18n "discourse_blog.admin.import_file_description"}}
            @name="file"
            @title={{i18n "discourse_blog.admin.theme_file"}}
            @type="custom"
            @validation="required"
            as |field|
          >
            <field.Control>
              <DPickFilesButton
                @acceptedFormatsOverride=".zip"
                @fileInputDisabled={{field.disabled}}
                @fileInputId={{field.id}}
                @label="discourse_blog.admin.choose_theme_file"
                @onFilesPicked={{fn this.selectFile field}}
                @showButton={{true}}
              />
              {{#if field.value}}
                <p class="blog-theme-import__filename">{{field.value.name}}</p>
              {{/if}}
            </field.Control>
          </form.Field>
        {{/if}}
        <form.Actions><form.Submit
            @label="discourse_blog.admin.import"
          /></form.Actions>
      </Form>
    </section>
  </template>
}
