class DraftsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_access_to_community
  before_action :require_admin_or_access_to_friend
  before_action :require_admin, only: [:destroy]

  def new
    @draft = friend.drafts.new
  end

  def create
    application = friend.applications.find_or_initialize_by(category: draft_params[:category])
    draft = application.drafts.new(draft_params.merge(friend: friend))
    if draft.save
      flash[:success] = 'Application draft saved.'
      render_document_list
    else
      flash.now[:error] = 'Application draft not saved.'
      render :new
    end
  end

  def edit
    draft
    friend
  end

  def update
    if draft.update(draft_params)
      flash[:success] = 'Application draft saved.'
      render_document_list
    else
      friend
      flash.now[:error] = 'Friend record not saved.'
      render :edit
    end
  end

  def index
    friend
  end

  def destroy
    if draft.destroy
      flash[:success] = 'Application draft destroyed.'
      redirect_to edit_community_admin_friend_path(current_community.slug, friend, tab: '#documents')
    else
      flash[:error] = 'Error destroying application draft.'
      redirect_to community_friend_drafts_path(current_community.slug, friend)
    end
  end

  def submit_for_review
    draft.status = :in_review
    application.status = :in_review
    if draft.save && application.save
      notify_lawyer(draft)
      flash[:success] = 'Draft submitted for review.'
    else
      flash[:error] = 'There was an issue submitting the draft for review.'
    end
    render_document_list
  end

  private

  def notify_lawyer(draft)
    Notification.draft_for_review(draft: draft)
  end

  def render_document_list
    if current_user.admin?
      redirect_to edit_community_admin_friend_path(current_community.slug, friend, tab: '#documents')
    else
      redirect_to community_friend_path(current_community.slug, friend, tab: '#documents')
    end
  end

  def draft
    @draft ||= Draft.find(params[:id])
  end

  def application
    @application ||= draft.application
  end

  def friend
    @friend ||= current_community.friends.find(params[:friend_id])
  end

  def draft_params
    params.require(:draft).permit(
      :notes,
      :pdf_draft,
      :category,
      user_ids: []
    )
  end

  def require_admin_or_access_to_friend
    return if current_user.admin_or_existing_relationship?(params[:friend_id])
    not_found
  end
end
