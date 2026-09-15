# frozen_string_literal: true

namespace :discourse_blog do
  desc "Set up an editorial demo on the local development site"
  task demo: :environment do
    abort "Demo content is only available in development" unless Rails.env.development?
    admin = User.find_by!(username: "admin")
    blog =
      Category.find_by(id: SiteSetting.discourse_blog_category) || Category.find_by(slug: "blog")
    unless blog
      blog = Category.new(name: "Blog", slug: "blog", user: admin)
      blog.set_permissions(everyone: :create_post, staff: :full)
      blog.save!
    end
    drafts =
      Category.find_by(id: SiteSetting.discourse_blog_drafts_category) ||
        Category.find_by(slug: "blog-drafts")
    unless drafts
      drafts = Category.new(name: "Blog editorial", slug: "blog-drafts", user: admin)
      drafts.set_permissions(staff: :full)
      drafts.save!
    end
    SiteSetting.discourse_blog_url = "https://blog.dev.home.arpa"
    SiteSetting.discourse_blog_category = blog.id
    SiteSetting.discourse_blog_drafts_category = drafts.id
    SiteSetting.discourse_blog_title = "Fieldnotes"
    SiteSetting.discourse_blog_description =
      "Ideas in progress, things we’ve learned, and conversations worth having."
    SiteSetting.discourse_blog_about = <<~MD
      A little space for longer thoughts, built right into our community.

      **Fieldnotes** is a working demonstration of Discourse Blog. Every article starts as a topic, and every conversation stays connected to the story that started it.

      ## A place to think out loud

      We believe the interesting part often happens after you press publish. Ask a question, share an experience, or offer a different perspective in the discussion beneath each article.

      These sample articles are demo content. Replace them with your own when you are ready.
    MD
    SiteSetting.discourse_blog_enabled = true
    DiscourseBlog::Configuration.ensure_ready!
    SiteSetting.embed_full_app = true
    SiteSetting.embed_full_app_signin_flow = true
    EmbeddableHost.find_or_create_by!(host: "blog.dev.home.arpa") do |host|
      host.category_id = blog.id
    end

    examples = [
      {
        path: "/a-small-home-for-big-ideas",
        title: "A small home for big ideas",
        excerpt:
          "A blog should feel like a quiet place to read, with an open door to the conversation. This is our first step toward that.",
        featured: true,
        raw: <<~MD,
          *This is a demo article. Make yourself at home and try the conversation below.*

          There is something satisfying about a page that gets out of your way. A title, a little context, and room for an idea to develop.

          That is the starting point for this blog: **a calm reading experience, connected to a living community.** No separate publishing system. No comments database drifting away from the article. Just one place to write, and two good ways to experience it.

          ## Write where the conversation happens

          Every article begins as a Discourse topic. Before it is ready, it lives in a private drafts category. You can revise it, add images, ask fellow editors for feedback, and preview the finished page.

          Publishing is an explicit decision. It gives the story a permanent address and opens the discussion to everyone.

          > The article is the beginning of the conversation, not the end of it.

          ## Small by default

          The words arrive as ordinary HTML. You do not need to load an application to read them. When you reach the discussion, Discourse joins you there: real accounts, live replies, and the moderation tools the community already knows.

          A few things we care about:

          - Links that keep working when a title changes.
          - A feed you can subscribe to in your favorite reader.
          - Drafts that stay out of the public archive.
          - Space for thoughtful responses, not just a reaction count.

          ## An invitation

          This is a working first version, not a finished manifesto. Scroll down, say hello, and tell us what a good community blog should feel like.
        MD
      },
      {
        path: "/the-case-for-writing-in-public",
        title: "The case for writing in public",
        excerpt:
          "Useful writing doesn’t have to be definitive. Sometimes the most valuable thing you can share is the question you are still working through.",
        raw: <<~MD,
          *Demo content for exploring the blog.*

          A polished answer is useful. But a well-framed question can be even more useful, especially when it reaches people who have been thinking about the same thing from another direction.

          ## Leave a little room

          We tend to imagine publishing as the final step: research, draft, polish, publish. In a community, it is often better understood as a midpoint.

          You bring what you have learned. Someone else brings the exception. A third person supplies the example that makes the whole thing click.

          That does not mean publishing carelessly. It means being honest about what is settled and what is still an experiment.

          ## Three questions before publishing

          1. What is the one idea I want a reader to take away?
          2. What would help someone disagree constructively?
          3. Where should the conversation go next?

          The last question is why the replies belong alongside the article. Context matters, and the best follow-up should not disappear into a different system.

          **What have you learned by sharing an unfinished idea?**
        MD
      },
      {
        path: "/keeping-the-web-readable",
        title: "Keeping the web readable",
        excerpt:
          "Permanent links, readable pages, and a good RSS feed are small features with a surprisingly long life.",
        raw: <<~MD,
          *Demo content for exploring the blog.*

          Some web features age beautifully. A link you bookmarked years ago still opens. An RSS reader quietly brings you a new article. A page prints without losing the thing you came to read.

          None of these needs to be complicated.

          ## Start with the document

          The simplest useful representation of an article is still a document: a heading, some paragraphs, and meaningful links.

          ```html
          <article>
            <h1>An idea worth sharing</h1>
            <p>Start with the words.</p>
          </article>
          ```

          Add interaction where it helps, rather than making the words depend on it.

          ## Respect the address

          Titles evolve. Categories change. A permanent link should survive both. If an address really must change, leave a redirect behind for the people who trusted the old one.

          ## Let readers choose

          Visit the site, subscribe to the feed, or join the discussion. A good publication does not insist that everyone reads in the same way.
        MD
      },
    ]
    examples.each_with_index do |example, index|
      next if DiscourseBlog::Path.exists?(path: example[:path])
      post =
        PostCreator.create!(admin, title: example[:title], raw: example[:raw], category: drafts.id)
      publication = DiscourseBlog::Publication.for_topic(post.topic)
      publication.save_metadata!(
        admin,
        path: example[:path],
        excerpt: example[:excerpt],
        featured: example[:featured] || false,
        published_at: index.days.ago,
      )
      publication.publish!(admin)
      if index == 0
        reader = User.find_by(username: "user1") || admin
        PostCreator.create!(
          reader,
          topic_id: post.topic_id,
          raw:
            "The separation feels right: a quiet article first, then a real conversation. I would love to see more behind-the-scenes posts here.",
        )
        PostCreator.create!(
          admin,
          topic_id: post.topic_id,
          raw:
            "Exactly the idea. Try replying here from the blog — this is the same discussion you can open in Discuss.",
        )
      end
    end
    unless Topic.where(category_id: drafts.id, title: "Draft: what we are building next").exists?
      PostCreator.create!(
        admin,
        category: drafts.id,
        title: "Draft: what we are building next",
        raw: <<~MD,
        This is a private demo draft. It is not listed on the public blog.

        ## The next chapter

        Use the edit button to make this your own. The normal Discourse composer provides uploads, Markdown, rich text, revisions, and autosave.

        When you are ready, use the publication panel above this post. Open **Article settings** to give the article a short excerpt and a permanent path, preview it, then choose **Publish**.

        Publishing makes the entire topic public, including any editorial replies. Remove private editorial notes before publishing.
      MD
      )
    end
    puts "Blog: #{DiscourseBlog::Configuration.origin}"
    puts "Editor: #{Discourse.base_url}/blog/editor"
    puts "Categories: Blog=#{blog.id}, private drafts=#{drafts.id}"
  end
