class Message
  include Mongoid::Document

  field :name, type: String
  field :email, type: String
  field :subject, type: String
  field :message, type: String
  
  validates_presence_of :name
  validates_presence_of :email
  validates_format_of :email, :with => Devise.email_regexp, allow_blank: false
  validates_presence_of :body
  validates_length_of :message, :maximum => 500
end