class DatasetObserver < Mongoid::Observer

  # send notification if the dataset was made public
  def after_save(dataset)
    if dataset.public_changed? && dataset.public == true 
      puts "======= - new public dataset, sending notification"
      NotificationTrigger.add_new_dataset(dataset.id)
    end

    return true
  end

end