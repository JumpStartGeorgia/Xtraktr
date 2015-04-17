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
end
