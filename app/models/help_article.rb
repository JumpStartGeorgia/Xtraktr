class HelpArticle
  include Mongoid::Document
  include Mongoid::Timestamps

  #############################
  attr_accessible :title

  field :title, type: String
end
