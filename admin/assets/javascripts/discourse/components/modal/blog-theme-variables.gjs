import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import DButton from "discourse/ui-kit/d-button";
import DFilterInput from "discourse/ui-kit/d-filter-input";
import DModal from "discourse/ui-kit/d-modal";
import DNativeSelect from "discourse/ui-kit/d-native-select";
import { i18n } from "discourse-i18n";

export default class BlogThemeVariables extends Component {
  get editor() {
    return this.args.model.editor;
  }

  @action
  insert(variable) {
    this.editor.insertVariable(variable);
    this.args.closeModal();
  }

  <template>
    <DModal
      class="blog-theme-variables"
      @title={{i18n "discourse_blog.admin.variable_reference"}}
      @closeModal={{@closeModal}}
    >
      <:body>
        <p class="blog-theme-variables__hint">{{i18n
            "discourse_blog.admin.insert_hint"
          }}</p>
        <div class="blog-theme-variables__controls">
          <DFilterInput
            placeholder={{i18n "discourse_blog.admin.find_variable"}}
            aria-label={{i18n "discourse_blog.admin.find_variable"}}
            @value={{this.editor.variableQuery}}
            @filterAction={{this.editor.filterVariables}}
            {{on "keydown" this.editor.preventSearchSubmit}}
          />
          <DNativeSelect
            aria-label={{i18n "discourse_blog.admin.sample_article"}}
            @includeNone={{false}}
            @value={{this.editor.selectedArticle}}
            @onChange={{this.editor.selectArticle}}
            as |select|
          >{{#each this.editor.articleOptions as |article|}}<select.Option
                @value={{article.id}}
              >{{article.title}}</select.Option>{{/each}}</DNativeSelect>
        </div>
        <ul class="blog-theme-variables__list">
          {{#each this.editor.variables as |variable|}}
            <li
              class="blog-theme-variables__item"
              data-variable={{variable.path}}
            >
              <div class="blog-theme-variables__header">
                <code
                  class="blog-theme-variables__path"
                >{{variable.path}}</code>
                <span
                  class="blog-theme-variables__type"
                >{{variable.type}}</span>
                <DButton
                  class="btn-default btn-small blog-theme-variables__insert"
                  @action={{fn this.insert variable}}
                  @label="discourse_blog.admin.insert"
                />
              </div>
              <pre
                class="blog-theme-variables__example"
              >{{variable.example}}</pre>
            </li>
          {{else}}
            <li class="blog-theme-variables__empty">{{i18n
                "discourse_blog.admin.no_variables"
              }}</li>
          {{/each}}
        </ul>
      </:body>
      <:footer>
        <DButton @label="close" @action={{@closeModal}} />
      </:footer>
    </DModal>
  </template>
}
