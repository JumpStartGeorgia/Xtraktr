class NotificationMailer < ActionMailer::Base
  default :from => ENV['APPLICATION_FEEDBACK_FROM_EMAIL']
  layout 'mailer'
  add_template_helper(ApplicationHelper)

  def send_new_user(message)
    puts "=== sending new user!"
    @message = message

    # get instruction text
    @page_content = PageContent.by_name('instructions')

    mail(:bcc => message.bcc, :subject => message.subject)
  end

  def send_new_data(message, dataset_ids, time_series_ids)
    puts "=== sending new data!"
    @message = message
    @datasets = nil
    @time_series = nil


    # get datasets
    @datasets = Dataset.is_public.only_id_title_description.sorted.in(id: dataset_ids) if dataset_ids.present?
    # get time series
    @time_series = TimeSeries.is_public.only_id_title_description.sorted.in(id: time_series_ids) if time_series_ids.present?

    puts "===- dataset ids = #{dataset_ids}"
    puts "===- time series ids = #{time_series_ids}"

    mail(:bcc => message.bcc, :subject => message.subject)
  end

  def send_new_organization_member(message, user)
    @message = message
    @user = user
    mail(:to => "#{message.email}",
			:subject => I18n.t("mailer.notification.new_organization_member.subject"))
  end

end
