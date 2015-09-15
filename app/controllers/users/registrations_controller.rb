class Users::RegistrationsController < Devise::RegistrationsController
   # POST /resource
   respond_to :json
   def create
      pars = sign_up_params
      puts "--------------------------create user-#{session.inspect}"
     Rails.logger.debug("--------------------------------------------#{pars} #{params}")
      if create_user? pars
        if create_facebook? pars
          
          
          agreement_data = pars.slice(:email, :first_name, :last_name, :age_group, :residence, :affiliation, :status, :status_other, :description, :terms).merge!(params[:agreement])
Rails.logger.debug("--------------------------------------------facebook#{agreement_data}")
          @mod = Agreement.new(agreement_data)
Rails.logger.debug("--------------------------------------------facebook#{@mod.errors.inspect}")           
          respond_to do |format|
            if @mod.valid?
               Rails.logger.debug("--------------------------------------------valid")
              format.json { render json: { url: omniauth_authorize_path(resource_name, :facebook, agreement_data), registration: true }, :success => true }
            else
              Rails.logger.debug("--------------------------------------------not valid #{@mod.errors.inspect}")
              format.json { render json: { errors: @mod.errors, registration: true }, :status => :error }
            end
          end   

          # build_resource(sign_up_params)
          # resource_saved = resource.save
          # yield resource if block_given?
          # if resource_saved
          #   if resource.active_for_authentication?
          #     set_flash_message :notice, :signed_up if is_flashing_format?
          #     sign_up(resource_name, resource)
          #     respond_with resource, location: after_sign_up_path_for(resource)
          #   else
          #     set_flash_message :notice, :"signed_up_but_#{resource.inactive_message}" if is_flashing_format?
          #     expire_data_after_sign_in!
          #     respond_with resource, location: after_inactive_sign_up_path_for(resource)
          #   end
          # else
          #   clean_up_passwords resource
          #   @validatable = devise_mapping.validatable?
          #   if @validatable
          #     @minimum_password_length = resource_class.password_length.min
          #   end
          #   respond_with resource
          # end
        else 
          build_resource(sign_up_params)
          resource_saved = resource.save
          yield resource if block_given?
          if resource_saved
            if resource.active_for_authentication?
              set_flash_message :notice, :signed_up if is_flashing_format?
              sign_up(resource_name, resource)
              respond_with resource, location: after_sign_up_path_for(resource)
            else
              set_flash_message :notice, :"signed_up_but_#{resource.inactive_message}" if is_flashing_format?
              expire_data_after_sign_in!
              respond_with resource, location: after_inactive_sign_up_path_for(resource)
            end
          else
            clean_up_passwords resource
            @validatable = devise_mapping.validatable?
            if @validatable
              @minimum_password_length = resource_class.password_length.min
            end
            respond_with resource
          end
        end
             
      else
         #if terms?
            @mod = Agreement.new(pars.slice(:email, :first_name, :last_name, :age_group, :residence, :affiliation, :status, :status_other, :description, :terms).merge!( params[:agreement] ))
              @url = Dataset.find(@mod.dataset_id).urls[@mod.dataset_type][@mod.dataset_locale]
                @model_name = @mod.model_name.downcase
         respond_to do |format|
             if @mod.save
                @mapper = FileMapper.create({ dataset_id: @mod.dataset_id, dataset_type: @mod.dataset_type, dataset_locale: @mod.dataset_locale })         
               format.json { render json: { url: "/#{I18n.locale}/download/#{@mapper.key}", registration: true }, :success => true }
              else
               format.json { render json: { errors: @mod.errors, registration: true }, :status => :error }
              end
           end    
      end
   end
  def sign_up_params
    devise_parameter_sanitizer.sanitize(:sign_up)
  end
  def create_user? pars    
    pars[:account].present? && pars[:account].to_i == 1
  end
  def create_facebook? pars
    pars[:facebook_account].present? && pars[:facebook_account].to_i == 1
  end
  def terms?
    params[:user][:terms].present? && params[:user][:terms].to_i == 1
  end
end