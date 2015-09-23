class Users::SessionsController < Devise::SessionsController
   def create 
    #self.resource = warden.authenticate!(auth_options)
    self.resource = warden.authenticate!(:scope => resource_name, :recall => 'users/sessions#failure')      
    set_flash_message(:notice, :signed_in) if is_flashing_format?
    sign_in(resource_name, resource)
    yield resource if block_given?
        if resource.valid?
            respond_with resource, location: after_sign_in_path_for(resource)
        else
            respond_to do |format|
            format.html { redirect_to after_sign_in_path_for(resource) }
            format.json { render :json => {url: after_sign_in_path_for(resource)} }
        end
    end
    #respond_with resource, location: after_sign_in_path_for(resource)    
   end
     def failure 
        render :json => { :errors => self.flash.to_hash, sessions: true }, :status => :error
    end
end