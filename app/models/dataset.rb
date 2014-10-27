class Dataset
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip
  include ProcessDataFile # script in lib folder that will convert datafile to csv and then load into appropriate fields

  # paperclip data file storage
  has_mongoid_attached_file :datafile, :url => "/system/datasets/:id/original/:filename", :use_timestamp => false

  field :title, type: String
  field :description, type: String
  field :dates_gathered, type: String
  field :date_released, type: Date
  field :data_created_by, type: String
  # array of hashes {code1: value1, code2: value2, etc}
  field :data, type: Array
  # hash of questions codes and text {code1: {text:question1, original_code:code1}, code2: {text:question2, original_code:code2}}
  # mongo key names cannot include a '.' so if there is one, it was replaced with '|'
  # - hence the need for recording the original code value
  field :questions, type: Hash
  # hash of array of question answers (answer value and answer text) {code1: [{value: value1, text: text1}, {value: value2, text: text2}] }
  field :answers, type: Hash
  # array of question codes who possibly have answer values that are not in the provided list of possible answers
  field :questions_with_bad_answers, type: Array

  # Validations
  validates_presence_of :title
  validates_attachment :datafile, :presence => true, 
      :content_type => { :content_type => ["application/x-spss-sav", "application/octet-stream", "text/csv"] }

  attr_accessible :title, :explanation, :data, :questions, :answers, :questions_with_bad_answers, :datafile

  before_create :process_file
  after_destroy :delete_dataset_files

  TYPE = {:onevar => 'onevar', :crosstab => 'crosstab'}

  # process the datafile and save all of the information from it
  def process_file
    process_spss
  end

  # make sure all of the data files that were generated for this dataset are deleted
  def delete_dataset_files
    FileUtils.rm_r("#{Rails.root}/public/system/datasets/#{self.id}")
  end

  ### perform a summary analysis of one hash key in 
  ### the data array
  ### - row: name of key to put along row of crosstab
  def data_onevar_analysis(row, options={})
    puts "--------------------"
    puts "--------------------"

    result = {}
    data = []

    # get the question/answers
    result[:row_code] = row
    result[:row_question] = self.questions[row]
    result[:row_answers] = self.answers[row]
    result[:type] = TYPE[:onevar]
    result[:counts] = []
    result[:percents] = []
    result[:total_responses] = nil
    result[:chart] = {}

    # if the row question/answers were found, continue
    if result[:row_question].present? && result[:row_answers].present?
      # get uniq values
      row_answers = result[:row_answers].select{|x| !x['value'].nil?}.map{|x| x['value']}.uniq.sort
      puts "unique row values = #{row_answers}"

      # get the counts of each row value
      map = "
        function(){
          if (!this.data){
            return;
          }

          for (var i = 0; i < this.data.length; i++) {
            if (this.data[i]['#{row}'] != null){
              emit(this.data[i]['#{row}'].toString(), 1 ); 
            }
          }

        }
      "

      puts map
      puts "---"

      # countRowValue will be an array of ones from the map function above
      # for the total number of times that the row value appears in data
      # count the length of the array to see how many times it appears
      reduce = "
        function(rowValue, countRowValue) {
          return countRowValue.length;
        };
      "

      puts reduce
      puts "---"

      data << Dataset.where(:id => self.id).map_reduce(map, reduce).out(inline: true).to_a

      # flatten the data
      puts "++ data length was = #{data.length}"
      data.flatten!
      puts "++ data length = #{data.length}"
puts "-----"
      puts data.inspect
puts "-----"
puts result[:row_answers]
puts "-----"

      # now put it all together
      # - create counts
      result[:row_answers].each do |row_answer|

        # look for match in data
        data_match = data.select{|x| x['_id'].to_s == row_answer['value'].to_s}.first
        if data_match.present?
          result[:counts] << data_match['value']
        else
          result[:counts] << 0
        end
      end

      # - take counts and turn into percents
      total = result[:counts].inject(:+)
      result[:counts].each do |count_item|
        result[:percents] << (count_item.to_f/total*100).round(2)
      end

      # - record the total number of responses
      result[:total_responses] = result[:counts].inject(:+)

      # - format data for charts
      # pie chart requires data to be in following format:
      # [ {name, y, count}, {name, y, count}, ...]
      result[:chart][:data] = []
      (0..result[:row_answers].length-1).each do |index|
        result[:chart][:data] << {
          name: result[:row_answers][index]['text'], 
          y: result[:percents][index], 
          count: result[:counts][index], 
        }
      end

    end

    return result
  end

  ### perform a crosstab analysis between two hash keys in 
  ### the data array
  ### - row: name of key to put along row of crosstab
  ### - col: name of key to put along the columns of crosstab
  def data_crosstab_analysis(row, col)
    puts "--------------------"
    puts "--------------------"

    result = {}
    data = []

    # get the question/answers
    result[:row_code] = row
    result[:row_question] = self.questions[row]
    result[:row_answers] = self.answers[row]
    result[:column_code] = col
    result[:column_question] = self.questions[col]
    result[:column_answers] = self.answers[col]
    result[:type] = TYPE[:crosstab]
    result[:counts] = []
    result[:percents] = []
    result[:total_responses] = nil
    result[:chart] = {}


    # if the row and col question/answers were found, continue
    if result[:row_question].present? && result[:row_answers].present? && result[:column_question].present? && result[:column_answers].present?
      # get uniq values
      row_answers = result[:row_answers].select{|x| !x['value'].nil?}.map{|x| x['value']}.uniq.sort
      col_answers = result[:column_answers].select{|x| !x['value'].nil?}.map{|x| x['value']}.uniq.sort
      puts "unique row values = #{row_answers}"
      puts "unique col values = #{col_answers}"

      col_answers.each do |c|
        puts "--------------------"
        puts "c = #{c}"

        # need to make sure the row value and c value are recorded as strings
        # for if it is an int, the javascript function turns it into a decimal 
        # (2 -> 2.0) and then comparisons do not work!
        # - use the if statement to only emit when the row has this value of c and both the row and col have a value
        map = "
          function() {
             if (!this.data){
              return;
             }
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

        data << Dataset.where(:id => self.id).map_reduce(map, reduce).out(inline: true).to_a

      end

      # flatten the data
      puts "++ data length was = #{data.length}"
      data.flatten!
      puts "++ data length = #{data.length}"

      # now put it all together
      # - create counts
      row_answers.each do |r|
        data_row = []
        col_answers.each do |c|
          data_match = data.select{|x| x['_id'].to_s == r.to_s && x['value'][col].to_s == c.to_s}
          if data_match.present?
            data_row << data_match.map{|x| x['value']['count']}.inject(:+)
          else
            data_row << 0
          end
        end
        result[:counts] << data_row
      end

      # - take counts and turn into percents
      totals = []
      result[:counts].each do |count_row|
        total = count_row.inject(:+)
        totals << total
        if total > 0
          percent_row = []
          count_row.each do |item|
            percent_row << (item.to_f/total*100).round(2)
          end
          result[:percents] << percent_row
        else
          result[:percents] << Array.new(count_row.length){0}
        end
      end

      # - record the total number of responses
      result[:total_responses] = totals.inject(:+)

      # - format data for charts
      result[:chart][:labels] = result[:row_answers].map{|x| x['text']}
      result[:chart][:data] = []
      counts = result[:counts].transpose

      (0..result[:column_answers].length-1).each do |index|
        item = {}
        item[:name] = result[:column_answers][index]['text']
        item[:data] = counts[index]
        result[:chart][:data] << item
      end


    end

    return result
  end

end