# encoding: utf-8
module ProcessDataFile
  require 'csv'
  DATA_TYPE_VALUES = Question::DATA_TYPE_VALUES
  #######################
  #######################
  ##
  ## run a data file (spss, sas, etc) throuh an R script
  ## that generates CSV files of data, questions and answers
  ##
  #######################
  #######################



  #######################
  ## global variables
  @@path = "#{Rails.public_path}/system/datasets/[dataset_id]/processed/"
  @@file_data = 'data.csv'
  @@file_questions = 'questions.csv'
  @@file_answers = 'answers.csv'
  @@r_file = {
    'sav' => 'spss_to_csv.r',
    'dta' => 'stata_to_csv.r'
  }
  @@spreadsheet_question_code = 'Q'


  #######################
  # process a data file
  def process_data_file
    start = Time.now
    puts "$$$$$$ process_data_file"

    # if file extension does not exist, get it
    self.file_extension = File.extname(self.datafile.url).gsub('.', '').downcase if self.file_extension.blank?

    # set flag on whether or not this is a spreadsheet
    is_spreadsheet = case self.file_extension
      when 'csv', 'ods', 'xls', 'xlsx'
        true
      else
        false
    end

    puts "$$$$$$$ file ext = #{self.file_extension}; is spreadsheet = #{is_spreadsheet}"

    path = @@path.sub('[dataset_id]', self.id.to_s)
    # check if file has been saved yet
    # if file has not be saved to proper place yet, have to get queued file path
    file_to_process = "#{Rails.public_path}/#{self.datafile.url}"
    if !File.exists?(file_to_process) && self.datafile.queued_for_write[:original].present?
      file_to_process = self.datafile.queued_for_write[:original].path
    end

    file_r = "#{Rails.root}/script/r_scripts/#{@@r_file[self.file_extension]}" if !is_spreadsheet
    file_data = path + @@file_data
    file_questions = path + @@file_questions
    file_answers = path + @@file_answers

    # make sure files exists
    if (is_spreadsheet || (!is_spreadsheet && File.exists?(file_r))) && File.exists?(file_to_process)

      # create dataset directory if not exist
      FileUtils.mkdir_p(File.dirname(file_data))

      # process the file and populate the data, questions and answers csv spreadsheet files
      results = nil
      start_task = Time.now
      case self.file_extension
        when 'sav'
          results = process_spss(file_to_process, file_r, file_data, file_questions, file_answers)
        when 'dta'
          results = process_stata(file_to_process, file_r, file_data, file_questions, file_answers)
        when 'csv', 'xls', 'xlsx', 'ods'
          results = process_spreadsheet(file_to_process, file_data, file_questions, file_answers)
      end
      puts "=============================="
      puts ">>>>>>> it took #{Time.now-start_task} seconds to process the data file"
      puts "=============================="

      if results.nil? || results == false
        puts "Error was #{$?}"
        errors.add(:datafile, "bad datafile!")
        return false
      elsif results
        puts "DATA FILE WAS PROCESSED!"

        puts "=============================="
        puts "reading in questions from #{file_questions} and saving to questions attribute"
        question_codes = [] # record the question codes from the questions file
        start_task = Time.now

        if File.exists?(file_questions)
          line_number = 0
          CSV.foreach(file_questions, headers: true).each_with_index do |row, i|
            # row format: question code, question text, 
            line_number += 1

            # only add if the code is present
            if row[0].present? && row[0].strip.present?

              question_codes << [clean_text(row[0], format_code: true), clean_text(row[0])]
              ln = question_codes.length-1

              # determine the data type
              # - we only know the data type here if data file is not spreadsheet and data type column (col 2) exists
              data_type = DATA_TYPE_VALUES[:unknown]
              if !is_spreadsheet && row.length > 2 && row[2].present?
                case row[2].downcase
                  when 'c'
                    data_type = DATA_TYPE_VALUES[:categorical]
                  when 'n'
                    data_type = DATA_TYPE_VALUES[:numerical]
                end

              end
              # mongo does not allow '.' in key names, so replace with '|'
              self.questions_attributes = [{code: question_codes[ln][0],
                                            original_code: question_codes[ln][1],
                                            text_translations: {self.default_language => clean_text(row[1])},
                                            sort_order: i+1,
                                            data_type: data_type
                                          }]
            end
          end
        end
        puts " - added #{self.questions.length} questions"
        puts "=============================="
        puts ">>>>>>> it took #{Time.now-start_task} seconds to add the questions"
        puts "=============================="


        puts "=============================="
        puts "reading in answers from #{file_answers} and adding to questions"
        start_task = Time.now
        if File.exists?(file_answers)
          line_number = 0
          last_key = nil
          sort_order = 0
          CSV.foreach(file_answers, headers: true) do |row|
            line_number += 1

            # it is possible that the answer is nil so it will have a length of two
            # - when this happens, add a '' to row so there are 3 values
            if row.length == 2
              puts "---> answer does not have text, adding ''"              
              row << ''
            end

            if row.length == 3
              # add the answer to the appropriate question
              # save to answers attribute
              key = clean_text(row[0], format_code: true)
              question = self.questions.with_code(key)
              if question.present?
                # if this is a new key (question code), reset sort variables
                if last_key != key
                  last_key = key.dup
                  sort_order = 0
                end
                # create sort order that is based on order they are listed in data file
                sort_order += 1
                # - add the answer to the question
                question.answers_attributes  = [{value: clean_text(row[1]),
                                                text_translations: { self.default_language => clean_text(row[2]) },
                                                sort_order: sort_order
                                              }]
                # update question to indciate it has answers
                question.has_code_answers = true
                question.is_analysable = true
                # set the data type if it is not set yet
                # - will not be set if this is spreadsheet
                if question.data_type.nil?
                  question.data_type = DATA_TYPE_VALUES[:categorical]
                end

              else
                puts "******************************"
                puts "Line #{line_number} of #{file_answers} has a question code #{key} that could not be found in the list of questions."
                puts "******************************"
              end
            else
              puts "******************************"
              puts "ERROR"
              puts "An error occurred on line #{line_number} of #{file_answers} while parsing the answers."
              puts "This line was not in the correct format of: Question Code, Answer Value, Answer Text"
              puts "******************************"
              return false
            end
          end
        end
        puts "=============================="
        puts ">>>>>>> it took #{Time.now-start_task} seconds to add question answers"
        puts "=============================="


        puts "=============================="
        puts "saving data from #{file_data} and to data_items attribute"
        # if this is a spreadsheet do not use the quote char setting
        if is_spreadsheet
          data = CSV.read(file_data, headers: true)
        else
          data = CSV.read(file_data, quote_char: "\0", headers: true)
        end
        # only conintue if the # of cols match the # of quesiton codes
        if data.first.length == question_codes.length
          question_codes.each_with_index do |code, code_index|
            puts "@@@@@@@@@@@ code index = #{code_index}, code = #{code}"
            clean_code = code[0]

            code_data = data.map{|x| x[code_index]}
            total = 0
            frequency_data = {}
            formatted_data = nil
            question = self.questions.with_code(clean_code)
            if code_data.present? && question.present?
              # build frequency/stats for question if needed
              if question.data_type == DATA_TYPE_VALUES[:categorical] # build basic frequency info for categorical questions
                puts "@@@@@@@@@@@ - question is categorical"
                question.answers.sorted.each {|answer|
                  cnt = code_data.select{|x| x == answer.value }.count
                  total += cnt
                  frequency_data[answer.value] = [cnt, (cnt.to_f/code_data.length*100).round(2)]
                }
                question.has_data_without_answers = total < code_data.select{|d| !d.nil? }.length 

              elsif question.data_type == DATA_TYPE_VALUES[:numerical] # build numerical descriptive stats for numerical questions
                puts "@@@@@@@@@@@ - question is numerical"
                # flag that is set to false if:
                # - data has no numeric data
                # - there is no repeating values in the data (most likely an ID field)
                #   - computing stats on ID field can take a long time and possibly crash the system 
                #     so lets skip it until the user asks for it
                #   - have found that ID field can have repeating values, so using a 90% threshold
                #     to determine whether or not to compute the numerical info
                #     - if unique data is less than 90% in length from full list -> compute
                has_numeric_data = (code_data.uniq.length / code_data.length.to_f) < 0.9

                if has_numeric_data
                  unique_answer_values = question.answers.unique_values

                  # first have to determine if data is int or float
                  int_data = []
                  float_data = []
                  # get uniq data items and remove ones that are predefined answers
                  unique_data = code_data.uniq - unique_answer_values
                  # if item is int or float, add it to array
                  unique_data.each do |x|
                    if (x =~ /\A[-+]?\d+\z/) != nil # int
                      int_data << x.to_i
                    elsif (x =~ /\A[-+]?\d*\.?\d+\z/) != nil # float
                      float_data << x.to_f
                    end
                  end  

                  # make sure at least some numeric data was found
                  has_numeric_data = int_data.present? || float_data.present?
                end
                
                if has_numeric_data
                  num = Numerical.new
                  
                  # if float_data has any values then it is float
                  # else int
                  num.type = float_data.present? ? Numerical::TYPE_VALUES[:float] : Numerical::TYPE_VALUES[:integer]

                  # get min and max values
                  # - merge the two data arrays and then get min/max
                  #   (if data is float, it still might have int values too)
                  merge_data = int_data + float_data
                  num.min = merge_data.min.to_f
                  num.max = merge_data.max.to_f
                  num.max += 1 if num.min == num.max # if min and max are the same increase max by 1

                  # set bar width
                  # - if the difference between max and min is less than default width, use 1
                  #   else use default width
                  #num.width = (num.max - num.min) > Numerical::NUMERIC_DEFAULT_WIDTH ? Numerical::NUMERIC_DEFAULT_WIDTH : 1
                  range = num.max - num.min
                  num.width = range > Numerical::NUMERIC_DEFAULT_WIDTH ? (range/Numerical::NUMERIC_DEFAULT_WIDTH).ceil : 1                   
                  
                  # set ranges and size
                  num.min_range = (num.min / num.width).floor * num.width
                  num.max_range = (num.max / num.width).ceil * num.width
                  num.size = (num.max_range - num.min_range) / num.width

                  # set teh numerical object
                  question.numerical = num

                  formatted_data = []
                  vfd = [] # only valid formatted data for calculating stats
                  fd = Array.new(num.size, [0,0])

                  #formatted and grouped data calculation
                  code_data.each {|d|
                    if is_numeric?(d) && !unique_answer_values.include?(d)
                      if num.type == Numerical::TYPE_VALUES[:integer]
                        tmpD = d.to_i
                      elsif num.type == Numerical::TYPE_VALUES[:float]
                        tmpD = d.to_f
                      end

                      if tmpD.present? && tmpD >= num.min && tmpD <= num.max
                        formatted_data.push(tmpD);
                        vfd.push(tmpD);

                        index = tmpD == num.min_range ? 0 : ((tmpD-num.min_range)/num.width-0.00001).floor
                        fd[index][0] += 1
                      else 
                        formatted_data.push(nil);
                      end
                    else 
                      formatted_data.push(nil)
                    end

                  }
                  total = 0
                  fd.each {|x| total+=x[0]}
                  fd.each_with_index {|x,i| 
                     fd[i][1] = (x[0].to_f/total*100).round(2) }

                  frequency_data = fd;

                  vfd.extend(DescriptiveStatistics) # descriptive statistics
                  
                  question.descriptive_statistics = {
                    :number => vfd.number.to_i,
                    :min => num.integer? ? vfd.min.to_i : vfd.min,
                    :max => num.integer? ? vfd.max.to_i : vfd.max,
                    :mean => vfd.mean,
                    :median => num.integer? ? vfd.median.to_i : vfd.median,
                    :mode => num.integer? ? vfd.mode.to_i : vfd.mode,
                    :q1 => num.integer? ? vfd.percentile(25).to_i : vfd.percentile(25),
                    :q2 => num.integer? ? vfd.percentile(50).to_i : vfd.percentile(50),
                    :q3 => num.integer? ? vfd.percentile(75).to_i : vfd.percentile(75),
                    :variance => vfd.variance,
                    :standard_deviation => vfd.standard_deviation
                  }
                  # mark the question as being analyzable
                  question.is_analysable = true
                end
                


                question.has_data_without_answers = code_data.select{|d| !d.nil? }.length > 0 
              else
                question.has_data_without_answers = code_data.select{|d| !d.nil? }.length > 0 
              end
              # add the data for this question
              self.data_items_attributes = [{code: clean_code,
                                            original_code: code[1],
                                            data: code_data
                                          }.merge(frequency_data.present? ? { frequency_data: frequency_data, frequency_data_total: total, formatted_data: formatted_data } : {})]
              
            else
              puts "******************************"
              puts "Column #{code_index} (supposed to be #{code}) of #{file_questions} does not exist."
              puts "******************************"
            end
          end
        else
          puts "******************************"
          puts "ERROR"
          puts "The number of columns in #{file_data} (#{data.first.length}) does not match the number of question codes #{self.questions.unique_codes.length}"
          puts "******************************"
        end
        puts "added #{self.data_items.length} columns worth of data"
        puts "=============================="
        puts ">>>>>>> it took #{Time.now-start_task} seconds to add the data items"
        puts "=============================="
      end
    else
      puts "******************************"
      puts "WARNING"
      puts "The required R script file or the data file to process do not exist"
      puts "******************************"
    end

    puts "=============================="
    puts "=============================="
    puts ">>>>>>> it took #{Time.now-start} seconds to finish processing the data file"
    puts "=============================="
    puts "=============================="
    return true
  end


 # process a data file
  def reprocess_data_file
    t = Timer.new
    t.start("process_data_file started")

    self.file_extension = File.extname(self.datafile.url).gsub('.', '').downcase if self.file_extension.blank? # if file extension does not exist, get it

    is_spreadsheet = ['csv', 'ods', 'xls', 'xlsx'].include?(self.file_extension) # set flag on whether or not this is a spreadsheet
    
    t.msg("file_extension = #{self.file_extension}; is_spreadsheet = #{is_spreadsheet}")

    path = @@path.sub('[dataset_id]', self.id.to_s)

    # check if file has been saved yet
    # if file has not be saved to proper place yet, have to get queued file path
    file_to_process = "#{Rails.public_path}#{self.datafile.url}"
    if !File.exists?(file_to_process) && self.datafile.queued_for_write[:original].present?      
      file_to_process = self.datafile.queued_for_write[:original].path
    end

    file_r = "#{Rails.root}/script/r_scripts/#{@@r_file[self.file_extension]}" if !is_spreadsheet
    file_data = path + @@file_data
    file_questions = path + @@file_questions
    file_answers = path + @@file_answers

    # make sure files exists
    if (is_spreadsheet || (!is_spreadsheet && File.exists?(file_r))) && File.exists?(file_to_process)

      # create dataset directory if not exist
      FileUtils.mkdir_p(File.dirname(file_data))

      # process the file and populate the data, questions and answers csv spreadsheet files
      results = nil

      t.start("processing data file #{self.file_extension}")
      case self.file_extension
        when 'sav'
          results = process_spss(file_to_process, file_r, file_data, file_questions, file_answers)
        when 'dta'
          results = process_stata(file_to_process, file_r, file_data, file_questions, file_answers)
        when 'csv', 'xls', 'xlsx', 'ods'
          results = process_spreadsheet(file_to_process, file_data, file_questions, file_answers)
      end
      t.end("to process data file")

      if results.nil? || results == false
        t.msg("Error was #{$?}")
        errors.add(:datafile, "bad datafile!")
        return false
      elsif results


        t.start("process questions")

        question_codes = [] # record the question codes from the questions file

        if File.exists?(file_questions)

          # only add if the code is present
          unknown_codes = self.questions.codes_with_unknown_datatype


          CSV.foreach(file_questions, headers: true).each_with_index do |row, i| # row format: question code, question text, data_type(c|n) 
            
            code = clean_text(row[0], format_code: true)

            if code.present? # only add if the code is present and unknown
              question_codes << [code, clean_text(row[0])]
              if unknown_codes.include?(code)
                data_type = DATA_TYPE_VALUES[:unknown] # determine the data type
                if !is_spreadsheet && row.length > 2 && row[2].present?
                  case row[2].downcase
                    when 'c'
                      data_type = DATA_TYPE_VALUES[:categorical]
                    when 'n'
                      data_type = DATA_TYPE_VALUES[:numerical]
                  end
                end              
                self.questions.with_code(code).data_type = data_type if data_type != DATA_TYPE_VALUES[:unknown]
              end
            end
          end
        end
        t.end("to add #{self.questions.length} questions")


        t.start("process data_items")
        # if this is a spreadsheet do not use the quote char setting
        data = is_spreadsheet ? CSV.read(file_data, headers: true) : CSV.read(file_data, quote_char: "\0", headers: true)

        # only conintue if the # of cols match the # of quesiton codes
        if data.first.length == question_codes.length

          question_codes.each_with_index do |code, code_index|
            code_data = data.map{|x| x[code_index]}

            total = nil
            frequency_data = nil
            formatted_data = nil  

            question = self.questions.with_code(code[0])

            if code_data.present? && question.present?
              # build frequency/stats for question if needed
              if question.data_type == DATA_TYPE_VALUES[:categorical]# build basic frequency info for categorical questions

                question.numerical = nil
                question.descriptive_statistics = nil
                total = 0
                frequency_data = {}
                question.answers.sorted.each {|answer|
                  cnt = code_data.select{|x| x == answer.value }.count
                  total += cnt
                  frequency_data[answer.value] = [cnt, (cnt.to_f/code_data.length*100).round(2)]
                }
 
              elsif question.data_type == DATA_TYPE_VALUES[:numerical] # build numerical descriptive stats for numerical questions
                # flag that is set to false if:
                # - data has no numeric data
                # - there is no repeating values in the data (most likely an ID field)
                #   - computing stats on ID field can take a long time and possibly crash the system 
                #     so lets skip it until the user asks for it
                #   - have found that ID field can have repeating values, so using a 90% threshold
                #     to determine whether or not to compute the numerical info
                #     - if unique data is less than 90% in length from full list -> compute
                has_numeric_data = (code_data.uniq.length / code_data.length.to_f) < 0.9

                if has_numeric_data
                  unique_answer_values = question.answers.unique_values

                  # first have to determine if data is int or float
                  int_data = []
                  float_data = []
                  # get uniq data items and remove ones that are predefined answers
                  unique_data = code_data.uniq - unique_answer_values
                  # if item is int or float, add it to array
                  unique_data.each do |x|
                    if (x =~ /\A[-+]?\d+\z/) != nil # int
                      int_data << x.to_i
                    elsif (x =~ /\A[-+]?\d*\.?\d+\z/) != nil # float
                      float_data << x.to_f
                    end
                  end  

                  # make sure at least some numeric data was found
                  has_numeric_data = int_data.present? || float_data.present?
     
                end

                if has_numeric_data

                  num = Numerical.new
                  
                  # if float_data has any values then it is float
                  # else int
                  num.type = float_data.present? ? Numerical::TYPE_VALUES[:float] : Numerical::TYPE_VALUES[:integer]

                  # get min and max values
                  # - merge the two data arrays and then get min/max
                  #   (if data is float, it still might have int values too)
                  merge_data = int_data + float_data
                  num.min = merge_data.min.to_f
                  num.max = merge_data.max.to_f
                  num.max += 1 if num.min == num.max # if min and max are the same increase max by 1

                  # set bar width
                  # - if the difference between max and min is less than default width, use 1
                  #   else use default width
                  #num.width = (num.max - num.min) > Numerical::NUMERIC_DEFAULT_WIDTH ? Numerical::NUMERIC_DEFAULT_WIDTH : 1
                  range = num.max - num.min
                  num.width = range > Numerical::NUMERIC_DEFAULT_WIDTH ? (range/Numerical::NUMERIC_DEFAULT_WIDTH).ceil : 1                   
                  
                  # set ranges and size
                  num.min_range = (num.min / num.width).floor * num.width
                  num.max_range = (num.max / num.width).ceil * num.width
                  num.size = (num.max_range - num.min_range) / num.width

                  # set teh numerical object
                  question.numerical = num

                  formatted_data = []
                  vfd = [] # only valid formatted data for calculating stats
                  fd = Array.new(num.size, [0,0])

                  #formatted and grouped data calculation
                  code_data.each {|d|
                    if is_numeric?(d) && !unique_answer_values.include?(d)
                      if num.type == Numerical::TYPE_VALUES[:integer]
                        tmpD = d.to_i
                      elsif num.type == Numerical::TYPE_VALUES[:float]
                        tmpD = d.to_f
                      end

                      if tmpD.present? && tmpD >= num.min && tmpD <= num.max
                        formatted_data.push(tmpD);
                        vfd.push(tmpD);

                        index = tmpD == num.min_range ? 0 : ((tmpD-num.min_range)/num.width-0.00001).floor
                        fd[index][0] += 1
                      else 
                        formatted_data.push(nil);
                      end
                    else 
                      formatted_data.push(nil)
                    end

                  }
                  total = 0
                  fd.each {|x| total+=x[0]}
                  fd.each_with_index {|x,i| 
                     fd[i][1] = (x[0].to_f/total*100).round(2) }

                  frequency_data = fd;

                  vfd.extend(DescriptiveStatistics) # descriptive statistics
                  
                  question.descriptive_statistics = {
                    :number => vfd.number.to_i,
                    :min => num.integer? ? vfd.min.to_i : vfd.min,
                    :max => num.integer? ? vfd.max.to_i : vfd.max,
                    :mean => vfd.mean,
                    :median => num.integer? ? vfd.median.to_i : vfd.median,
                    :mode => num.integer? ? vfd.mode.to_i : vfd.mode,
                    :q1 => num.integer? ? vfd.percentile(25).to_i : vfd.percentile(25),
                    :q2 => num.integer? ? vfd.percentile(50).to_i : vfd.percentile(50),
                    :q3 => num.integer? ? vfd.percentile(75).to_i : vfd.percentile(75),
                    :variance => vfd.variance,
                    :standard_deviation => vfd.standard_deviation
                  }
                  # mark the question as being analyzable
                  question.is_analysable = true
                else
                  question.data_type = DATA_TYPE_VALUES[:unknown]
                end
              end

              if question.data_type == DATA_TYPE_VALUES[:unknown]
                question.numerical = nil
                question.descriptive_statistics = nil
              end

              
              data_items = self.data_items.with_code(code[0]) # add the data for this question
              if data_items.present?
                data_items.update_attributes({
                  data: code_data,
                  frequency_data: frequency_data,
                  frequency_data_total: total,
                  formatted_data: formatted_data
                })
              else
                self.data_items_attributes = [{
                                            code: code[0],
                                            original_code: code[1],
                                            data: code_data,
                                            frequency_data: frequency_data,
                                            frequency_data_total: total,
                                            formatted_data: formatted_data }]
              end
            else
              t.msg("[Error] Column #{code_index} (supposed to be #{code}) of #{file_questions} does not exist.")
            end
            
            t.msg("[index, code, data_type] = [#{code_index}, #{code[0]}, #{question.data_type}]")
          end
        else
          t.msg("[ERROR] The number of columns in #{file_data} (#{data.first.length}) does not match the number of question codes #{self.questions.unique_codes.length}")
        end
        t.end("to add #{self.data_items.length} data items");
      end
    else
      t.msg("[WARNING] The required R script file or the data file to process do not exist")      
    end
    t.end("to finish processing the data file")
    return true
  end

