# encoding: utf-8
module ProcessDataFile
  require 'csv'

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
        are_question_codes_categorical = []
        are_question_codes_numerical = []
        if File.exists?(file_questions)
          line_number = 0
          CSV.foreach(file_questions, headers: true).each_with_index do |row, i|
            # row format: question code, question text, 
            line_number += 1

            # record the question code even if it is missing text
            # - need this for when pulling in data in the next section
            if row[0].present? && row[0].strip.present?
              question_codes << row[0].strip
              are_question_codes_categorical << false
              are_question_codes_numerical << false
            end

            # only add if the code is present
            if row[0].present? && row[0].strip.present?
              # determine the data type
              # - we only know the data type here if data file is not spreadsheet and data type column (col 2) exists
              data_type = Question::DATA_TYPE_VALUES[:unknown]
              if !is_spreadsheet && row.length > 2 && row[2].present?
                case row[2].downcase
                  when 'c'
                    data_type = Question::DATA_TYPE_VALUES[:categorical]
                    are_question_codes_categorical[question_codes.index(row[0])] = true
                  when 'n'
                    data_type = Question::DATA_TYPE_VALUES[:numerical]
                    are_question_codes_numerical[question_codes.index(row[0])] = true
                end

              end
              # mongo does not allow '.' in key names, so replace with '|'
              self.questions_attributes = [{code: clean_text(row[0], format_code: true),
                                            original_code: clean_text(row[0]),
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
                  question.data_type = Question::DATA_TYPE_VALUES[:categorical]
                  are_question_codes_categorical[question_codes.index(row[0])] = true
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
            clean_code = clean_text(code, format_code: true)
            code_data = data.map{|x| x[code_index]}
            total = 0
            frequency_data = {}
            question = self.questions.with_code(clean_code)
            if code_data.present? && question.present?
              # build frequency/stats for question if needed
              if are_question_codes_categorical[code_index] # build basic frequency info for categorical questions
                question.answers.sorted.each {|answer|
                  cnt = code_data.select{|x| x == answer.value }.count
                  total += cnt
                  frequency_data[answer.value] = [cnt, (cnt.to_f/code_data.length*100).round(2)]
                }
                question.has_data_without_answers = total < code_data.select{|d| !d.nil? }.length 

              elsif are_question_codes_numerical[code_index] # build numerical descriptive stats if numerical
#### TODO                


                question.has_data_without_answers = code_data.select{|d| !d.nil? }.length > 0 
              else
                question.has_data_without_answers = code_data.select{|d| !d.nil? }.length > 0 
              end

              # add the data for this question
              self.data_items_attributes = [{code: clean_code,
                                            original_code: clean_text(code),
                                            data: code_data
                                          }.merge(frequency_data.present? ? { frequency_data: frequency_data, frequency_data_total: total } : {})]

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

private



  #######################
  # run r-script for spss file
  def process_spss(file_to_process, file_r, file_data, file_questions, file_answers)
    puts "=============================="
    puts "$$$$$$ process_spss"
    puts "=============================="
    start = Time.now
    # run the R script
    begin
      result = system 'Rscript', '--default-packages=foreign,MASS', file_r, file_to_process, file_data, file_questions, file_answers
    rescue => e
      puts "!!!!!!!!!!!!!!!! an error occurred - #{e.inspect}"
      result = nil
    end

    puts "Error was #{$?}"

    puts ">>>>>>> it took #{Time.now-start} seconds to process the spss file"

    return result
  end


  #######################
  # run r-script for stata file
  def process_stata(file_to_process, file_r, file_data, file_questions, file_answers)
    puts "=============================="
    puts "$$$$$$ process_stata"
    puts "=============================="
    start = Time.now
    # run the R script
    begin
      result = system 'Rscript', '--default-packages=foreign,MASS', file_r, file_to_process, file_data, file_questions, file_answers
    rescue => e
      puts "!!!!!!!!!!!!!!!! an error occurred - #{e.inspect}"
      result = nil
    end
    puts ">>>>>>> it took #{Time.now-start} seconds to process the stata file"

    puts "Error was #{$?}"

    if result == true
      # STATA files might use variables to define the answers so the variable answer set can easily be re-used.
      # If this file is using variables, then the answers csv file uses the variable code instead of the question code.
      # Need to create the answers file using the correct question code values.
      puts "=============================="
      puts "reading in questions from #{file_questions}"
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
          puts "saving re-formatted answers with correct question code to csv"
          puts "++ - there were #{answers_formatted.length} total answers recorded"
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
    puts "=============================="
    puts "$$$$$$ process_spreadsheet"
    puts "=============================="
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
      puts "- cleaning data"
      (1..data.last_row).each do |index|
        data_items << data.row(index).map{|cell| cell == '\\N' ? nil : clean_data_item(cell)}
      end

      # get headers
      headers = data_items.shift

      # get the questions
      puts "- getting questions"
      headers.each_with_index{|x, i| questions << ["#{@@spreadsheet_question_code}#{i+1}", x]}

      # get the answers
      puts "- getting answers"
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
      puts "- writing question file"
      CSV.open(file_questions, 'w') do |csv|
        # header
        csv << ['Question Code', 'Question Text']

        questions.each do |row|
          csv << row
        end
      end

      # answers
      puts "- writing answer file"
      CSV.open(file_answers, 'w') do |csv|
        # header
        csv << ['Question Code', 'Answer Value', 'Answer Text']

        answers.each do |row|
          csv << row
        end
      end

      # data
      puts "- writing data file"
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