end

namespace :discourse_blog do
  desc "Seed 20 clearly labeled community discussion topics for local exploration"
  task seed_community: :environment do
    abort "Demo content is only available in development" unless Rails.env.development?
    general = Category.find_by(slug: "general") || Category.find(SiteSetting.general_category_id)
    feedback =
      Category.find_by(slug: "site-feedback") || Category.find(SiteSetting.meta_category_id)
    authors = %w[admin user0 user1 user2].filter_map { |username| User.find_by(username: username) }
    examples = [
      [
        "What are you working on this week?",
        "A weekly place to share something in progress: a side project, a difficult problem, or a small improvement that finally shipped. It does not need to be finished to be interesting.",
        "What is your next small milestone, and where could another pair of eyes help?",
      ],
      [
        "Introduce yourself and one thing you are curious about",
        "New faces make a community more interesting. Tell us a little about what brought you here and the subjects you could happily spend an afternoon discussing.",
        "What would you like to learn from people in this community?",
      ],
      [
        "The small tools that make your day easier",
        "Sometimes the most useful software is the tiny utility you stop noticing because it works so well. A keyboard shortcut, a short script, or a carefully chosen default can save a surprising amount of effort.",
        "Which small tool would you miss most if it disappeared tomorrow?",
      ],
      [
        "How do you decide an idea is ready to share?",
        "There is a balance between polishing an idea and keeping it private forever. A rough explanation with an honest question can invite better feedback than a document that sounds completely settled.",
        "Do you share early, or wait until you have a complete proposal?",
      ],
      [
        "A place for questions that do not need their own topic",
        "Not every question needs a long introduction. Use this thread for quick requests, pointers to documentation, and small things you have wondered about but never asked.",
        "What is one thing you would like someone to explain?",
      ],
      [
        "What have you read recently that stayed with you?",
        "An article, a book, a technical write-up, or even a thoughtful forum reply can change the way you approach a problem. Share a recommendation with a sentence about why it mattered.",
        "Which idea are you still thinking about days after reading it?",
      ],
      [
        "Share a project that taught you something unexpected",
        "The useful lesson is not always the one you planned to learn. A simple project can reveal a difficult constraint; a larger one can teach you that the simplest approach was enough.",
        "What surprised you, and what would you do differently next time?",
      ],
      [
        "What makes a technical explanation easy to follow?",
        "Examples, diagrams, a clear statement of the problem, and a little context all help. But different readers arrive with different knowledge, so there is no single perfect level of detail.",
        "Which explanation has helped you understand a difficult subject?",
      ],
      [
        "Your favorite way to take notes",
        "Some people keep a single text file. Others use notebooks, linked documents, or a collection of small daily entries. The best system is probably the one that makes useful notes easy to find again.",
        "How do you turn notes into something you actually return to?",
      ],
      [
        "A small win worth celebrating",
        "Progress often arrives as something ordinary: a confusing bug fixed, an old task finished, or a conversation that clarified the next step. Those moments deserve a place here too.",
        "What went a little better than expected this week?",
      ],
      [
        "When is a simple solution the right solution?",
        "It is tempting to design for every possible future requirement. Sometimes that flexibility helps; sometimes it makes the problem harder to understand before we have learned what people actually need.",
        "How do you recognize useful preparation versus unnecessary complexity?",
      ],
      [
        "How do you make time for learning?",
        "New ideas compete with deadlines, maintenance, and the rest of life. Small, regular experiments can be more sustainable than waiting for a completely free weekend.",
        "What learning habit has been easiest for you to keep?",
      ],
      [
        "Show us a useful automation",
        "A little automation can remove repetitive work without becoming a project of its own. Think reminders, backups, tidy reports, or a script that replaces a particularly error-prone checklist.",
        "What did you automate, and how do you know it is still working?",
      ],
      [
        "What deserves a permanent link?",
        "A good discussion often contains a reply that becomes useful long after the original conversation. Stable links make it possible to build on that knowledge instead of explaining it from the beginning every time.",
        "Which answers or resources do you find yourself linking to repeatedly?",
      ],
      [
        "How do you ask for useful feedback?",
        "A focused question can turn a vague request for opinions into a productive review. Explaining the constraints and the decision you are trying to make gives people something concrete to help with.",
        "What do you include when asking someone to review your work?",
      ],
      [
        "Weekend experiments and side projects",
        "This is a low-pressure place for experiments that might never become products. Try an unfamiliar tool, build an odd little prototype, or revisit an idea that has been sitting in a notebook.",
        "What would you try if the only goal were to learn something?",
      ],
      [
        "What should our community blog cover?",
        "The new blog gives longer pieces a quiet reading space while keeping the replies connected to the community. Tutorials, project notes, interviews, and thoughtful retrospectives could all fit.",
        "Which three subjects would make you subscribe to the feed?",
      ],
      [
        "Feedback on the new reading experience",
        "A good article page should be comfortable to read on a phone as well as a large screen. The details matter: line length, heading size, contrast, and where the conversation begins.",
        "What feels good, and what gets in the way when you read a longer article?",
      ],
      [
        "Help us make the community easier to navigate",
        "Categories are useful when they help readers know where to start. Too many can make posting feel like a classification exercise; too few can make good discussions hard to find later.",
        "Which part of the navigation would you simplify first?",
      ],
      [
        "Suggestions for a welcoming first visit",
        "A first-time visitor should be able to understand what this place is about, find something worth reading, and see a natural way to join in. A welcoming experience is made of many small choices.",
        "What would have helped you on your first visit to a new community?",
      ],
    ]
    examples.each_with_index do |(title, introduction, question), index|
      marker = (index + 1).to_s
      next if TopicCustomField.exists?(name: "discourse_blog_demo_community", value: marker)
      author = authors[index % authors.size]
      PostCreator.create!(
        author,
        title: title,
        category: index >= 16 ? feedback.id : general.id,
        skip_rate_limits: true,
        raw:
          "*Demo community discussion — seeded for exploring the development site.*\n\n#{introduction}\n\n**Discussion starter:** #{question}\n\nShare an example, ask a follow-up question, or offer a different perspective. Short, thoughtful replies are welcome.",
        custom_fields: {
          "discourse_blog_demo_community" => marker,
        },
      )
    end
    puts "Seeded community topics: #{TopicCustomField.where(name: "discourse_blog_demo_community").count}"
    puts "Published blog articles: #{DiscourseBlog::Publication.publicly_visible.count}"
  end

  desc "Add repeatable sample conversations to the development blog"
  task seed_replies: :environment do
    abort "Demo content is only available in development" unless Rails.env.development?

    replies = {
      "/a-small-home-for-big-ideas" => [
        [
          "user1",
          "The quiet reading experience is what sold me. I like being able to finish an article before seeing the conversation, rather than having a sidebar compete for attention.",
        ],
        [
          "user2",
          "One thing I would love to see here: follow-up posts that collect what people learned in the comments. Sometimes the best example arrives a week after the original article.",
        ],
        [
          "admin",
          "That is exactly the kind of loop we want: publish an idea, listen, then write something better. A monthly roundup of community discoveries would be a good place to start.",
        ],
      ],
      "/the-case-for-writing-in-public" => [
        [
          "user1",
          "The hardest part for me is deciding when something is ready to share. I have started calling my early posts field notes rather than guides. That small change makes it much easier to admit what I do not know yet.",
        ],
        [
          "user2",
          "I tried this with a project journal last month. A short post about a failed approach got more useful responses than my polished launch announcement. People could actually see where help was needed.",
        ],
        [
          "admin",
          "A useful rule of thumb: share one concrete observation and one honest question. It gives readers something to respond to without making the post feel unfinished. What did you change after that feedback?",
        ],
        [
          "user2",
          "We simplified the onboarding flow instead of adding another help page. Someone pointed out that our instructions were explaining a problem we could just remove. I would not have spotted that on my own.",
        ],
      ],
      "/keeping-the-web-readable" => [
        [
          "user2",
          "Thank you for keeping RSS in the picture. My feed reader is still the only place where I get to choose what to read without an algorithm rearranging everything.",
        ],
        [
          "user1",
          "Readable also means usable on a slow connection. I opened this on the train and the article was there before the discussion loaded. That is a small detail that makes a big difference.",
        ],
        [
          "admin",
          "The article should never have to wait for the comments application. The same goes for permanent links: changing a headline should not break a bookmark someone saved six months ago.",
        ],
        [
          "user1",
          "My other vote is for descriptive links. A sentence that tells me where a link goes is much more useful than a row of identical read-more buttons, especially with a screen reader.",
        ],
      ],
    }

    replies.each do |path, conversation|
      publication = DiscourseBlog::Publication.publicly_visible.find_by!(path: path)
      conversation.each do |username, text|
        author = User.find_by!(username: username)
        raw = "#{text}\n\n*Sample conversation for the demo blog.*"
        next if publication.topic.posts.exists?(user_id: author.id, raw: raw)

        PostCreator.create!(
          author,
          topic_id: publication.topic_id,
          raw: raw,
          skip_rate_limits: true,
        )
      end
      puts "#{path}: #{publication.topic.posts.where(post_type: Post.types[:regular]).where("post_number > 1").count} replies"
    end
  end
end
