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

  # SCOPES

  # get the data item with this code
  def self.with_dataset_code(dataset_id, code)
    where(:dataset_id => dataset_id, :code => code.downcase).first
  end

  # get the data array for the provided code
  def self.dataset_code_data(dataset_id, code)
    x = with_dataset_code(dataset_id, code)
    if x.present?
      return x.data
    else
      return nil
    end
  end


end
