class Dataset
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title,         type: String
  field :explanation,   type: String
  field :data_headers,  type: Hash
  field :data,          type: Array

  # Validations
  validates_presence_of :title



  def self.load_csv(title, explanation, file_path)
    if File.exists?(file_path)
      d = Dataset.new(:title => title, :explanation => explanation)

      d.data = SmarterCSV.process(file_path)

      if d.data.present?
        d.data_headers = {}

        # get the keys
        keys = d.data.first.keys

        # read in first line of csv to get real header names
        CSV.foreach(file_path) do |row|
          keys.each_with_index do |key, index|
            d.data_headers[key] = row[index]
          end

          # only need first row, so stop
          break
        end
      end

      d.save
    end
  end


end