class SettingsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :load_owner # set @owner variable

  def index
    @user = @owner

    if request.put? &&
      success = if params[:user][:password].present? || params[:user][:password_confirmation].present?
        @user.update_attributes(params[:user])
      else
        @user.update_without_password(params[:user])
      end

      if success
        flash[:success] = t('app.msgs.user_settings_updated')
      end
    end

    @css.push('tabs.css', 'settings.css')

    respond_to do |format|
      format.html # index.html.erb
    end
  end


  def get_api_token
    @user = @owner

    @user.api_keys.create

    flash[:success] = t('app.msgs.api_key_created')

    redirect_to settings_path(owner_id: @owner.slug, page: 'api')
  end

  def delete_api_token
    @user = @owner

    key = @user.api_keys.where(id: params[:id]).first

    if key.present?
      key.destroy
    end

    flash[:success] = t('app.msgs.api_key_deleted')

    redirect_to settings_path(owner_id: @owner.slug, page: 'api')
  end


  def organization_new
    @user = @owner
    @group = params[:user].present? ? User.new(params[:user]) : User.new

    if @group.present?
      if request.post?
        # make sure the record is not saved as a user
        @group.is_user = false

        if @group.save
          # add this user as a member
          @group.members.create(member_id: @owner.id)
          respond_to do |format|
            format.html { redirect_to settings_path(@owner, page: 'organizations'), flash: {success:  t('app.msgs.success_saved', :obj => t('mongoid.models.organization'))} }
          end
        else
          respond_to do |format|
            format.html # index.html.erb
          end
        end
      else
        respond_to do |format|
          format.html # index.html.erb
        end
      end
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to settings_path(:owner_id => @owner.slug, page: 'organizations')
      return
    end
  end

  def organization_edit
    @user = @owner
    @group = User.find(params[:id])

    if @group.present? && @owner.groups.in_group?(@group.id)
      if request.put?
        # make sure the record is not saved as a user
        @group.is_user = false

        if @group.update_attributes(params[:user])
          respond_to do |format|
            format.html { redirect_to settings_path(@owner, page: 'organizations'), flash: {success:  t('app.msgs.success_saved', :obj => t('mongoid.models.organization'))} }
          end
        else
          respond_to do |format|
            format.html # index.html.erb
          end
        end
      else
        respond_to do |format|
          format.html # index.html.erb
        end
      end
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to settings_path(:owner_id => @owner.slug, page: 'organizations')
      return
    end

  end

  def organization_delete
    @user = @owner
    @group = User.find(params[:id])

    if @group.present? && @owner.groups.in_group?(@group.id)
      @group.destroy

      respond_to do |format|
        format.html { redirect_to settings_path(:owner_id => @owner.slug, page: 'organizations'), flash: {success:  t('app.msgs.success_deleted', :obj => t('mongoid.models.organization'))} }
        format.json { head :no_content }
      end
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to settings_path(:owner_id => @owner.slug, page: 'organizations')
      return
    end

  end

  def organization_leave
    @user = current_user
    @group = User.find(params[:id])

    if @group.present? && @user.groups.in_group?(@group.id)
      member = @group.members.where(member_id: @user.id)
      member.destroy if member.present?

      respond_to do |format|
        format.html { redirect_to settings_path(:owner_id => @user.slug, page: 'organizations'), flash: {success:  t('app.msgs.success_deleted', :obj => t('mongoid.models.organization'))} }
        format.json { head :no_content }
      end
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to settings_path(:owner_id => @owner.slug, page: 'organizations')
      return
    end

  end

  def member_delete
    @group = @owner
    @user = User.find(params[:id])

    if @user.present?
      member = @group.members.where(member_id: @user.id)
      member.destroy_all if member.present?

      respond_to do |format|
        format.html { redirect_to settings_path(:owner_id => @owner.slug, page: 'members'), flash: {success:  t('app.msgs.success_deleted', :obj => t('mongoid.models.member'))} }
        format.json { head :no_content }
      end
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to settings_path(:owner_id => @owner.slug, page: 'members')
      return
    end

  end

end
