# frozen_string_literal: true

module ::DiscourseBlog
  class EditorController < ::ApplicationController
    helper DiscourseBlog::BlogHelper
    requires_plugin PLUGIN_NAME
    requires_login except: [:index]
    before_action :ensure_blog_editor, except: :index
    before_action :ensure_discussion_host
    before_action :find_topic, except: :index
    skip_before_action :check_xhr, only: %i[index preview]

    def index
      ensure_blog_editor unless request.format.html? && !current_user
      respond_to do |format|
        format.html { render "default/empty" }
        format.json do
          topics =
            EditorQuery.call(
              guardian,
              filter: params[:filter].presence || "all",
              query: params[:q] || "",
            )
          @page = [params[:page].to_i, 0].max
          selected = topics.offset(@page * 30).limit(31).includes(:first_post, :category).to_a
          publications =
            Publication
              .where(topic_id: selected.map(&:id))
              .includes(
                :discussion_topic,
                :submitted_revision,
                :approved_revision,
                :published_revision,
                topic: :first_post,
                draft_topic: :first_post,
              )
              .index_by(&:topic_id)
          live_topic_ids =
            Publication.publicly_visible.where(topic_id: selected.map(&:id)).pluck(:topic_id).to_set
          render json: {
                   error: Configuration.error,
                   blog_url: Configuration.origin,
                   more: selected.size > 30,
                   topics:
                     selected
                       .first(30)
                       .map { |topic|
                         entry(
                           topic,
                           publications[topic.id],
                           live: live_topic_ids.include?(topic.id),
                         )
                       },
                 }
        end
      end
    end

    def show
      render json: entry(@topic, @publication)
    end

    def update
      @publication.save_metadata!(
        current_user,
        params.require(:publication).permit(:path, :excerpt, :featured, :published_at),
      )
      render json: entry(@topic, @publication)
    end

    def publish
      @publication.publish!(current_user, revision_id: params.require(:revision_id).to_i)
      render json: entry(@topic.reload, @publication)
    end

    def prepare
      @publication.prepare_draft!(current_user)
      render json: entry(@publication.topic, @publication)
    end

    def submit
      @publication.submit!(current_user)
      render json: entry(@publication.topic, @publication)
    end

    def approve
      @publication.approve!(current_user, params.require(:revision_id).to_i)
      render json: entry(@publication.topic, @publication)
    end

    def schedule
      @publication.schedule!(
        current_user,
        revision_id: params.require(:revision_id).to_i,
        at: params.require(:scheduled_at),
      )
      render json: entry(@publication.topic, @publication)
    end

    def cancel_schedule
      @publication.cancel_schedule!(current_user)
      head :no_content
    end

    def destroy
      @publication.unpublish!(current_user)
      head :no_content
    end

    def return_to_drafts
      @publication.return_to_drafts!(current_user)
      head :no_content
    end

    def preview
      @preview = true
      @canonical_url = @publication.url
      source = @publication.editorial_topic || @topic
      @article =
        if params[:revision_id].present?
          @publication.revisions.find(params[:revision_id])
        else
          Revision.new(data: Revision.capture(@publication, source))
        end
      @page_title = @article.title
      @description = @article.data["excerpt"]
      response.headers["X-Robots-Tag"] = "noindex, nofollow"
      response.headers["Cache-Control"] = "private, no-store"
      render "discourse_blog/articles/show", layout: "discourse_blog"
    end

    private

    def ensure_blog_editor
      raise Discourse::InvalidAccess unless Configuration.contributor?(current_user)
    end

    def ensure_discussion_host
      raise Discourse::NotFound if Configuration.blog_host?(request)
    end

    def find_topic
      requested = Topic.find(params[:topic_id])
      @publication = Publication.for_topic(requested)
      @topic = @publication.topic
      Configuration.ensure_editor!(current_user, @publication.editorial_topic || @topic)
    end

    def entry(topic, publication, live: nil)
      publication ||= Publication.new(topic: topic, path: "/#{topic.slug.presence || topic.id}")
      source = publication.editorial_topic
      metadata = publication.editorial_metadata
      {
        id: topic.id,
        title: source&.title || topic.title,
        public_title: publication.published_revision&.title,
        public_excerpt: publication.published_revision&.data&.[]("excerpt"),
        public_path: publication.published_revision&.data&.[]("path"),
        draft_correction: publication.draft_correction?,
        topic_url: source&.url || topic.url,
        source_topic_id: source&.id,
        source_url: source&.url,
        discussion_url: publication.discussion_topic&.url,
        preview_url: publication.preview_url,
        url: publication.url,
        path: metadata["path"],
        excerpt: metadata["excerpt"],
        featured: metadata["featured"],
        published_at: metadata["published_at"],
        published: publication.published?,
        published_revision_id: publication.published_revision_id,
        live: live.nil? ? publication.publicly_visible? : live,
        draft: !publication.published? && source.present?,
        replies: [publication.discussion_topic&.posts_count.to_i - 1, 0].max,
        can_publish: Configuration.publisher?(current_user),
        submitted_revision: revision_entry(publication.submitted_revision, publication),
        approved_revision: revision_entry(publication.approved_revision, publication),
        scheduled_revision_id: publication.scheduled_revision_id,
        scheduled_at: publication.scheduled_at,
        schedule_error: publication.schedule_error,
      }
    end

    def revision_entry(revision, publication)
      return nil unless revision
      {
        id: revision.id,
        title: revision.title,
        preview_url: "#{publication.preview_url}?revision_id=#{revision.id}",
      }
    end
  end
end
