# frozen_string_literal: true

module DiscourseBlogSpecHelpers
  BLOG_HOST = "blog.example.com"
  DISCUSSION_HOST = "test.localhost"
  BLOG_HOSTNAMES = [DISCUSSION_HOST, BLOG_HOST].freeze

  # Stubs both hostnames and enables the blog, optionally wiring its categories.
  def enable_discourse_blog!(category: nil, drafts: nil)
    RailsMultisite::ConnectionManagement.stubs(:current_db_hostnames).returns(BLOG_HOSTNAMES)
    SiteSetting.discourse_blog_enabled = true
    SiteSetting.discourse_blog_url = "https://#{BLOG_HOST}"
    SiteSetting.discourse_blog_category = category.id if category
    SiteSetting.discourse_blog_drafts_category = drafts.id if drafts
  end
end

RSpec.configure { |config| config.include(DiscourseBlogSpecHelpers) }
