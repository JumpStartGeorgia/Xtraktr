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

  #############################
  # Callbacks

  # if name or content are '', reset value to nil so fallback works
  def set_to_nil
    self.name_translations.keys.each do |key|
      self.name_translations[key] = nil if self.name_translations[key].empty?
    end
  end

  before_save :set_to_nil

  #############################
  # Scopes

  def self.sorted
    order_by([[:sort_order, :asc], [:name, :asc]])
  end

  def self.by_permalink(permalink)
    find_by(permalink: permalink)
  end
end
