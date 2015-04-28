module TimeSeriesHelper

  # get the correct url to use for explore time_series
  # can either be admin time_series page or root time_series page 
  def url_time_series_explore(time_series, options={})
    request.path == explore_time_series_dashboard_path(time_series) ? explore_time_series_show_path(time_series, options) : explore_time_series_path(time_series, options)
  end

  # get the correct url to use for dashboard time_series
  # can either be admin time_series page or root time_series page 
  def url_time_series_dashboard(time_series, options={})
    request.path == explore_time_series_show_path(time_series) ? explore_time_series_dashboard_path(time_series, options) : time_series_path(time_series, options)
  end

  # get the correct url to use on dashboard of time series to send to dashboard of dataset
  # can either be admin time_series page or root time_series page 
  def url_dataset_to_datasets_dashboard(time_series_id, dataset_id, options={})
    request.path == explore_time_series_dashboard_path(time_series_id) ? explore_data_dashboard_path(dataset_id, options) : dataset_path(dataset_id, options)
  end
end
