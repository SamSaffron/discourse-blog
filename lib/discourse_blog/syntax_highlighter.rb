# frozen_string_literal: true

module ::DiscourseBlog
  module SyntaxHighlighter
    def self.source
      @source ||= File.read(File.join(HighlightJs::HIGHLIGHTJS_DIR, "es/core.min.js"))
    end

    def self.version
      @version ||= Digest::SHA256.hexdigest(source)
    end

    def self.path
      "/blog-highlight/#{version}.js"
    end
  end
end
