class Users::RegistrationsController < Devise::RegistrationsController
   # POST /resource
   def create
          Rails.logger.debug("--------------------------------------------#{sign_up_params}")
          pars = sign_up_params
      if create_user?
             build_resource(sign_up_params)

             resource_saved = resource.save
              Rails.logger.debug("----------------------------#{params}----------------#{resource_saved} #{resource.inspect}")
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
      else
         #if terms?
            @mod = Agreement.new(pars.slice(:email, :first_name, :last_name, :age_group, :residence, :affiliation, :status, :status_other, :description, :terms).merge!( params[:agreement] ))
              @url = Dataset.find(@mod.dataset_id).urls[@mod.dataset_type][@mod.dataset_locale]
                @model_name = @mod.model_name.downcase
         respond_to do |format|
             if @mod.save
                @mapper = FileMapper.create({ dataset_id: @mod.dataset_id, dataset_type: @mod.dataset_type, dataset_locale: @mod.dataset_locale })         
               format.json { render json: { url: "/#{I18n.locale}/download/#{@mapper.key}" }, :success => true }
              else
         Rails.logger.debug("------------------------------------------blahhere2--#{}")
               format.json { render json: { errors: @mod.errors }, :status => error }
              end
           end
        # end

    # a = Agreement.create({
    #     email: self.email,
    #     first_name: self.first_name,
    #     last_name: self.last_name,
    #     age_group: self.age_group,
    #     residence: self.residence,
    #     affiliation: self.affiliation,
    #     status: self.status,
    #     status_other: self.status_other,
    #     description: self.description,
    #     dataset_id: Moped::BSON::ObjectId.from_string(dataset_id),
    #     dataset_type: dataset_type,
    #     dataset_locale: dataset_locale,
    #     terms: 1
    #   })
    # a.valid?






      end
   end
   def create_user?
      params[:user][:account].present? && params[:user][:account].to_i == 1
   end
   def terms?
      params[:user][:terms].present? && params[:user][:terms].to_i == 1
   end
end