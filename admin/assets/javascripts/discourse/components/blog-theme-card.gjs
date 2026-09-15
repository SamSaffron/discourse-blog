import Component from "@glimmer/component";
import { array, concat } from "@ember/helper";
import { action } from "@ember/object";
import { LinkTo } from "@ember/routing";
import { service } from "@ember/service";
import AdminConfigAreaCard from "discourse/admin/components/admin-config-area-card";
import ThemeCardPreview from "discourse/components/theme-card-preview";
import DMenu from "discourse/float-kit/components/d-menu";
import DButton from "discourse/ui-kit/d-button";
import DDropdownMenu from "discourse/ui-kit/d-dropdown-menu";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";
import BlogThemeThumbnail from "./blog-theme-thumbnail";

export default class BlogThemeCard extends Component {
  @service blogThemeActions;
  @service router;

  get isActive() {
    return this.args.theme.id === this.args.activeThemeId;
  }

  @action
  activate() {
    this.blogThemeActions.activate(this.args.theme, {
      onActivated: () => this.router.refresh(),
    });
  }

  @action
  pull() {
    this.blogThemeActions.pull(this.args.theme, {
      onPulled: () => this.router.refresh(),
    });
  }

  @action
  remove() {
    this.blogThemeActions.remove(this.args.theme, {
      onRemoved: () => this.router.refresh(),
    });
  }

  <template>
    <AdminConfigAreaCard class="theme-card" data-theme-id={{@theme.id}}>
      <:content>
        <ThemeCardPreview @theme={{@theme}}>
          <:placeholder>
            <BlogThemeThumbnail @theme={{@theme}} @label={{@theme.name}} />
          </:placeholder>

          <:title>
            <LinkTo
              class="theme-card__title"
              @route="adminPlugins.show.discourse-blog-themes.edit"
              @model={{@theme.id}}
            >{{@theme.name}}</LinkTo>
            <p class="theme-card__description">{{i18n
                "discourse_blog.admin.revision"
              }}
              {{@theme.revision}}</p>
          </:title>

          <:footer>
            <div class="theme-card__footer">
              <div class="theme-card__badges">
                {{#if this.isActive}}
                  <span class="theme-card__badge">{{dIcon "circle-check"}}
                    {{i18n "discourse_blog.admin.active"}}</span>
                {{/if}}
                {{#if @theme.locally_modified}}
                  <span class="theme-card__badge">{{dIcon "pencil"}}
                    {{i18n "discourse_blog.admin.local_edits_badge"}}</span>
                {{/if}}
              </div>

              <div class="theme-card__controls">
                <DButton
                  class="btn-default theme-card__button edit"
                  @route="adminPlugins.show.discourse-blog-themes.edit"
                  @routeModels={{array @theme.id}}
                  @translatedLabel={{i18n "discourse_blog.admin.edit"}}
                  @preventFocus={{true}}
                />

                <div class="theme-card__footer-actions">
                  <DMenu
                    @identifier={{concat "blog-theme-actions-" @theme.id}}
                    @triggerClass="theme-card__footer-menu btn-flat"
                    @icon="ellipsis"
                    @title={{i18n "discourse_blog.admin.theme_actions"}}
                    @modalForMobile={{true}}
                  >
                    <:content>
                      <DDropdownMenu as |dropdown|>
                        <dropdown.item>
                          <DButton
                            class="theme-card__button btn-transparent"
                            @action={{this.activate}}
                            @icon="play"
                            @disabled={{this.isActive}}
                            @translatedLabel={{i18n
                              "discourse_blog.admin.activate"
                            }}
                            @preventFocus={{true}}
                          />
                        </dropdown.item>

                        {{#if @theme.source}}
                          <dropdown.item>
                            <DButton
                              class="theme-card__button btn-transparent"
                              @action={{this.pull}}
                              @icon="cloud-arrow-down"
                              @translatedLabel={{i18n
                                "discourse_blog.admin.pull_git"
                              }}
                              @preventFocus={{true}}
                            />
                          </dropdown.item>
                        {{/if}}

                        <dropdown.item>
                          <a
                            class="btn btn-transparent theme-card__button preview"
                            href={{@theme.preview_url}}
                            target="_blank"
                            rel="noopener noreferrer"
                          >{{dIcon "eye"}}
                            {{i18n "discourse_blog.admin.preview"}}</a>
                        </dropdown.item>

                        <dropdown.item>
                          <DButton
                            class="theme-card__button btn-transparent --danger"
                            @action={{this.remove}}
                            @icon="trash-can"
                            @disabled={{this.isActive}}
                            @translatedLabel={{i18n
                              "discourse_blog.admin.delete_theme"
                            }}
                            @preventFocus={{true}}
                          />
                        </dropdown.item>
                      </DDropdownMenu>
                    </:content>
                  </DMenu>
                </div>
              </div>
            </div>
          </:footer>
        </ThemeCardPreview>
      </:content>
    </AdminConfigAreaCard>
  </template>
}
