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
  field :with_title, :type => Boolean
  field :with_chart_data, :type => Boolean
  field :with_map_data, :type => Boolean

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
  index({ :created_at => 1}, { background: true})

  ####################
  # Scopes

  def self.sorted
    order_by([[:created_at, :asc]])
  end


  ####################

  # record the api request
  def self.record_request(api_key, ip, params, user_agent)
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
      record.with_title = params['with_title'].to_bool if params['with_title'].present?
      record.with_chart_data = params['with_chart_data'].to_bool if params['with_chart_data'].present?
      record.with_map_data = params['with_map_data'].to_bool if params['with_map_data'].present?
    end

    # record the user agent info
    if user_agent.present?
      record.browser = user_agent.browser
      record.version = user_agent.version
      record.os = user_agent.os
      record.platform = user_agent.platform
      record.app = user_agent.application
      record.is_mobile = user_agent.mobile?
    end   
  
    record.save

    return record
  end


  # generate a csv object for all records on file
  def self.generate_csv
    return CSV.generate do |csv_row|
      # add header
      csv_row << csv_header

      sorted.each do |record|
        # add row
        csv_row << record.csv_data
      end
    end
  end


  def self.csv_header
    model = ApiRequest
    return [  
      model.human_attribute_name("created_at"), model.human_attribute_name("api_key_id"), model.human_attribute_name("user_id"), model.human_attribute_name("dataset_id"), model.human_attribute_name("time_series_id"), model.human_attribute_name("ip_address"), 
      model.human_attribute_name("locale"), model.human_attribute_name("api_version"), model.human_attribute_name("action"), model.human_attribute_name("question_code"), model.human_attribute_name("broken_down_by_code"), model.human_attribute_name("filtered_by_code"), model.human_attribute_name("can_exclude"), model.human_attribute_name("with_title"), model.human_attribute_name("with_chart_data"), model.human_attribute_name("with_map_data"), 
      model.human_attribute_name("browser"), model.human_attribute_name("version"), model.human_attribute_name("os"), model.human_attribute_name("platform"), model.human_attribute_name("app"), model.human_attribute_name("is_mobile")
    ]
  end

  def csv_data
    return [  
      self.created_at, self.api_key_id, self.user_id, self.dataset_id, self.time_series_id, self.ip_address, 
      self.locale, self.api_version, self.action, self.question_code, self.broken_down_by_code, self.filtered_by_code, self.can_exclude, self.with_title, self.with_chart_data, self.with_map_data, 
      self.browser, self.version, self.os, self.platform, self.app, self.is_mobile
    ]
  end
end