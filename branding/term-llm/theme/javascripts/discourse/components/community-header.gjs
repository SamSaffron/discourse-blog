import Component from "@glimmer/component";
import { service } from "@ember/service";
import { settings, themePrefix } from "virtual:theme";
import EmbedMode from "discourse/lib/embed-mode";
import { i18n } from "discourse-i18n";

export default class CommunityHeader extends Component {
  @service router;

  get isHomepage() {
    return [
      "discovery.latest",
      "discovery.categories",
      "discovery.top",
    ].includes(this.router.currentRouteName);
  }

  get visible() {
    return (
      !EmbedMode.enabled && !this.router.currentRouteName?.startsWith("admin")
    );
  }

  <template>
    {{#if this.visible}}
      <div class="term-community">
        <nav
          class="term-community__nav"
          aria-label={{i18n (themePrefix "navigation")}}
        >
          <a href={{settings.product_url}}>{{i18n (themePrefix "product")}}</a>
          <a href={{settings.blog_url}}>{{i18n (themePrefix "blog")}}</a>
          <a href={{settings.docs_url}}>{{i18n (themePrefix "docs")}}</a>
          <a href={{settings.source_url}}>{{i18n (themePrefix "source")}} ↗</a>
        </nav>
        {{#if this.isHomepage}}
          <section class="term-community__hero">
            <div class="term-community__copy">
              <p class="term-community__eyebrow">{{i18n
                  (themePrefix "eyebrow")
                }}</p>
              <h1>{{i18n (themePrefix "headline")}}</h1>
              <p class="term-community__description">{{i18n
                  (themePrefix "description")
                }}</p>
              <div class="term-community__links">
                <a class="btn btn-primary" href={{settings.docs_url}}>{{i18n
                    (themePrefix "start")
                  }}</a>
                <a href={{settings.blog_url}}>{{i18n (themePrefix "stories")}}
                  →</a>
              </div>
            </div>
            <div class="term-community__terminal">
              <p>{{i18n (themePrefix "terminal_label")}}</p>
              <code><span aria-hidden="true">$ </span>term-llm serve web</code>
              <p class="term-community__terminal-note">{{i18n
                  (themePrefix "terminal_note")
                }}</p>
            </div>
          </section>
        {{/if}}
      </div>
    {{/if}}
  </template>
}
