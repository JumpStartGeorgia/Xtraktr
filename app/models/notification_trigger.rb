class NotificationTrigger
  include Mongoid::Document
  include Mongoid::Timestamps

  #############################

  belongs_to :dataset
  belongs_to :time_series
  belongs_to :user
  belongs_to :invitation

  #############################

  field :notification_type, :type => Integer
  field :processed, :type => Boolean, default: false

  TYPES = {:new_dataset => 1, :new_time_series => 2, :new_user => 3, :new_member => 4}

  #############################
  ## Indexes

  index({ :notification_type => 1}, { background: true})
  index({ :processed => 1}, { background: true})


  #############################
  ## Validations

  validates :notification_type, :presence => true


  #############################
  ## Scopes
  scope :not_processed, where(:processed => false)


  #############################

  def self.process_all_types
    puts "**************************"
    puts "--> Notification Triggers - process all types start at #{Time.now}"
    puts "**************************"
    process_new_user
    process_new_data
    process_new_organization_member
    puts "**************************"
    puts "--> Notification Triggers - process all types end at #{Time.now}"
    puts "**************************"
  end

  #################
  ## new user
  #################
  def self.add_new_user(id)
    NotificationTrigger.create(:notification_type => TYPES[:new_user], :user_id => id)
  end

  def self.process_new_user
    puts "========================================="
    puts "--> Notification Triggers - process new users"
    triggers = NotificationTrigger.where(:notification_type => TYPES[:new_user]).not_processed
    if triggers.present?
      puts "--- triggers exist"
      I18n.available_locales.each do |locale|
        puts "---- #{locale}"
        emails = User.only(:email)
            .where(:notifications => true, :notification_locale => locale)
            .in(:id => triggers.map{|x| x.user_id}.uniq)
        if emails.present?
          puts "----- sending to #{emails.length} users"
          emails_string = emails.map{|x| x.email}.join(';')

          message = Message.new
          message.bcc = emails_string
          message.locale = locale
          message.subject = I18n.t("mailer.notification.new_user.subject", :locale => locale)
          message.message = I18n.t("mailer.notification.new_user.message", :locale => locale)
          puts " ---> message: #{message.inspect}; bcc = #{message.bcc}; locale = #{message.locale}"
          NotificationMailer.send_new_user(message).deliver if !Rails.env.staging?
        end
      end
      NotificationTrigger.in(:id => triggers.map{|x| x.id}).update_all(:processed => true)
    end
  end

  #################
  ## new data
  #################
  def self.add_new_dataset(id)
    puts "======= add new dataset trigger!"
    NotificationTrigger.create(:notification_type => TYPES[:new_dataset], :dataset_id => id)
  end
  def self.add_new_time_series(id)
    puts "======= add new time series trigger!"
    NotificationTrigger.create(:notification_type => TYPES[:new_time_series], :time_series_id => id)
  end

  # send notification if new dataset or time series
  def self.process_new_data
    puts "========================================="
    puts "--> Notification Triggers - process new data"
    triggers = NotificationTrigger.in(:notification_type => [TYPES[:new_dataset], TYPES[:new_time_series]]).not_processed
    if triggers.present?
      puts "--- triggers exist"
      I18n.available_locales.each do |locale|
        puts "---- #{locale}"
        emails = User.only(:email).where(:notifications => true, :notification_locale => locale)

        if emails.present?
          puts "----- found #{emails.length} users to notification"
          emails = emails.map{|x| x.email}.join(';')

          # get datasets
          dataset_ids = triggers.select{|x| x.notification_type == TYPES[:new_dataset]}.map{|x| x.dataset_id}.uniq
          # get time series
          time_series_ids = triggers.select{|x| x.notification_type == TYPES[:new_time_series]}.map{|x| x.time_series_id}.uniq

          message = Message.new
          message.bcc = emails
          message.locale = locale
          message.subject = I18n.t("mailer.notification.new_data.subject", :locale => locale)
          message.message = I18n.t("mailer.notification.new_data.message", :locale => locale)
          puts " ---> message: #{message.inspect}"
          NotificationMailer.send_new_data(message, dataset_ids, time_series_ids).deliver if !Rails.env.staging?
        end
      end
      NotificationTrigger.in(:id => triggers.map{|x| x.id}).update_all(:processed => true)
    end
  end

  #################
  ## story collaboration
  #################
  def self.add_new_organization_member(id)
    NotificationTrigger.create(:notification_type => TYPES[:new_member], :invitation_id => id)
  end

  # slightly different format
  # for invitations that need triggers, get uniq list of emails
  # and then for each email send an invitation
  # - this way if user has > 1 invitation they will all be in one email
  def self.process_new_organization_member
    puts "========================================="
    puts "--> Notification Triggers - process org member"
    triggers = NotificationTrigger.where(:notification_type => TYPES[:new_member]).not_processed
    if triggers.present?
      invitations = Invitation.in(:id => triggers.map{|x| x.invitation_id}.uniq)
      if invitations.present?
        emails = invitations.map{|x| x.to_email}.uniq
        if emails.present?
          orig_locale = I18n.locale
          emails.each do |email|
            invs = invitations.select{|x| x.to_email == email}
            if invs.present?
              # if invitations have user_id, get language
              # else, use default language
              I18n.locale = I18n.default_locale
              user_ids = invs.map{|x| x.to_user_id}.uniq
              user = nil
              if !(user_ids.include?(nil) && user_ids.length == 1)
                # has user id
                I18n.locale = User.get_notification_language_locale(user_ids.select{|x| x.present?}.first)
                user = User.find(user_ids.select{|x| x.present?}.first)
              end

              message = Message.new
              message.email  = email
              message.locale = I18n.locale
              message.subject = I18n.t("mailer.notification.new_organization_member.subject", :locale => I18n.locale)
              message.message = I18n.t("mailer.notification.new_organization_member.message", :locale => I18n.locale)
              message.message_list = []

              invs.each do |inv|
                message.message_list << [inv.from_user.name, inv.key, inv.message]
	            end
              puts " ---> message: #{message.inspect}"
              NotificationMailer.send_new_organization_member(message, user).deliver if !Rails.env.staging?
            end
          end

          # reset the locale
          I18n.locale = orig_locale
        end
      end
      NotificationTrigger.in(:id => triggers.map{|x| x.id}).update_all(:processed => true)
    end
  end


end
