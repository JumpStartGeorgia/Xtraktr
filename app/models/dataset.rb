class Dataset
  require 'process_data_file'
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip
  include ProcessDataFile # script in lib folder that will convert datafile to csv and then load into appropriate fields

  #############################

  belongs_to :user

  #############################
  # paperclip data file storage
  has_mongoid_attached_file :datafile, :url => "/system/datasets/:id/original/:filename", :use_timestamp => false

  field :title, type: String
  field :description, type: String
  field :dates_gathered, type: String
  field :released_at, type: Date
  field :data_created_by, type: String
  # indicate if questions_with_bad_answers has data
  field :has_warnings, type: Boolean, default: false
  # array of hashes {code1: value1, code2: value2, etc}
  field :data, type: Array
  # hash of questions codes and text 
  # {code1: {text:question1, original_code:code1, has_code_answers:true}, code2: {text:question2, original_code:code2, has_code_answers:false}}
  # mongo key names cannot include a '.' so if there is one, it was replaced with '|'
  # - hence the need for recording the original code value
#  field :questions, type: Hash
  # hash of array of question answers (answer value and answer text) 
  # {code1: [{value: value1, text: text1, can_exclude:false, sort_order: 1}, {value: value2, text: text2, sort_order: 2}] }
#  field :answers, type: Hash
  # array of question codes who possibly have answer values that are not in the provided list of possible answers
  field :questions_with_bad_answers, type: Array
  # indicates if any questions in this dataset have been connected to a shapeset
  field :is_mappable, type: Boolean, default: false

  embeds_many :questions do
    # these are functions that will query the questions documents

    # get the question that has the provide code
    def with_code(code)
      where(:code => code).first
    end

    def with_original_code(original_code)
      where(:original_code => original_code).first
    end

    # get all of the questions with code answers
    def with_code_answers
      where(:has_code_answers => true).to_a
    end

    # get all of the questions with no code answers
    def with_no_code_answers
      where(:has_code_answers => false).to_a
    end

    def all_answers
      only(:code, :answers)
    end

    # get just the codes
    def unique_codes
      only(:code).map{|x| x.code}
    end

    # get all questions that are mappable
    def are_mappable
      where(:is_mappable => true)
    end

  end
  accepts_nested_attributes_for :questions

  #############################
  # indexes
  index ({ :title => 1})
  index ({ :released_at => 1})
  index ({ :user_id => 1})
  index ({ :shapeset_id => 1})
  index ({ :'questions.text' => 1})
  index ({ :'questions.is_mappable' => 1})
  index ({ :'questions.has_code_answers' => 1})
  index ({ :'answers.can_exclude' => 1})
  index ({ :'answers.sort_order' => 1})


  #############################
  # Validations
  validates_presence_of :title
  validates_attachment :datafile, :presence => true, 
      :content_type => { :content_type => ["application/x-spss-sav", "application/octet-stream", "text/csv"] }


  #############################
  attr_accessible :title, :description, :data, :user_id, 
      :questions_attributes, :questions_with_bad_answers, :datafile, :has_warnings


  TYPE = {:onevar => 'onevar', :crosstab => 'crosstab'}

  FOLDER_PATH = "/system/datasets"
  JS_FILE = "shapes.js"

  #############################

  before_create :process_file
  after_destroy :delete_dataset_files
  before_save :update_flags

  # process the datafile and save all of the information from it
  def process_file
    process_spss
  end

  # make sure all of the data files that were generated for this dataset are deleted
  def delete_dataset_files
    FileUtils.rm_r("#{Rails.root}/public#{FOLDER_PATH}/#{self.id}")
  end

  def update_flags
