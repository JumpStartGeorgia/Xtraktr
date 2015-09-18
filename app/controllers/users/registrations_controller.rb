class Users::RegistrationsController < Devise::RegistrationsController
   # POST /resource
   respond_to :json

   def create
    @pars = sign_up_params

    if create_user? # user should be created
      if !create_facebook? # local user
        build_resource(sign_up_params)
        resource_saved = resource.save
        yield resource if block_given?

        respond_to do |format|
          if resource_saved
            sign_up(resource_name, resource)
            format.json { render json: { url: after_sign_up_path_for(resource) }, :success => true }
          else
            clean_up_passwords resource
            format.json { render json: { errors: resource.errors }, :status => :error }
          end
        end 
      else # facebook user
        build_resource(@pars.merge!({ provider: :facebook }))
        respond_to do |format|
          if resource.valid?
            tmp = @pars.slice(:email, :first_name, :last_name, :age_group, :residence, :affiliation, :status, :status_other, :description, :notifications, :notification_locale)              
            format.json { render json: { url: omniauth_authorize_path(resource_name, :facebook, tmp) }, :success => true }
          else
            format.json { render json: { errors: resource.errors }, :status => :error }
          end
        end 
      end        
    else # downloading data without creating user   
      if user_signed_in? # user has missing required fields
        agreement_data = @pars.slice(:email, :first_name, :last_name, :age_group, :residence, :affiliation, :status, :status_other, :description).merge!(params[:agreement])
        agreement_data[:residence] = Country.find(agreement_data[:residence]).name
        @mod = Agreement.new(agreement_data)
        respond_to do |format|
          if @mod.valid?
            format.json { render json: { url: omniauth_authorize_path(resource_name, :facebook, agreement_data), registration: true }, :success => true }
          else
            format.json { render json: { errors: @mod.errors, registration: true }, :status => :error }
          end
        end 
      else # just download data with agreement
        agreement_data = @pars.slice(:email, :first_name, :last_name, :age_group, :residence, :affiliation, :status, :status_other, :description).merge!(params[:agreement])

        agreement_data[:residence] = Country.find(agreement_data[:residence]).name
        @mod = Agreement.new(agreement_data)

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
  end
  def new 
    @flags = [false, true, true, false, true]
    super
  end
  def sign_up_params
    devise_parameter_sanitizer.sanitize(:sign_up)
  end
  def create_user?
    user_signed_in? ? false : (params[:account].present? && params[:account].to_i == 1)     
  end
  def create_facebook?
    params[:facebook_account].present? && params[:facebook_account].to_i == 1
  end
  def direct?
    params[:direct].present? && params[:direct].to_i == 1
  end
end