private



  #######################
  # run r-script for spss file
  def process_spss(file_to_process, file_r, file_data, file_questions, file_answers)
    begin # run the R script
      result = system 'Rscript', '--default-packages=foreign,MASS', file_r, file_to_process, file_data, file_questions, file_answers
    rescue => e
      puts "!!!!!!!!!!!!!!!! an error occurred - #{e.inspect}"
      result = nil
    end

    puts "Error was #{$?}"

    return result
  end


  #######################
  # run r-script for stata file
  def process_stata(file_to_process, file_r, file_data, file_questions, file_answers)

    begin     # run the R script
      result = system 'Rscript', '--default-packages=foreign,MASS', file_r, file_to_process, file_data, file_questions, file_answers
    rescue => e
      puts "!!!!!!!!!!!!!!!! an error occurred - #{e.inspect}"
      result = nil
    end
    puts "Error was #{$?}"

    if result == true
      # STATA files might use variables to define the answers so the variable answer set can easily be re-used.
      # If this file is using variables, then the answers csv file uses the variable code instead of the question code.
      # Need to create the answers file using the correct question code values.
      #puts "=============================="
      #puts "reading in questions from #{file_questions}"
      questions = CSV.read(file_questions, headers: true)
      answers = CSV.read(file_answers.gsub(/.csv$/, '_temp.csv'), headers: true)

      if questions.present? && answers.present?
        # build correct answer file by going through each question and seeing if it has answers
        # if so, add to array that will be used to write out to file
        # correct format is: Question Code, Answer Value, Answer Text
        # - question format is: question code, question text, data type, variable code
        answers_formatted = []
        questions.each do |question|
          code = question[0]
          code = question[3] if question[3].present?

          matches = answers.select{|x| x[0].downcase == code.downcase}

          if matches.present?
            # found answers for this question
            answers_formatted << matches.map{|match| [question[0], match[1], match[2]] }
          end
        end

        # get rid of the nested arrays
        answers_formatted.flatten!(1)

        # write the re-formatted answers to csv file
        if answers_formatted.present?
          #puts "saving re-formatted answers with correct question code to csv"
          #puts "++ - there were #{answers_formatted.length} total answers recorded"
          # correct format is: Question Code, Answer Value, Answer Text
          CSV.open(file_answers, 'w') do |csv|
            # header
            csv << ['Question Code', 'Answer Value', 'Answer Text']

            answers_formatted.each do |answer|
              csv << answer
            end
          end
        end
      end
    end

    return result
  end


  #######################
  # pull data out of spreadsheet and into new files
  def process_spreadsheet(file_to_process, file_data, file_questions, file_answers)

    result = nil

    data = nil
    case self.file_extension
      when 'csv'
        data = Roo::CSV.new(file_to_process)
      when 'xls'
        data = Roo::Spreadsheet.open(file_to_process)
      when 'xlsx'
        data = Roo::Excelx.new(file_to_process)
      when 'ods'
        data = Roo::OpenOffice.new(file_to_process)
    end

    if !data.nil?
      questions = [] # array of [code, question]
      answers = [] # array of [code, answer value, answer text]
      data_items = []

      # remove \N from data
      # if field is '', replace with nil
      #puts "- cleaning data"
      (1..data.last_row).each do |index|
        data_items << data.row(index).map{|cell| cell == '\\N' ? nil : clean_data_item(cell)}
      end

      # get headers
      headers = data_items.shift

      # get the questions
      #puts "- getting questions"
      headers.each_with_index{|x, i| questions << ["#{@@spreadsheet_question_code}#{i+1}", x]}

      # get the answers
      #puts "- getting answers"
      (0..headers.length-1).each do |index|
        code = questions[index][0]
        # only add answer if it exists and all answers are text (categorical)
        # - if answers are all of same type, sort them, else do not
        items = data_items.map{|x| x[index]}.select{|x| x.present?}.uniq
        items.sort! if items.map{|x| x.class}.uniq.length == 1

        if items.all?{|item| !is_number?(item)}
          items.each do |uniq_answer|
            answers << [code, uniq_answer, uniq_answer]
          end
        end
      end


      # now save the files
      # questions
      #puts "- writing question file"
      CSV.open(file_questions, 'w') do |csv|
        # header
        csv << ['Question Code', 'Question Text']

        questions.each do |row|
          csv << row
        end
      end

      # answers
      #puts "- writing answer file"
      CSV.open(file_answers, 'w') do |csv|
        # header
        csv << ['Question Code', 'Answer Value', 'Answer Text']

        answers.each do |row|
          csv << row
        end
      end

      # data
      #puts "- writing data file"
      CSV.open(file_data, 'w') do |csv|
        data.each do |row|
          csv << row
        end
      end

      result = true

    end

    return result
  end

  def clean_data_item_array(ary)
    if !ary.nil?
      ary.each do |item|
        clean_data_item(item)
      end
    end
    return ary
  end

  def clean_data_item(text)
    if !text.nil?
      x = text.gsub('\\n', ' ').gsub('\\r', ' ').strip
      if x.present?
        return x
      end
    end
    return nil
  end

  # determine if item is number
  def is_number? string
    true if Float(string) rescue false
  end


end

class Timer
   def initialize()  
    # Instance variables  
    @stack = [] 
    #@sep = "==============================\n" 
  end  
  def start(msg)
    @stack.push(Time.now)
    p(msg, false) if msg.present?
  end
  def end(msg)
    if @stack.any?
      p("it took #{Time.now-@stack.pop} seconds #{msg}", true)
    end    
  end
  def msg(msg)
    puts ">  #{"  "*(@stack.length - 1)} " + msg
  end
  def p(msg, is_end)
    puts "> #{"  "*(@stack.length - (is_end ? 0 : 1))} " + msg
  end
end