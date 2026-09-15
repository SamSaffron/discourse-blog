import DButton from "discourse/ui-kit/d-button";
import DConditionalLoadingSpinner from "discourse/ui-kit/d-conditional-loading-spinner";
import DModal from "discourse/ui-kit/d-modal";
import DNativeSelect from "discourse/ui-kit/d-native-select";
import { i18n } from "discourse-i18n";

const BlogThemePreview = <template>
  {{#let @model.editor as |editor|}}
    <DModal
      class="--max blog-theme-preview"
      @title={{i18n "discourse_blog.admin.preview_short"}}
      @closeModal={{@closeModal}}
    >
      <:body>
        <p class="blog-theme-preview__hint">{{i18n
            "discourse_blog.admin.working_preview_hint"
          }}</p>
        <div class="blog-theme-preview__controls">
          <DNativeSelect
            aria-label={{i18n "discourse_blog.admin.preview_page"}}
            @value={{editor.previewPage}}
            @includeNone={{false}}
            @onChange={{editor.selectPreviewPage}}
            as |select|
          >
            <select.Option @value="index">{{i18n
                "discourse_blog.admin.preview_home"
              }}</select.Option>
            <select.Option @value="archive">{{i18n
                "discourse_blog.admin.preview_archive"
              }}</select.Option>
            <select.Option @value="article">{{i18n
                "discourse_blog.admin.preview_article"
              }}</select.Option>
            <select.Option @value="about">{{i18n
                "discourse_blog.admin.template_about"
              }}</select.Option>
            <select.Option @value="not_found">{{i18n
                "discourse_blog.admin.template_not_found"
              }}</select.Option>
          </DNativeSelect>
          <DNativeSelect
            aria-label={{i18n "discourse_blog.admin.sample_article"}}
            @includeNone={{false}}
            @value={{editor.selectedArticle}}
            @onChange={{editor.selectPreviewArticle}}
            as |select|
          >{{#each editor.articleOptions as |article|}}<select.Option
                @value={{article.id}}
              >{{article.title}}</select.Option>{{/each}}</DNativeSelect>
          <DNativeSelect
            aria-label={{i18n "discourse_blog.admin.preview_size"}}
            @value={{editor.previewDevice}}
            @includeNone={{false}}
            @onChange={{editor.selectDevice}}
            as |select|
          ><select.Option @value="desktop">{{i18n
                "discourse_blog.admin.desktop"
              }}</select.Option><select.Option @value="mobile">{{i18n
                "discourse_blog.admin.mobile"
              }}</select.Option></DNativeSelect>
          <DConditionalLoadingSpinner
            @condition={{editor.busy}}
            @size="small"
          />
        </div>
        {{#if editor.previewUnavailable}}
          <p class="blog-theme-preview__empty">{{i18n
              "discourse_blog.admin.preview_article_unavailable"
            }}</p>
        {{else}}
          {{#if editor.previewUrl}}
            <div class="blog-theme-preview__scroll"><iframe
                class="blog-theme-preview__frame"
                data-size={{editor.previewDevice}}
                src={{editor.previewUrl}}
                title={{i18n "discourse_blog.admin.preview_short"}}
                sandbox="allow-scripts allow-same-origin allow-forms"
              ></iframe></div>
            <p class="blog-theme-preview__link"><a
                href={{editor.previewUrl}}
                target="_blank"
                rel="noopener noreferrer"
              >{{i18n "discourse_blog.admin.open_working_preview"}}</a></p>
          {{/if}}
        {{/if}}
      </:body>
      <:footer>
        <DButton @label="close" @action={{@closeModal}} />
      </:footer>
    </DModal>
  {{/let}}
</template>;

export default BlogThemePreview;
