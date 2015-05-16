class TimeSeriesObserver < Mongoid::Observer

  # send notification if the time_series was made public
  def after_save(time_series)

    if time_series.public_changed? && time_series.public == true 
      NotificationTrigger.add_new_time_series(time_series.id)
    end
    return true
  end

end