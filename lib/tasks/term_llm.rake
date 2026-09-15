# frozen_string_literal: true

namespace :discourse_blog do
  desc "Apply the term-llm brand and editorial content to the local demo"
  task brand_term_llm: :environment do
    abort "Brand setup is only available in development" unless Rails.env.development?

    root = Rails.root.join("plugins/discourse-blog/branding/term-llm")
    admin = User.find_by!(username: "admin")
    content = JSON.parse(root.join("content.json").read)
    DiscourseBlog::Configuration.ensure_ready!
    seeded =
      Topic
        .joins(:_custom_fields)
        .where(topic_custom_fields: { name: "discourse_blog_demo_community" })
        .order(:id)
        .to_a
    unless seeded.length == content.fetch("topics").length
      abort "Run discourse_blog:demo and discourse_blog:seed_community before branding this site."
    end
    publications =
      content
        .fetch("articles")
        .map do |article|
          DiscourseBlog::Publication.find_by(path: article.fetch("path")) ||
            DiscourseBlog::Publication.find_by(path: article.fetch("old_path")) ||
            abort("Missing demo article. Run discourse_blog:demo before branding this site.")
        end
    existing_theme = Theme.find_by(name: "term-llm Community")
    theme =
      RemoteTheme.import_theme_from_directory(root.join("theme").to_s, theme_id: existing_theme&.id)
    theme.update!(
      color_scheme_id: ColorScheme.find_by!(name: "term-llm Light").id,
      dark_color_scheme_id: ColorScheme.find_by!(name: "term-llm Dark").id,
    )
    theme.update_setting("blog_url", SiteSetting.discourse_blog_url)
    theme.set_default!
    result =
      Themes::ThemeSiteSettingManager.call(
        params: {
          theme_id: theme.id,
          name: "enable_welcome_banner",
          value: false,
        },
        guardian: admin.guardian,
      )
    raise "Could not configure the theme welcome banner" if result.failure?
    SiteSetting.enable_site_owner_onboarding = false

    SiteSetting.title = "term-llm"
    SiteSetting.site_description =
      "The term-llm community. Ask questions, share agent workflows, and build better terminal-first AI together."
    SiteSetting.short_site_description = "Your workflow. Our workshop."
    SiteSetting.logo = ""
    icon =
      File.open(root.join("favicon.svg")) do |file|
        UploadCreator.new(file, "term-llm.svg", type: "branding").create_for(admin.id)
      end
    raise icon.errors.full_messages.join(", ") unless icon.persisted?
    SiteSetting.logo_small = icon
    SiteSetting.favicon = icon
    SiteSetting.discourse_blog_title = "term-llm"
    SiteSetting.discourse_blog_description =
      "Field notes for a workflow that is yours. Practical ideas for terminal-first AI, the browser workspace, and the people building with it."
    SiteSetting.discourse_blog_accent_color = "16634e"
    SiteSetting.discourse_blog_paper_color = "fcfcfa"
    SiteSetting.discourse_blog_ink_color = "222b28"
    SiteSetting.discourse_blog_custom_css = root.join("blog.css").read
    SiteSetting.discourse_blog_custom_js = ""
    SiteSetting.discourse_blog_about = <<~MD
      ## Your workflow. Not one provider’s workflow.

      term-llm is an open-source, MIT-licensed AI runtime for your terminal, with a browser workspace served from your own machine. Review code, edit files, research questions, and automate repeatable work with your choice of models.

      This is the project's blog and community: a place for useful explanations, honest trade-offs, and workflows other people can reproduce.

      ### Find your next step

      - [Explore term-llm](https://term-llm.com)
      - [Follow the quickstart](https://term-llm.com/getting-started/quickstart/)
      - [Browse the source and contribute](https://github.com/SamSaffron/term-llm)
      - [Ask a question or share a workflow](#{Discourse.base_url})

      ### Powerful tools. Explicit controls.

      Running the application locally is not a promise that every request stays local. Check your model, tool, search, and review routing before using sensitive data. Keep credentials and private project material out of public posts.

      Be specific, be kind, and help the next person understand what you learned.
    MD

    categories = {}
    {
      "Help" => [
        "16634E",
        "Get unstuck with installation, providers, permissions, and the web workspace. Include a minimal reproduction and remove secrets from logs.",
      ],
      "Workflows" => [
        "527D64",
        "Share reproducible agent workflows, shell pipelines, MCP integrations, and workspace ideas. Explain the task, the permissions, and the trade-offs.",
      ],
      "Feedback" => [
        "866280",
        "Suggest product and community improvements. Explain the problem, who it affects, and what you have tried. Use Help for troubleshooting and Development for reproducible bugs.",
      ],
      "Development" => [
        "637B91",
        "Discuss reproducible bugs, focused feature proposals, tests, and documentation improvements. Source and pull requests live on GitHub.",
      ],
    }.each_with_index do |(name, (color, description)), index|
      category =
        Category.find_by(name: name) ||
          (Category.find_by(id: SiteSetting.meta_category_id) if name == "Feedback") ||
          Category.create!(name: name, user: admin)
      category.update!(color: color, text_color: "FFFFFF", position: index + 1)
      if category.description != description
        category.topic.first_post.revise(admin, raw: description, skip_validations: true)
      end
      categories[name] = category
    end

    welcome = Topic.find_by(id: SiteSetting.welcome_topic_id)
    if welcome
      welcome_raw = <<~MD
        Welcome to the term-llm community. **Your workflow. Our workshop.**

        term-llm is open source, terminal-first, and browser-ready. This is a place to ask practical questions, share reproducible workflows, and help improve the project.

        - **New here?** Follow the [quickstart](https://term-llm.com/getting-started/quickstart/) and introduce the task you want to work on.
        - **Need help?** Post in [Help](/c/#{categories.fetch("Help").slug}/#{categories.fetch("Help").id}) with your version, provider, command, and a minimal reproduction. Never include credentials.
        - **Have something useful?** Share it in Workflows. Explain the model, tools, permissions, and how you check the result.
        - **Want to contribute?** Discuss ideas in Development and find the [source, issues, and pull requests on GitHub](https://github.com/SamSaffron/term-llm).
        - **Prefer a longer read?** Visit [the blog](#{SiteSetting.discourse_blog_url}).

        Be specific. Be kind. Make it easier for the next person to learn.
      MD
      if welcome.first_post.raw != welcome_raw
        welcome.first_post.revise(
          admin,
          { raw: welcome_raw, category_id: categories.fetch("Help").id },
          skip_validations: true,
        )
      end
    end

    SiteSetting.default_navigation_menu_categories =
      (categories.values.map(&:id) + [SiteSetting.discourse_blog_category]).join("|")
    Category.find(SiteSetting.discourse_blog_category).update!(
      color: "16634E",
      text_color: "FFFFFF",
    )

    content
      .fetch("articles")
      .each_with_index do |article, index|
        publication = publications.fetch(index)
        post = publication.topic.first_post
        if post.raw != article.fetch("raw") || publication.topic.title != article.fetch("title")
          post.revise(
            admin,
            { raw: article.fetch("raw"), title: article.fetch("title") },
            skip_validations: true,
          )
        end
        publication.save_metadata!(
          admin,
          path: article.fetch("path"),
          excerpt: article.fetch("excerpt"),
        )
        publication
          .topic
          .posts
          .where(
            "raw LIKE ? OR raw LIKE ?",
            "%Sample conversation for the demo blog.%",
            "%Example discussion, seeded for this development community.%",
          )
          .order(:post_number)
          .each_with_index do |reply, reply_index|
            text = article.fetch("replies")[reply_index]
            next unless text
            raw = "#{text}\n\n*Example discussion, seeded for this development community.*"
            reply.revise(admin, { raw: raw }, skip_validations: true) if reply.raw != raw
          end
      end

    content
      .fetch("topics")
      .each_with_index do |(category_name, title, body), index|
        topic = seeded.fetch(index)
        raw =
          "#{body}\n\n*Starter topic for the development community; not a report of an actual incident.*"
        if topic.title != title || topic.first_post.raw != raw ||
             topic.category_id != categories.fetch(category_name).id
          topic.first_post.revise(
            admin,
            { title: title, raw: raw, category_id: categories.fetch(category_name).id },
            skip_validations: true,
          )
        end
      end

    Rake::Task["discourse_blog:organize_term_llm"].reenable
    Rake::Task["discourse_blog:organize_term_llm"].invoke

    puts "Applied term-llm branding. Theme #{theme.id}; #{content.fetch("articles").length} articles; #{seeded.length} starter topics."
  end
end
