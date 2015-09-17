class SettingsController < ApplicationController
  before_filter :authenticate_user!

  def index
    @flags = [false, false, current_user.provider.blank?, false, true]
    @user = current_user
    # @user.valid?
    
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
      # format.json { render json: @pages }
    end
  end
  def refill
    @user = current_user

    if request.put? &&       
      success = if params[:user][:password].present? || params[:user][:password_confirmation].present?
                  @user.update_attributes(params[:user])
                else
                  @user.update_without_password(params[:user])
                end      
    end

    respond_to do |format|
      if success
        format.json { render json: { }, :success => true }
      else
        format.json { render json: { errors: @user.errors }, :status => :error }
      end
    end    
  end

  def get_api_token
    @user = current_user
    
    @user.api_keys.create

    flash[:success] = t('app.msgs.api_key_created')

    redirect_to settings_path(page: 'api')
  end

  def delete_api_token
    @user = current_user
    
    key = @user.api_keys.where(id: params[:id]).first

    if key.present?
      key.destroy
    end

    flash[:success] = t('app.msgs.api_key_deleted')

    redirect_to settings_path(page: 'api')
  end
end
