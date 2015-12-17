class HelpCategory
  include Mongoid::Document

  #############################
  attr_accessible :name,
                  :name_translations,
                  :permalink,
                  :sort_order
  #############################

  field :name, type: String, localize: true
  field :permalink, type: String
  field :sort_order, type: Integer, default: 1

  #############################
  # indeces
  index ({ :permalink => 1})
  index ({ :name => 1})
  index ({ :sort_order => 1})
end
