# class OmniauthCallbacksController < Devise::OmniauthCallbacksController
#   def facebook
#     logger.debug "++++++++++== facebook start"
#     @user = User.find_for_facebook_oauth(request.env["omniauth.auth"])

#     if @user.persisted?
#       logger.debug "++++++++++== user persisted"
#       sign_in_and_redirect @user, :event => :authentication #this will throw if @user is not activated
#       set_flash_message(:notice, :success, :kind => "Facebook") if is_navigational_format?
#     else
#       logger.debug "++++++++++== setting session"
#       session["devise.facebook_data"] = request.env["omniauth.auth"].except('extra')
#       logger.debug(request.env["omniauth.auth"])
#       redirect_to new_user_session_url
#     end
#   end
  
#   def failure
#     set_flash_message :alert, :failure, kind: OmniAuth::Utils.camelize(failed_strategy.name), reason: failure_message
#     redirect_to after_omniauth_failure_path_for(resource_name)
#   end  
# end



class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def twitter
    handle_redirect('devise.twitter_uid', 'Twitter')
  end

  def facebook
    handle_redirect('devise.facebook_data', 'Facebook')
  end

  private

  def handle_redirect(_session_variable, kind)
    # Use the session locale set earlier; use the default if it isn't available.
    I18n.locale = session[:omniauth_login_locale] || I18n.default_locale
    sign_in_and_redirect user, event: :authentication
    set_flash_message(:notice, :success, kind: kind) if is_navigational_format?
  end

  def user
    User.find_for_oauth(env['omniauth.auth'], current_user)
  end
end