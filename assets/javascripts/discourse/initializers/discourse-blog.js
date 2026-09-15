import { getOwner } from "@ember/owner";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import EmbedMode from "discourse/lib/embed-mode";
import { withPluginApi } from "discourse/lib/plugin-api";
import { registerTopicFooterButton } from "discourse/lib/register-topic-footer-button";
import { i18n } from "discourse-i18n";
import BlogPublication from "../components/modal/blog-publication";

export default {
  name: "discourse-blog",

  initialize(container) {
    const settings = container.lookup("service:site-settings");
    if (!settings.discourse_blog_enabled) {
      return;
    }
    withPluginApi((api) => {
      if (api.getCurrentUser()?.can_blog_edit ?? api.getCurrentUser()?.staff) {
        api.addCommunitySectionLink({
          name: "blog-editor",
          route: "blog-editor",
          icon: "pen-to-square",
          title: i18n("discourse_blog.editor_title"),
          text: i18n("discourse_blog.editor_title"),
        });
      }
    });
    registerTopicFooterButton({
      id: "blog-publication",
      icon: "pen-to-square",
      label: "discourse_blog.manage",
      title: "discourse_blog.manage",
      displayed() {
        return (
          !EmbedMode.enabled &&
          (this.currentUser?.can_blog_edit ?? this.currentUser?.staff) &&
          !this.topic?.isPrivateMessage &&
          [
            Number(settings.discourse_blog_category),
            Number(settings.discourse_blog_drafts_category),
          ].includes(this.topic?.category_id)
        );
      },
      async action() {
        try {
          const publication = await ajax(
            `/blog/publications/${this.topic.id}.json`
          );
          getOwner(this).lookup("service:modal").show(BlogPublication, {
            model: { publication },
          });
        } catch (error) {
          popupAjaxError(error);
        }
      },
    });
  },
};
