class UserObserver < Mongoid::Observer

  # send notification if the user is new
  def after_create(user)
    NotificationTrigger.add_new_user(user.id)
    return true
  end

end