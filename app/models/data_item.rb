class DataItem
  include Mongoid::Document

  belongs_to :person
  belongs_to :dataset

  #############################

  # all codes are downcased and '.' are replaced with '|'
  field :code, type: String
  field :original_code, type: String
  field :data, type: Array

  #############################

  # indexes
  index ({ :code => 1})
  index ({ :original_code => 1})

  #############################

end