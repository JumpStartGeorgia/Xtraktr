class SettingsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :load_owner # set @owner variable

  def index
    @user = @owner
    @pending_members = Invitation.pending_from_user(@user.id) if !@user.is_user?
    @pending_orgs = Invitation.pending_to_user(@user.id) if @user.is_user?

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
      member.destroy_all if member.present?
      Invitation.delete_accepted_invitation(@group.id, @user.id)

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

  def organization_accept_invitation
    accepted = false
    @user = @owner
    @invitation = Invitation.find(params[:id])

    if @invitation.present?
      if @invitation.accepted_at.blank?
        @invitation.from_user.members.create(member_id: @user.id)
        @invitation.accepted_at = Time.now
        @invitation.save
        accepted = true
        flash[:success] = t('app.msgs.invitation.accepted', :org => @invitation.from_user.name)
      else
        flash[:notice] = t('app.msgs.invitation.accepted_already', :org => @invitation.from_user.name)
        accepted = true
      end
    end

    if !accepted
      flash[:notice] = t('app.msgs.invitation.bad')
    end
    redirect_to settings_path(:owner_id => @owner.slug, page: 'organizations')

  end

  def organization_delete_invitation
    @user = @owner
    @invitation = Invitation.find(params[:id])

    if @invitation.present?
      @invitation.destroy

      respond_to do |format|
        format.html { redirect_to settings_path(:owner_id => @owner.slug, page: 'organizations'), flash: {success:  t('app.msgs.success_deleted', :obj => t('mongoid.models.invitation'))} }
        format.json { head :no_content }
      end
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to settings_path(:owner_id => @owner.slug, page: 'members')
      return
    end

  end


  def member_new
    @group = @owner

    if @group.present?
      user_with_errors = []
      sending_invitations = false
      msgs = []

      gon.member_search = settings_member_search_path(@group)

      @css.push('token-input-xtraktr.css')
      @js.push('jquery.tokeninput.js', 'settings.js')

      if params[:member_ids].present? && request.post?
        sending_invitations = true

        # split out the ids
        ids = params[:member_ids].split(',')

        # pull out the user ids for existing users (numbers)
        user_ids = ids.select{|x| x !~ /^\'.*\'$/ }

        # pull out the email addresses for new users (not numbers)
        emails = ids.select{|x| x =~ /^\'.*\'$/ }.map{|x| x.gsub("'", '')}

        logger.debug "__________ user_ids = #{user_ids}"
        logger.debug "__________ emails = #{emails}"

        # send invitation for each existing user
        if user_ids.present?
          user_ids.each do |user_id|
            Rails.logger.debug "_______________user id = #{user_id}"
            user = User.find(user_id)
            if user.present?
              msg = create_invitation(@owner.id, user.id, user.email, params[:message])
              Rails.logger.debug "-------------- msg = #{msg}"
              if msg.blank?
    		        # remove id from list
    		        ids.delete(user_id)
    		      else
    		        # record the user with the error so that it can be re-displayed in the list
      		      user_with_errors << {id: user.id, name: user.nickname }
      		      msgs << "'#{user.name}' - #{msg.join(', ')}"
              end
            end
          end
        end

        # send invitation for new users
        if emails.present?
          emails.each do |email|
            Rails.logger.debug "_____________email = #{email}"
            msg = create_invitation(@owner.id, nil, email, params[:message])
            Rails.logger.debug "-------------- msg = #{msg}"
            if msg.blank?
  		        # remove email from list
  		        ids.delete(email)
  		      else
  		        # record the user with the error so that it can be re-displayed in the list
    		      user_with_errors << {id: email, name: email }
    		      msgs << "'#{email}' - #{msg.join(', ')}"
  		      end
          end
        end
      end

      # if not all ids were processed for invitations
      # record them so they can be shown in the list again
      params[:collaborator_error_ids] = user_with_errors

      if sending_invitations && user_with_errors.empty?
        flash[:success] = t('app.msgs.members.success_invitations')
        redirect_to settings_path(:owner_id => @owner.slug, page: 'members')
        return
      end

      if sending_invitations && user_with_errors.present?
        if user_with_errors.length == ids.length
          flash[:error] = t('app.msgs.members.error_invitations_all', :msg => msgs.join('; '))
        else
          flash[:error] = t('app.msgs.members.error_invitations_some', :msg => msgs.join('; '))
        end
      end

      respond_to do |format|
        format.html # index.html.erb
      end
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to settings_path(:owner_id => @owner.slug, page: 'members')
      return
    end

  end

  def member_search
    output = nil
    @group = @owner
    if @group.present?
      users = @group.invitation_search(params[:q])
      # format for token input js library [{id,name}, ...]
      output = users.map{|x| {id: x.id, name: x.name } }
    end

    respond_to do |format|
      format.json { render json: output.to_json }
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

  def member_delete_invitation
    @group = @owner
    @invitation = Invitation.find(params[:id])

    if @invitation.present?
      @invitation.destroy

      respond_to do |format|
        format.html { redirect_to settings_path(:owner_id => @owner.slug, page: 'members'), flash: {success:  t('app.msgs.success_deleted', :obj => t('mongoid.models.invitation'))} }
        format.json { head :no_content }
      end
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to settings_path(:owner_id => @owner.slug, page: 'members')
      return
    end

  end


  # this is the action called from notification emails to change settings
  # could not easily add owner_id into email url so doing this to redirect to
  # the correct page
  def settings_from_notification
    redirect_to settings_path(:owner_id => @owner.slug)
  end

  # this is the action that is called from notification emails to accept member invitation
  # if invitation is found, then redirect to
  def accept_invitation_from_notification
    accepted = false
    @user = @owner
    @invitation = Invitation.find_by_key(@user.id, params[:key])

    if @invitation.present?
      if @invitation.accepted_at.blank?
        @invitation.from_user.members.create(member_id: @user.id)
        @invitation.accepted_at = Time.now
        @invitation.save
        accepted = true
        flash[:success] = t('app.msgs.invitation.accepted', :org => @invitation.from_user.name)
      else
        flash[:notice] = t('app.msgs.invitation.accepted_already', :org => @invitation.from_user.name)
        accepted = true
      end

      if !accepted
        flash[:notice] = t('app.msgs.invitation.bad')
      end
      redirect_to settings_path(:owner_id => @owner.slug, page: 'organizations')
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to root_path(locale: I18n.locale)
      return
    end
  end

private

  def create_invitation(from_user_id, to_user_id=nil, to_email=nil, msg=nil)
    error_msg = nil

    if from_user_id.present? && (to_user_id.present? || to_email.present?)
      # if invitation already exists, stop
      if Invitation.already_exists?(from_user_id, to_email)
        Rails.logger.debug "@@@@@ invitation already exists, ignoring"
        # already sent, so ignore
        return error_msg
      end

      # save the invitation
      inv = Invitation.new
      inv.from_user_id = from_user_id
      inv.to_user_id = to_user_id
      inv.to_email = to_email
      inv.message = msg if msg.present?

      if !inv.save
        Rails.logger.debug "========= message error = #{inv.errors.full_messages}"
          error_msg = inv.errors.full_messages
      end
    end

    return error_msg
  end



end
