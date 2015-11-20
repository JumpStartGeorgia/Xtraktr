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
  field :dataset_title, :type => String
  field :time_series_title, :type => String
  field :user_name, :type => String

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

      # get user name
      user = User.find(record.user_id)
      record.user_name = user.name if user.present?
    end

    # record the ip
    record.ip_address = ip if ip.present?

    # record the request being made
    if params.present?
      record.locale = params['locale'] if params['locale'].present?
      record.api_version = params['controller'].split('/').last if params['controller'].present?
      record.action = params['action'] if params['action'].present?
      record.dataset_id = params['dataset_id'] if params['dataset_id'].present?
      # get dataset title
      if record.dataset_id.present?
        dataset = Dataset.only_id_title_languages.find(record.dataset_id)
        record.dataset_title = dataset.title if dataset.present?
      end

      record.time_series_id = params['time_series_id'] if params['time_series_id'].present?
      # get time series title
      if record.time_series_id.present?
        time_series = TimeSeries.only_id_title.find(record.time_series_id)
        record.time_series_title = time_series.title if time_series.present?
      end
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
    require 'csv'
    return CSV.generate do |csv_row|
      csv_row << csv_header # add header
      sorted.each do |record|
        csv_row << record.csv_data # add row
      end
    end
  end

  # generate a csv object for all records on file
  def self.generate_xlsx

    workbook = RubyXL::Workbook.new
    worksheet = workbook[0]

    csv_header.each_with_index{|x,i| 
      worksheet.add_cell(0, i, x)  
    }
    
    sorted.each_with_index { |r, r_i|
      tmp = r.csv_data
      tmp.each_with_index { |c, c_i|
        worksheet.add_cell(r_i+1, c_i, c)
      }
    }
    
    return workbook.stream.string
  end

  def self.csv_header
    model = ApiRequest
    return [  
      model.human_attribute_name("created_at"), model.human_attribute_name("api_key_id"), model.human_attribute_name("user_id"), model.human_attribute_name("user_name"), 
      model.human_attribute_name("dataset_id"), model.human_attribute_name("dataset_title"), model.human_attribute_name("time_series_id"), model.human_attribute_name("time_series_title"), model.human_attribute_name("ip_address"), 
      model.human_attribute_name("locale"), model.human_attribute_name("api_version"), model.human_attribute_name("action"), model.human_attribute_name("question_code"), model.human_attribute_name("broken_down_by_code"), model.human_attribute_name("filtered_by_code"), model.human_attribute_name("can_exclude"), model.human_attribute_name("with_title"), model.human_attribute_name("with_chart_data"), model.human_attribute_name("with_map_data"), 
      model.human_attribute_name("browser"), model.human_attribute_name("version"), model.human_attribute_name("os"), model.human_attribute_name("platform"), model.human_attribute_name("app"), model.human_attribute_name("is_mobile")
    ]
  end

  def csv_data

    return [  
      self.created_at, self.api_key_id, self.user_id, self.user_name, self.dataset_id, self.dataset_title, self.time_series_id, self.time_series_title, self.ip_address, 
      self.locale, self.api_version, self.action, self.question_code, self.broken_down_by_code, self.filtered_by_code, self.can_exclude, self.with_title, self.with_chart_data, self.with_map_data, 
      self.browser, self.version, self.os, self.platform, self.app, self.is_mobile
    ]
  end
end