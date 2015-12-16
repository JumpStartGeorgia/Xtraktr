class HelpCategory
  include Mongoid::Document
  field :name, type: String, localize: true

  attr_accessible :name, :name_translations
end
