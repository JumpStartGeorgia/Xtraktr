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


  def data_crosstab_analysis(row, col)
    # get uniq values of col
    rows = self.data.map{|x| x[row]}.uniq.sort
    cols = self.data.map{|x| x[col]}.uniq.sort

    results = []
    data = {}

    cols.each do |c|
      puts "--------------------"
      puts "c = #{c}"

      # need to make sure the row value and c value are recorded as strings
      # for if it is an int, the javascript function turns it into a decimal 
      # (2 -> 2.0) and then comparisons do not work!
      map = "
        function() {
           for (var i = 0; i < this.data.length; i++) {
            emit('#{row}', { #{col}: '#{c}', count: 1 }); 
           }
        };
      "

      puts map
      puts "---"


      reduce = "
        function(rowKey, columnValues) {
          var result = { #{col}: '#{c}', count: 0 };

          for (var i = 0; i < columnValues.length; i++) {
            result.count += 1;
          }
          return result;
        };
      "


      puts reduce
      puts "---"

      results << Dataset.where(:id => self.id).map_reduce(map, reduce).out(inline: true).to_a

    end

    # flatten the results
    puts "++ results length was = #{results.length}"
    results.flatten!
    puts "++ results length = #{results.length}"

puts results

    # now put it all together
    data[:row_header] = row.titlecase
    data[:row_answers] = rows
    data[:column_header] = col.titlecase
    data[:column_answers] = cols

    data[:counts] = []
    rows.each do |r|
      data_row = []
      cols.each do |c|
        data_match = results.select{|x| x['_id'].to_s == r.to_s && x['value'][col].to_s == c.to_s}
        if data_match.present?
          data_row << data_match.map{|x| x['value']['count']}.inject(:+)
        else
          data_row << 0
        end
      end
      data[:counts] << data_row
    end

    return data
  end

end