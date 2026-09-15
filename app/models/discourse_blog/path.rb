# frozen_string_literal: true

module ::DiscourseBlog
  class Path < ActiveRecord::Base
    self.table_name = "discourse_blog_paths"
    belongs_to :publication
    validates :path, presence: true, uniqueness: true
  end
end

# == Schema Information
#
# Table name: discourse_blog_paths
#
#  id             :bigint           not null, primary key
#  path           :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  publication_id :bigint           not null
#
# Indexes
#
#  index_discourse_blog_paths_on_path            (path) UNIQUE
#  index_discourse_blog_paths_on_publication_id  (publication_id)
#
