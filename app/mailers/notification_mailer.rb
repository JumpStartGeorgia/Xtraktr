class NotificationMailer < ActionMailer::Base
  default :from => ENV['APPLICATION_FROM_EMAIL']
  layout 'mailer'

  def new_user(message)
    @message = message
    mail(:to => message.email, :subject => message.subject)
  end

  def new_dataset(message)
    @message = message
    mail(:bcc => message.bcc, :subject => message.subject)
  end

  def new_time_serise(message)
    @message = message
    mail(:bcc => message.bcc, :subject => message.subject)
  end


end
