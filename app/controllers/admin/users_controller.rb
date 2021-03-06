class Admin::UsersController < AdminController
  def index
    @filterrific = initialize_filterrific(User,
                                          params[:filterrific],
                                          select_options: {
                                            filter_volunteer_type: volunteer_type_options
                                          },
                                          persistence_id: false)

    @users = current_community.users.filterrific_find(@filterrific).paginate(page: params[:page])

    respond_to do |format|
      format.html
      format.js
    end

  # Recover from invalid param sets, e.g., when a filter refers to the
  # database id of a record that doesn’t exist any more.
  # In this case we reset filterrific and discard all filter params.
  rescue ActiveRecord::RecordNotFound => e
    # There is an issue with the persisted param_set. Reset it.
    puts "Had to reset filterrific params: #{e.message}"
    redirect_to(reset_filterrific_url(format: :html)) && return
  end

  def destroy
    @user = current_community.users.find(params[:id])
    return unless @user.destroy

    flash[:success] = 'User record deleted.'
    redirect_to community_admin_users_path(current_community.slug, query: params[:query])
  end

  def edit
    @user = current_community.users.find(params[:id])
  end

  def update
    @user = current_community.users.find(params[:id])
    if @user.update(user_params)
      redirect_to community_admin_users_path(current_community.slug)
    else
      render 'edit'
    end
  end

  private

  def volunteer_type_options
    User.volunteer_types.keys.map do |volunteer_type|
      [volunteer_type.humanize, volunteer_type]
    end
  end

  def search
    Search.new(user_index_scope, params[:query], params[:page])
  end

  def user_params
    params.require(:user).permit(
      :first_name,
      :last_name,
      :email,
      :phone,
      :volunteer_type,
      :role,
      :signed_guidelines,
      :attended_training,
      :remote_clinic_lawyer
    )
  end

  def user_index_scope
    scope = current_community.users
    scope = scope.for_volunteer_type(params[:volunteer_type]) if params[:volunteer_type].present?
    scope
  end
end
