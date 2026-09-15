import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "discourse-blog-admin-navigation",

  initialize(container) {
    if (!container.lookup("service:current-user")?.admin) {
      return;
    }
    withPluginApi((api) => {
      api.setAdminPluginIcon("discourse-blog", "pen-to-square");
      api.addAdminPluginConfigurationNav("discourse-blog", [
        {
          label: "discourse_blog.admin.themes",
          route: "adminPlugins.show.discourse-blog-themes",
          description: "discourse_blog.admin.themes_description",
        },
        {
          label: "discourse_blog.admin.identity_tab",
          route: "adminPlugins.show.discourse-blog-identity",
          description: "discourse_blog.admin.identity_description",
        },
      ]);
    });
  },
};
