module TimeSeriesHelper

  def format_time_series_public_status(is_public)
    if is_public == true
      return "<div class='publish-status public'>#{t('publish_status.public')}</div>".html_safe
    else
      return "<div class='publish-status not-public'>#{t('publish_status.private')}</div>".html_safe
    end
  end


  # get the correct url to use for explore time_series
  # can either be admin time_series page or root time_series page 
  def url_time_series_explore(time_series, options={})
    request.path == explore_time_series_dashboard_path(time_series) ? explore_time_series_show_path(time_series, options) : explore_time_series_path(time_series, options)
  end
end
