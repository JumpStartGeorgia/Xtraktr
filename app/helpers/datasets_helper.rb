module DatasetsHelper

  def format_gathered_dates(start_at, end_at)
    text = ''
    if start_at.present? && end_at.present?
      text << I18n.l(start_at, format: :day_first)
      text << " - "
      text << I18n.l(end_at, format: :day_first)
    elsif start_at.present?
      text << I18n.l(start_at, format: :day_first)
    elsif end_at.present?
      text << I18n.l(start_at, format: :day_first)
    end
    return text
  end

  # get the correct url to use for explore dataset
  # can either be admin dataset page or root dataset page 
  def url_dataset_explore(dataset, options={})
    request.path == explore_data_dashboard_path(dataset) ? explore_data_show_path(dataset, options) : explore_dataset_path(dataset, options)
  end

  # get the correct url to use for dashboard dataset
  # can either be admin dataset page or root dataset page 
  def url_dataset_dashboard(dataset, options={})
    request.path == explore_data_show_path(dataset) ? explore_data_dashboard_path(dataset, options) : dataset_path(dataset, options)
  end

  # get the correct url to use on dashboard of dataset to send to dashboard of time series
  # can either be admin dataset page or root dataset page 
  def url_dataset_to_times_series_dashboard(dataset_id, time_series_id, options={})
    request.path == explore_data_dashboard_path(dataset_id) ? explore_time_series_dashboard_path(time_series_id, options) : time_series_path(time_series_id, options)
  end
end
