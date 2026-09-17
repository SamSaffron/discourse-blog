# frozen_string_literal: true

# name: discourse-blog
# about: A lightweight publication with Discourse authoring and live discussion.
# version: 0.1.0
# authors: Discourse
# required_version: 3.6.0

enabled_site_setting :discourse_blog_enabled
register_asset "stylesheets/blog-editor.scss"
register_asset "stylesheets/blog-publication-panel.scss"
register_asset "stylesheets/blog-review.scss"
register_asset "stylesheets/blog-post-summary.scss"
register_asset "stylesheets/blog-discussion.scss"
register_asset "stylesheets/admin/blog-admin.scss", :admin
register_svg_icon "pen-to-square"
add_admin_route "discourse_blog.admin.title", "discourse-blog", use_new_show_route: true

module ::DiscourseBlog
  PLUGIN_NAME = "discourse-blog"
end

require_relative "lib/discourse_blog/engine"
require_relative "lib/discourse_blog/color_validator"

after_initialize do
  add_to_serializer(:current_user, :can_blog_edit) do
    DiscourseBlog::Configuration.contributor?(object)
  end
  reloadable_patch { ::Guardian.prepend(DiscourseBlog::GuardianExtensions) }
  reloadable_patch { ::Topic.prepend(DiscourseBlog::TopicExtensions) }
  if defined?(::Middleware::EnforceHostname)
    reloadable_patch do
      ::Middleware::EnforceHostname.prepend(DiscourseBlog::EnforceHostnameExtension)
    end
  end

  Rails.application.config.filter_parameters += [:review_token]

  add_model_callback(:topic, :before_destroy) do
    DiscourseBlog::Review.where(topic_id: id).find_each(&:destroy!)
    DiscourseBlog::Publication
      .where(topic_id: id)
      .or(DiscourseBlog::Publication.where(draft_topic_id: id))
      .or(DiscourseBlog::Publication.where(discussion_topic_id: id))
      .find_each(&:destroy!)
  end

  add_model_callback(:topic, :validate) do
    if category_id_changed? && persisted? &&
         category_id_in_database == SiteSetting.discourse_blog_drafts_category.to_i
      errors.add(:category_id, I18n.t("discourse_blog.editorial.private_source"))
    end
  end

  add_model_callback(:post, :after_update) do
    if post_number == 1 &&
         ((saved_change_to_hidden? && hidden?) || (saved_change_to_deleted_at? && deleted_at))
      DiscourseBlog::Review.revoke_for_topic!(topic_id)
    end
  end

  add_model_callback(:topic, :after_update) do
    if saved_change_to_category_id? || saved_change_to_deleted_at? || saved_change_to_archetype? ||
         saved_change_to_visible?
      DiscourseBlog::Review.revoke_for_topic!(id)
    end
  end

  add_to_serializer(
    :post,
    :blog_article,
    include_condition: -> do
      object.is_first_post? && object.word_count.to_i >= 250 &&
        DiscourseBlog::Configuration.public_enabled? &&
        object.topic.category_id == SiteSetting.discourse_blog_category.to_i
    end,
  ) do
    if publication =
         DiscourseBlog::Publication.publicly_visible.find_by(discussion_topic_id: object.topic_id)
      {
        url: publication.url,
        excerpt: publication.display_excerpt,
        blog_name: SiteSetting.discourse_blog_title,
      }
    end
  end

  add_to_serializer(
    :topic_view,
    :blog_publication,
    include_condition: -> { !blog_publication.nil? },
  ) do
    unless instance_variable_defined?(:@discourse_blog_publication)
      @discourse_blog_publication =
        DiscourseBlog::PublicationEntry.for_viewer(object.topic, scope.user)
    end
    @discourse_blog_publication
  end

  Discourse::Application.routes.prepend do
    constraints(
      ->(request) do
        DiscourseBlog::Configuration.blog_host?(request) &&
          !DiscourseBlog::Configuration.asset_path?(request.path)
      end,
    ) do
      get "/session/csrf" => "discourse_blog/review_reader#csrf"
      get "/review" => "discourse_blog/review_reader#show"
      post "/review/feedback" => "discourse_blog/review_reader#feedback"
      get "/" => "discourse_blog/articles#index"
      get "/posts" => redirect { "#{DiscourseBlog::Configuration.origin}/" }, :format => false
      %w[/posts.rss /posts.atom].each do |path|
        get path => redirect { "#{DiscourseBlog::Configuration.origin}/feed.xml" }, :format => false
      end
      get "/archive" => "discourse_blog/articles#index", :defaults => { archive: true }
      get "/tag/:tag" => "discourse_blog/articles#index"
      get "/about" => "discourse_blog/articles#about"
      get "/blog-theme.css" => "discourse_blog/articles#theme_css", :format => false
      get "/blog-highlight/:version.js" => "discourse_blog/articles#highlight_js", :format => false
      get "/blog-custom.js" => "discourse_blog/articles#theme_js", :format => false
      get "/feed.xml" => "discourse_blog/articles#feed",
          :defaults => {
            format: "rss",
          },
          :format => false
      get "/sitemap" => "discourse_blog/articles#sitemap",
          :format => true,
          :constraints => {
            format: :xml,
          }
      get "/robots.txt" => "discourse_blog/articles#robots",
          :defaults => {
            format: "text",
          },
          :format => false
      get "/*path" => "discourse_blog/articles#show", :format => false
    end
    %w[appearance identity themes themes/new themes/import/new themes/:id/edit].each do |path|
      get "/admin/plugins/discourse-blog/#{path}" => "admin/plugins#show",
          :defaults => {
            plugin_id: "discourse-blog",
          },
          :constraints => AdminConstraint.new
    end
    mount ::DiscourseBlog::Engine, at: "/"
  end

  reloadable_patch { ::TopicView.prepend(DiscourseBlog::TopicViewExtension) }
end
