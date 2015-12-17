class HelpCategory
  include Mongoid::Document

  attr_accessible :name,
                  :name_translations,
                  :permalink,
                  :sort_order

  field :name, type: String, localize: true
  field :permalink, type: String
  field :sort_order, type: Integer, default: 1
end
