# frozen_string_literal: true

abort "Design setup is only available in development" unless Rails.env.development?

root = Rails.root.join("plugins/discourse-blog/branding/term-llm")
theme = Theme.find_by!(name: "term-llm Community")
RemoteTheme.import_theme_from_directory(root.join("theme").to_s, theme_id: theme.id)

manifest = JSON.parse(root.join("blog-theme.json").read)
previous = DiscourseBlog::BlogTheme.all.find { |saved| saved["name"] == manifest["name"] }
design =
  DiscourseBlog::BlogTheme.save(
    {
      "name" => manifest["name"],
      "accent_color" => manifest["accent_color"],
      "paper_color" => manifest["paper_color"],
      "ink_color" => manifest["ink_color"],
      "css" => root.join("blog.css").read,
      "javascript" => "",
    },
    user: Discourse.system_user,
    id: previous&.fetch("id"),
    revision: previous&.fetch("revision"),
  )
DiscourseBlog::BlogTheme.activate(
  design["id"],
  revision: design["revision"],
  user: Discourse.system_user,
)
puts "Updated the term-llm community theme and activated its blog design."
