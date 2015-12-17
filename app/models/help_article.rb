# Helps a site user understand XTraktr
class HelpArticle
  include Mongoid::Document
  include Mongoid::Timestamps

  #############################
  attr_accessible :title,
                  :title_translations

  field :title, type: String, localize: true
  index(title: 1)

end