#    self.has_warnings = self.questions_with_bad_answers.present? if self.questions_with_bad_answers_changed?
    self.has_warnings = self.questions_with_bad_answers.present? || self.questions.with_no_code_answers.present?

    return true
  end

  # this is called from an embeded question if the is_mappable value changed in that question
  def update_mappable_flag
    puts "==== question mappable = #{self.questions.index{|x| x.is_mappable == true}.present?}"
    self.is_mappable = self.questions.index{|x| x.is_mappable == true}.present?
    self.save

    # if this dataset is mappable, create the js file with the geojson in it
    # else, delete the js file
    if self.is_mappable?
      puts "=== creating js file"
      # create hash of shapes in format: {code => geojson, code => geojson}
      shapes = {}
      self.questions.are_mappable.each do |question|
        shapes[question.code] = question.shapeset.get_geojson
      end

      # write geojson to file
      File.open(js_shapefile_file_path, 'w') do |f|
        f << "var highmap_shapes = " + shapes.to_json
      end
    else
      # delete js file
      puts "==== deleting shape js file at #{js_shapefile_file_path}"
      FileUtils.rm js_shapefile_file_path if File.exists?(js_shapefile_file_path)
    end

    return true
  end

  #############################

  def self.sorted
    order_by([[:title, :asc]])
  end

  # get the basic info about the dataset
  # - title, description
  def self.basic_info
    only(:_id, :title, :description, :has_warnings, :is_mappable)
  end

  # get the questions with bad answers
  def self.warnings
    only(:_id, :title, :has_warnings, :questions_with_bad_answers, :questions)
  end

  #############################

  # get the js shape file path
  def js_shapefile_file_path
    "#{Rails.root}/public#{FOLDER_PATH}/#{self.id}/#{JS_FILE}"
  end

  def js_shapefile_url_path
    "#{FOLDER_PATH}/#{self.id}/#{JS_FILE}"
  end

  #############################

  ### perform a summary analysis of one hash key in 
  ### the data array
  ### - row: name of key to put along row of crosstab
  def data_onevar_analysis(row, options={})
#    puts "--------------------"
#    puts "--------------------"

    result = {}
    data = []

    # get the question/answers
    result[:row_code] = row
    row_question = self.questions.with_code(row)
    result[:row_question] = row_question.text
    result[:row_answers] = row_question.answers.sort_by{|x| x.sort_order}
    result[:type] = TYPE[:onevar]
    result[:counts] = []
    result[:percents] = []
    result[:total_responses] = nil
    result[:chart] = {}

    # if the row question/answers were found, continue
    if result[:row_question].present? && result[:row_answers].present?
      # get uniq values
      row_answers = result[:row_answers].map{|x| x.value}.sort
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

#      puts map
#      puts "---"

      # countRowValue will be an array of ones from the map function above
      # for the total number of times that the row value appears in data
      # count the length of the array to see how many times it appears
      reduce = "
        function(rowValue, countRowValue) {
          return countRowValue.length;
        };
      "

#      puts reduce
#      puts "---"

      data << Dataset.where(:id => self.id).map_reduce(map, reduce).out(inline: true).to_a

      # flatten the data
#      puts "++ data length was = #{data.length}"
      data.flatten!
#      puts "++ data length = #{data.length}"

      if data.present?
        # now put it all together
        # - create counts
        result[:row_answers].each do |row_answer|
          # look for match in data
          data_match = data.select{|x| x['_id'].to_s == row_answer.value.to_s}.first
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
#        result[:total_responses] = result[:counts].inject(:+).to_i
        result[:total_responses] = result[:counts].inject(:+).to_i

        # - format data for charts
        # pie chart requires data to be in following format:
        # [ {name, y, count}, {name, y, count}, ...]
        result[:chart][:data] = []
        (0..result[:row_answers].length-1).each do |index|
          result[:chart][:data] << {
            name: result[:row_answers][index].text, 
            y: result[:percents][index], 
            count: result[:counts][index], 
          }
        end

        # - if row is a mappable variable, create the map data
        if row_question.is_mappable?
          result[:map] = {}
          result[:map][:data] = []
          result[:map][:question_code] = row

          result[:row_answers].each_with_index do |row_answer, row_index|
            # store in highmaps format: {name, value, count}
            result[:map][:data] << {:name => row_answer.text, :value => result[:percents][row_index], :count => result[:counts][row_index]}
          end
        end
      end
    end

    return result
  end

  ### perform a crosstab analysis between two hash keys in 
  ### the data array
  ### - row: name of key to put along row of crosstab
  ### - col: name of key to put along the columns of crosstab
  def data_crosstab_analysis(row, col, options={})
