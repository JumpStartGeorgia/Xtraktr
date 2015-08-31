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
      format.json { render json: @pages }
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
end
