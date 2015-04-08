class ApiRequest
  include Mongoid::Document
  include Mongoid::Timestamps

  #############################

  belongs_to :api_key
  belongs_to :user
  belongs_to :dataset
  belongs_to :time_series

  #############################

  field :ip_address, :type => String

  # request info
  field :locale, :type => String
  field :api_version, :type => String
  field :action, :type => String
  field :question_code, :type => String
  field :broken_down_by_code, :type => String
  field :filtered_by_code, :type => String
  field :can_exclude, :type => Boolean
  field :chart_formatted_data, :type => Boolean
  field :map_formatted_data, :type => Boolean

  # user agent info
  field :browser, :type => String
  field :version, :type => String
  field :os, :type => String
  field :platform, :type => String
  field :app, :type => String
  field :is_mobile, :type => Boolean


  #############################
  ## Indexes

  index({ :api_key_id => 1}, { background: true})
  index({ :user_id => 1}, { background: true})
  index({ :dataset_id => 1}, { background: true})
  index({ :time_series_id => 1}, { background: true})

  ####################


  # record the api request
  def self.record_request(api_key, ip, params, user_agent)
    Rails.logger.debug "$$$$$$$$$$$$$$44 recording request"
    Rails.logger.debug "$$$$$$$$$$$$$$44 #{params}"
    record = ApiRequest.new

    # if the key was found, save the ids
    if api_key.present?
      record.api_key_id = api_key.id
      record.user_id = api_key.user_id
    end

    # record the ip
    record.ip_address = ip if ip.present?


    # record the request being made
    if params.present?
      record.locale = params['locale'] if params['locale'].present?
      record.api_version = params['controller'].split('/').last if params['controller'].present?
      record.action = params['action'] if params['action'].present?
      record.dataset_id = params['dataset_id'] if params['dataset_id'].present?
      record.time_series_id = params['time_series_id'] if params['time_series_id'].present?
      record.question_code = params['question_code'] if params['question_code'].present?
      record.broken_down_by_code = params['broken_down_by_code'] if params['broken_down_by_code'].present?
      record.filtered_by_code = params['filtered_by_code'] if params['filtered_by_code'].present?
      record.can_exclude = params['can_exclude'].to_bool if params['can_exclude'].present?
      record.chart_formatted_data = params['chart_formatted_data'].to_bool if params['chart_formatted_data'].present?
      record.map_formatted_data = params['map_formatted_data'].to_bool if params['map_formatted_data'].present?
    end

    # record the user agent info
    if user_agent.present?
      record.browser = user_agent.browser
      record.version = user_agent.version
      record.os = user_agent.os
      record.platform = user_agent.platform
      record.app = user_agent.app
      record.is_mobile = user_agent.mobile?
    end   
  
    record.save

    Rails.logger.debug "$$$$$$$$$$$$$$44 request = #{record.inspect}"

    return record
  end

end