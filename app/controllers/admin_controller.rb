class AdminController < ApplicationController
  before_filter :authenticate_user!
  before_filter do |controller_instance|
    controller_instance.send(:valid_role?, @site_admin_role)
  end

  def index
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @pages }
    end
  end


  def download_api_requests
    if request.format.csv?
      data = ApiRequest.generate_csv
    elsif request.format.xlsx?
      data = ApiRequest.generate_xlsx
    end

    filename = I18n.t("app.common.#{@app_key_name}.app_name")
    filename << " API Requests #{I18n.l(Time.now, :format => :file)}"
    respond_to do |format|
      format.csv { send_data data, :filename=> "#{clean_filename(filename)}.csv" }
      format.xlsx { send_data data, :filename=> "#{clean_filename(filename)}.xlsx" }
    end
  end

  def download_download_requests
    if request.format.csv?
      data = Agreement.generate_csv
    elsif request.format.xlsx?
      data = Agreement.generate_xlsx
    end

    filename = I18n.t("app.common.#{@app_key_name}.app_name")
    filename << " Download Requests #{I18n.l(Time.now, :format => :file)}"

    respond_to do |format|
      format.csv { send_data data, :filename=> "#{clean_filename(filename)}.csv" }
      format.xlsx { send_data data, :filename=> "#{clean_filename(filename)}.xlsx" }
    end
  end

end
