# frozen_string_literal: true

namespace :discourse_blog do
  desc "Organize the local term-llm forum into five public categories"
  task organize_term_llm: :environment do
    abort "Category setup is only available in development" unless Rails.env.development?
    DiscourseBlog::Configuration.ensure_ready!
    admin = User.find_by!(username: "admin")
    logger = StaffActionLogger.new(admin)
    publication_category = Category.find(SiteSetting.discourse_blog_category)
    help = Category.find_by!(name: "Help")
    workflows = Category.find_by!(name: "Workflows")
    feedback = Category.find_by(name: "Feedback") || Category.find(SiteSetting.meta_category_id)
    development = Category.find_by!(name: "Development")
    uncategorized =
      Category.find_by(id: SiteSetting.uncategorized_category_id) ||
        Category.find_by!(name: "Uncategorized")
    providers = Category.find_by(name: "Providers")
    general = Category.find_by(name: "General")

    if general &&
         (
           Topic.where(category_id: general.id).where.not(id: general.topic_id).exists? ||
             general.has_children?
         )
      abort "General is no longer empty; classify its topics before removing it."
    end
    if providers && (providers.read_restricted || providers.has_children?)
      abort "Providers must be public and have no subcategories before merging it into Help."
    end

    public_categories = [publication_category, help, workflows, feedback, development]
    if public_categories.any?(&:read_restricted)
      abort "Refusing to make an existing private category public. Review its contents first."
    end
    descriptions = [
      [
        "Blog",
        "Project news, releases, and articles from the term-llm blog. Staff start topics here; everyone is welcome to ask questions and reply. For setup problems, use Help.",
        "16634E",
      ],
      [
        "Help",
        "Get help with installation, model providers, local models, the terminal, browser workspace, tools, and permissions. Include your version, command, expected behavior, and a minimal example. Redact credentials and private data. Confirmed reproducible bugs belong in Development.",
        "527D64",
      ],
      [
        "Workflows",
        "Show how you use term-llm: agents, instructions, shell pipelines, MCP integrations, widgets, and automation. Share a reproducible example, required permissions, and how you check the result. Use Help if you are stuck, or Feedback to propose a capability that does not exist yet.",
        "7D7755",
      ],
      [
        "Feedback",
        "Suggest improvements to term-llm or this community. Start with the problem, who it affects, and what you have tried. Feature proposals and usability feedback belong here; troubleshooting belongs in Help and reproducible bugs in Development.",
        "866280",
      ],
      [
        "Development",
        "Coordinate contributions, discuss reproducible bugs, and improve tests and documentation. Include minimal reproduction steps for bugs and link to related GitHub issues or pull requests. Use Feedback for feature ideas and Help for setup questions.",
        "637B91",
      ],
    ]
    moved = []

    Category.transaction do
      public_categories.each_with_index do |category, index|
        name, description, color = descriptions.fetch(index)
        category.name = name
        category.slug = name.downcase
        category.position = index
        category.color = color
        category.text_color = "FFFFFF"
        category.set_permissions(
          everyone: category == publication_category ? :create_post : :full,
          staff: :full,
        )
        category.save!
        if category.topic.first_post.raw != description
          unless category.topic.first_post.revise(
                   admin,
                   { raw: description },
                   skip_validations: true,
                 )
            raise "Could not update the #{name} category description"
          end
        end
      end

      if providers
        Topic
          .where(category_id: providers.id)
          .where.not(id: providers.topic_id)
          .find_each do |topic|
            raise "Could not move topic #{topic.id}" unless topic.change_category_to_id(help.id)
            moved << topic.id
          end
      end

      Topic
        .joins(:_custom_fields)
        .where(
          topic_custom_fields: {
            name: "discourse_blog_demo_community",
          },
          title: "Feature ideas: begin with the problem",
        )
        .find_each do |topic|
          next if topic.category_id == feedback.id
          raise "Could not move topic #{topic.id}" unless topic.change_category_to_id(feedback.id)
          moved << topic.id
        end

      [providers, general].compact.each do |category|
        category.reload
        admin.guardian.ensure_can_delete!(category)
        ["c/#{category.slug}/#{category.id}", "c/#{category.id}"].each do |url|
          Permalink.find_or_initialize_by(url: url).update!(category_id: help.id)
        end
        logger.log_category_deletion(category)
        category.destroy!
      end
    end

    SiteSetting.meta_category_id = feedback.id
    SiteSetting.general_category_id = help.id
    SiteSetting.default_composer_category = ""
    SiteSetting.uncategorized_category_id = uncategorized.id
    SiteSetting.allow_uncategorized_topics = false
    SiteSetting.fixed_category_positions = true
    SiteSetting.fixed_category_positions_on_create = true
    SiteSetting.default_navigation_menu_categories = public_categories.map(&:id).join("|")
    Category.find(SiteSetting.staff_category_id).update!(position: 5)
    Category.find(SiteSetting.discourse_blog_drafts_category).update!(position: 6)
    Discourse.cache.delete(Categories::TypeRegistry::COUNTS_CACHE_KEY)
    logger.log_custom(
      "term_llm_category_structure",
      category_ids: public_categories.map(&:id),
      moved_topic_ids: moved,
    )
    puts "Public categories: #{public_categories.map(&:name).join(", ")}"
    puts "Moved #{moved.length} discussions; Staff and Blog editorial permissions unchanged."
  end
end
