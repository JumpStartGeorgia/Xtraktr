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


  ### perform a crosstab analysis between two hash keys in 
  ### the data array
  ### - row: name of key to put along row of crosstab
  ### - col: name of key to put along the columns of crosstab
  def data_crosstab_analysis(row, col)
    puts "--------------------"
    puts "--------------------"

    # get uniq values
    rows = self.data.select{|x| !x[row].nil?}.map{|x| x[row]}.uniq.sort
    cols = self.data.select{|x| !x[col].nil?}.map{|x| x[col]}.uniq.sort
    puts "unique row values = #{rows}"
    puts "unique col values = #{cols}"

    results = []
    data = {}

    cols.each do |c|
      puts "--------------------"
      puts "c = #{c}"

      # need to make sure the row value and c value are recorded as strings
      # for if it is an int, the javascript function turns it into a decimal 
      # (2 -> 2.0) and then comparisons do not work!
      # - use the if statement to only emit when the row has this value of c and both the row and col have a value
      map = "
        function() {
           for (var i = 0; i < this.data.length; i++) {
            if (this.data[i]['#{row}'] != null && this.data[i]['#{col}'] != null && this.data[i]['#{col}'].toString() == '#{c}'){
              emit(this.data[i]['#{row}'].toString(), { '#{col}': '#{c}', count: 1 }); 
            }
           }
        };
      "

      puts map
      puts "---"

      reduce = "
        function(rowKey, columnValues) {
          return { '#{col}': '#{c}', count: columnValues.length };
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