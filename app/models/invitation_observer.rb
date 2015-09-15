class InvitationObserver < Mongoid::Observer

  # send notification if the invitaiton is new
  def after_create(invitation)
    NotificationTrigger.add_new_organization_member(invitation.id)
    return true
  end

end
