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
    require 'csv'
    csv = ApiRequest.generate_csv
    filename = I18n.t('app.common.app_name')
    filename << " API Requests "
    filename << I18n.l(Time.now, :format => :file)

    respond_to do |format|
      format.csv {
        if csv.nil?
          return false
        else
          send_data csv, 
            :type => 'text/csv; header=present',
            :disposition => "attachment; filename=#{clean_filename(filename)}.csv"
        end
      }
    end

  end

  def download_download_requests
    require 'csv'
    csv = Agreement.generate_csv
    filename = I18n.t('app.common.app_name')
    filename << " Download Requests "
    filename << I18n.l(Time.now, :format => :file)

    respond_to do |format|
      format.csv {
        if csv.nil?
          return false
        else
          send_data csv, 
            :type => 'text/csv; header=present',
            :disposition => "attachment; filename=#{clean_filename(filename)}.csv"
        end
      }
    end

  end

end
