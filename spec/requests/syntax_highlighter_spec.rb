# frozen_string_literal: true

RSpec.describe "Blog syntax highlighter", type: :request do
  before { enable_discourse_blog! }

  it "serves the minified module with immutable caching and CORS for previews" do
    get "https://blog.example.com#{DiscourseBlog::SyntaxHighlighter.path}"

    expect(response.status).to eq(200)
    expect(response.media_type).to eq("application/javascript")
    expect(response.body).to eq(DiscourseBlog::SyntaxHighlighter.source)
    expect(response.headers["Cache-Control"]).to include("immutable", "public")
    expect(response.headers["Access-Control-Allow-Origin"]).to eq("*")
    expect(response.headers["Set-Cookie"]).to be_nil
  end

  it "rejects an unknown asset version" do
    get "https://blog.example.com/blog-highlight/unknown.js"

    expect(response.status).to eq(404)
    expect(response.headers["Cache-Control"]).to include("no-store")
  end

  it "keeps the asset unavailable when public blogging is disabled" do
    SiteSetting.login_required = true

    get "https://blog.example.com#{DiscourseBlog::SyntaxHighlighter.path}"

    expect(response.status).not_to eq(200)
    expect(response.body).not_to eq(DiscourseBlog::SyntaxHighlighter.source)
  end
end