#    puts "--------------------"
#    puts "--------------------"

    result = {}
    data = []

    # get the question/answers
    result[:row_code] = row
    row_question = self.questions.with_code(row)
    result[:row_question] = row_question.text
    result[:row_answers] = row_question.answers.sort_by{|x| x.sort_order}
    result[:column_code] = col
    col_question = self.questions.with_code(col)
    result[:column_question] = col_question.text
    result[:column_answers] = col_question.answers.sort_by{|x| x.sort_order}
    result[:type] = TYPE[:crosstab]
    result[:counts] = []
    result[:percents] = []
    result[:total_responses] = nil
    result[:chart] = {}


    # if the row and col question/answers were found, continue
    if result[:row_question].present? && result[:row_answers].present? && result[:column_question].present? && result[:column_answers].present?
      # get uniq values
      row_answers = result[:row_answers].map{|x| x.value}.sort
      col_answers = result[:column_answers].map{|x| x.value}.sort
      puts "unique row values = #{row_answers}"
      puts "unique col values = #{col_answers}"

      col_answers.each do |c|
#        puts "--------------------"
#        puts "c = #{c}"

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

#        puts map
#        puts "---"

        reduce = "
          function(rowKey, columnValues) {
            return { '#{col}': '#{c}', count: columnValues.length };
          };
        "

#        puts reduce
#        puts "---"

        data << Dataset.where(:id => self.id).map_reduce(map, reduce).out(inline: true).to_a

      end

      # flatten the data
#      puts "++ data length was = #{data.length}"
      data.flatten!
#      puts "++ data length = #{data.length}"
#      puts "-----------"
#      puts data.inspect
#      puts "-----------"

      if data.present?
        # now put it all together

        # - create counts
        result[:row_answers].each do |r|
          data_row = []
          result[:column_answers].each do |c|
            data_match = data.select{|x| x['_id'].to_s == r.value.to_s && x['value'][col].to_s == c.value.to_s}
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
        result[:total_responses] = totals.inject(:+).to_i

        # - format data for charts
        result[:chart][:labels] = result[:row_answers].map{|x| x.text}
        result[:chart][:data] = []
        counts = result[:counts].transpose

        (0..result[:column_answers].length-1).each do |index|
          item = {}
          item[:name] = result[:column_answers][index].text
          item[:data] = counts[index]
          result[:chart][:data] << item
        end

        # - if row or column is a mappable variable, create the map data
        if row_question.is_mappable? || col_question.is_mappable?
          result[:map] = {}
          result[:map][:data] = {}

          # if the row is the mappable, recompute percents so columns add up to 100%
          if row_question.is_mappable?
            result[:map][:question_code] = row
            result[:map][:filter] = col_question.text
            result[:map][:filters] = result[:column_answers]

            counts = result[:counts].transpose
            percents = []
            counts.each do |count_row|
              total = count_row.inject(:+)
              if total > 0
                percent_row = []
                count_row.each do |item|
                  percent_row << (item.to_f/total*100).round(2)
                end
                percents << percent_row
              else
                percents << Array.new(count_row.length){0}
              end
            end

            result[:column_answers].each_with_index do |col_answer, col_index|
              # create hash to store the data for this answer
              result[:map][:data][col_answer.value.to_s] = []

              # now store the results for each item
              (0..result[:row_answers].length-1).each do |index|
                # store in highmaps format: {name, value, count}
                result[:map][:data][col_answer.value.to_s] << {:name => result[:row_answers][index].text, :value => percents[col_index][index], :count => counts[col_index][index]}
              end 
            end

          else
            result[:map][:question_code] = col
            result[:map][:filter] = row_question.text
            result[:map][:filters] = result[:row_answers]

            result[:row_answers].each_with_index do |row_answer, row_index|
              # create hash to store the data for this answer
              result[:map][:data][row_answer.value.to_s] = []

              # now store the results for each item
              (0..result[:column_answers].length-1).each do |index|
                # store in highmaps format: {name, value, count}
                result[:map][:data][row_answer.value.to_s] << {:name => result[:column_answers][index].text, :value => result[:percents][row_index][index], :count => result[:counts][row_index][index]}
              end 
            end
          end
        end
      end
    end

    return result
  end

end