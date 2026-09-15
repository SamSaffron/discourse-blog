# frozen_string_literal: true

module ::Jobs
  class PublishBlogRevision < ::Jobs::Base
    def execute(args)
      publication = DiscourseBlog::Publication.find_by(id: args[:publication_id])
      publication&.run_schedule!(args[:token])
    end
  end
end
