import DBreadcrumbsItem from "discourse/ui-kit/d-breadcrumbs-item";
import DEmptyState from "discourse/ui-kit/d-empty-state";
import DPageSubheader from "discourse/ui-kit/d-page-subheader";
import { i18n } from "discourse-i18n";
import BlogThemeCard from "../../../../components/blog-theme-card";

export default <template>
  <section class="blog-themes">
    <DBreadcrumbsItem
      @path="/admin/plugins/discourse-blog/themes"
      @label={{i18n "discourse_blog.admin.themes"}}
    />
    <DPageSubheader
      @titleLabel={{i18n "discourse_blog.admin.themes"}}
      @descriptionLabel={{i18n "discourse_blog.admin.themes_index_description"}}
    >
      <:actions as |actions|>
        <actions.Default
          @route="adminPlugins.show.discourse-blog-themes.import"
          @label="discourse_blog.admin.import"
        />
        <actions.Primary
          @route="adminPlugins.show.discourse-blog-themes.new"
          @label="discourse_blog.admin.new_theme_short"
        />
      </:actions>
    </DPageSubheader>
    {{#if @model.themes.length}}
      <div class="themes-cards-container">
        {{#each @model.themes key="id" as |theme|}}
          <BlogThemeCard @theme={{theme}} @activeThemeId={{@model.active.id}} />
        {{/each}}
      </div>
    {{else}}
      <DEmptyState
        @title={{i18n "discourse_blog.admin.no_themes"}}
        @body={{i18n "discourse_blog.admin.no_themes_description"}}
      />
    {{/if}}
  </section>
</template>
