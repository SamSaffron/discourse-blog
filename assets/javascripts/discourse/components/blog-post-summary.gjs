import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { uniqueId } from "@ember/helper";
import { action } from "@ember/object";
import { service } from "@ember/service";
import EmbedMode from "discourse/lib/embed-mode";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";

const EXPANSION_KEY = "discourse-blog-article-expanded";

export default class BlogPostSummary extends Component {
  @service router;
  @service siteSettings;

  @tracked _expanded = false;

  get article() {
    return this.args.outletArgs.post.blog_article;
  }

  get expanded() {
    return (
      this.args.outletArgs.decoratorState?.get(EXPANSION_KEY) ?? this._expanded
    );
  }

  get showSummary() {
    const params = new URLSearchParams(this.router.currentURL?.split("?")[1]);
    return (
      this.siteSettings.discourse_blog_enabled &&
      !EmbedMode.enabled &&
      this.args.outletArgs.post.post_number === 1 &&
      this.article &&
      !params.has("search") &&
      !params.has("context") &&
      !window.location.hash.startsWith("#p-")
    );
  }

  @action
  toggleExpanded() {
    this._expanded = !this.expanded;
    this.args.outletArgs.decoratorState?.set(EXPANSION_KEY, this._expanded);
  }

  <template>
    {{#let (uniqueId) as |contentId|}}
      {{#if this.showSummary}}
        <div class="blog-post-summary">
          <p class="blog-post-summary__label">{{i18n
              "discourse_blog.article_summary.from_blog"
              blog=this.article.blog_name
            }}</p>
          {{#unless this.expanded}}
            <p class="blog-post-summary__excerpt">{{this.article.excerpt}}</p>
          {{/unless}}
          <div class="blog-post-summary__actions">
            <a href={{this.article.url}}>{{i18n
                "discourse_blog.article_summary.read"
              }}
              ↗</a>
            <DButton
              class="btn-default"
              aria-controls={{contentId}}
              aria-expanded={{if this.expanded "true" "false"}}
              @action={{this.toggleExpanded}}
              @label={{if
                this.expanded
                "discourse_blog.article_summary.collapse"
                "discourse_blog.article_summary.expand"
              }}
            />
          </div>
        </div>
        <div id={{contentId}} hidden={{unless this.expanded true}}>
          {{#if this.expanded}}{{yield}}{{/if}}
        </div>
      {{else}}
        {{yield}}
      {{/if}}
    {{/let}}
  </template>
}
