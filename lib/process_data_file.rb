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
  @@file_answers_complete = 'answers_complete.csv'
  @@file_answers_incomplete = 'answers_incomplete.csv'
  @@r_file = {
    'sav' => 'spss_to_csv.r',
    'dta' => 'stata_to_csv.r'
  }
  @@spreadsheet_question_code = 'VAR'


  #######################
  # process a data file
  def process_data_file
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
    file_sps = path + "spss_code.sps"
    file_data = path + @@file_data
    file_questions = path + @@file_questions
    file_answers_complete = path + @@file_answers_complete
    file_answers_incomplete = path + @@file_answers_incomplete

    # make sure files exists
    if (is_spreadsheet || (!is_spreadsheet && File.exists?(file_r))) && File.exists?(file_to_process)

      # create dataset directory if not exist
      FileUtils.mkdir_p(File.dirname(file_data))

      # process the file and populate the data, questions and answers csv spreadsheet files
      results = nil
      case self.file_extension
        when 'sav'
          results = process_spss(file_to_process, file_r, file_sps, file_data, file_questions, file_answers_complete)
        when 'dta'
          results = process_stata(file_to_process, file_r, file_sps, file_data, file_questions, file_answers_complete)
        when 'csv', 'xls', 'xlsx', 'ods'
          results = process_spreadsheet(file_to_process, file_data, file_questions, file_answers_complete)
      end

      if results.nil? || results == false
        puts "Error was #{$?}"
        errors.add(:datafile, "bad datafile!")
        return false
      elsif results
        puts "You made it!"

        puts "=============================="
        puts "reading in questions from #{file_questions} and saving to questions attribute"
        question_codes = [] # record the question codes from the questions file
        if File.exists?(file_questions)
          line_number = 0
          CSV.foreach(file_questions).each_with_index do |row, i|
            line_number += 1

            # record the question code even if it is missing text
            # - need this for when pulling in data in the next section
            if row[0].present? && row[0].strip.present?
              question_codes << row[0].strip
            end

            # only add if the code is presetn ## and text are present
            if row[0].present? && row[0].strip.present?# && row[1].present? && row[1].strip.present?
              # mongo does not allow '.' in key names, so replace with '|'
              self.questions_attributes = [{code: clean_text(row[0], format_code: true),
                                            original_code: clean_text(row[0]),
                                            text_translations: {self.default_language => clean_text(row[1])},
                                            sort_order: i+1
                                          }]
            # else
            #   # if there is question code but no question text, save this
            #   if row[0].present? && row[0].strip.present? && !(row[1].present? && row[1].strip.present?)
            #     self.questions_with_no_text = [] if self.questions_with_no_text.nil?
            #     self.questions_with_no_text << clean_text(row[0])
            #   end
            #   puts "******************************"
            #   puts "Line #{line_number} of #{file_questions} is missing the code or text."
            #   puts "******************************"
            end
          end
        end
        puts " - added #{self.questions.length} questions"



        puts "=============================="
        puts "saving data from #{file_data} and saving to data_items attribute"
        # if this is a spreadsheet do not use the quote char setting
        if is_spreadsheet
          data = CSV.read(file_data)
        else
          data = CSV.read(file_data, :quote_char => "\0")
        end
        # only conintue if the # of cols match the # of quesiton codes
        # - have to subtract 1 from cols because csv file has ',' after last item
        if (is_spreadsheet && data.first.length == question_codes.length) || (!is_spreadsheet && data.first.length-1 == question_codes.length)
          question_codes.each_with_index do |code, code_index|
            code_data = data.map{|x| x[code_index]}
            if code_data.present?
              self.data_items_attributes = [{code: clean_text(code, format_code: true),
                                            original_code: clean_text(code),
                                            data: clean_data_item(code_data)
                                          }]
            else
              puts "******************************"
              puts "Column #{code_index} (supposed to be #{code}) of #{file_questions} does not exist."
              puts "******************************"
            end
          end
        else
          puts "******************************"
          puts "ERROR"
          puts "The number of columns in #{file_data} (#{data.first.length} does not match the number of question codes #{self.questions.unique_codes.length}"
          puts "******************************"
        end
        puts "added #{self.data_items.length} columns worth of data"

=begin
        # before can read in data, we have to add a header row to it
        # so the SmaterCSV library that reads in the csv has the correct keys for the values
        puts "=============================="
        puts "adding header to data csv"
        # read in data file and create new file with header
        # - need to use the quote char of \0 (null)
        #   - R does not put data in quotes so any quotes in file cause illegal quote error
        data = CSV.read(file_data, :quote_char => "\0")
        CSV.open(file_data, 'w', write_headers: true, headers: self.questions.unique_codes) do |csv|
          data.each do |row|
            csv << row
          end
        end


        puts "=============================="
        puts "reading in data from #{file_data} and saving to data attribute"
        if File.exists?(file_data)
          self.data = SmarterCSV.process(file_data, {downcase_header: false, strings_as_keys: true})        end
        puts "added #{self.data.length} records"

=end

        puts "=============================="
        puts "reading in answers from #{file_answers_complete} and converting to csv"
        # format for non-spreadsheet data files for each line is: [1] "Question Code || Answer Value || Answer Text"
        # spreadsheet data files are already in proper format
        answers_complete = []
        if File.exists?(file_answers_complete)
          line_number = 0
          if is_spreadsheet
            last_key = nil
            sort_order = 0
            CSV.foreach(file_answers_complete) do |row|
              line_number += 1
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
                  # - if this is the first answer for this question, initialize the array
                  question.answers_attributes  = [{value: clean_text(row[1]),
                                                  text_translations: { self.default_language => clean_text(row[2]) },
                                                  sort_order: sort_order
                                                }]
                  # update question to indciate it has answers
                  question.has_code_answers = true
                  question.has_code_answers_for_analysis = true
                  # include question in public download
                  # question.can_download = true
                else
                  puts "******************************"
                  puts "Line #{line_number} of #{file_answers_complete} has a question code #{key} that could not be found in the list of questions."
                  puts "******************************"
                end
              end
            end
          else
            File.open(file_answers_complete, "r") do |f|
              last_key = nil
              sort_order = 0
              f.each_line do |line|
                line_number += 1
                # take out the [1] " at the beginning and the closing "
                answer = clean_text(line).gsub('[1] "', '').gsub(/\"$/, '')
                values = answer.split(' || ')
                if values.length == 3
                  # save for writing to csv
                  answers_complete << [clean_text(values[0]), clean_text(values[1]), clean_text(values[2])]

                  # add the answer to the appropriate question
                  # save to answers attribute
                  key = clean_text(values[0], format_code: true)
                  question = self.questions.with_code(key)
                  if question.present?
                    # if this is a new key (question code), reset sort variables
                    if last_key != key
                      last_key = key.dup
                      sort_order = 0
                    end
                    # create sort order that is based on order they are listed in data file
                    sort_order += 1
                    # - if this is the first answer for this question, initialize the array
                    question.answers_attributes  = [{value: clean_text(values[1]),
                                                    text_translations: { self.default_language => clean_text(values[2]) },
                                                    sort_order: sort_order
                                                  }]
                    # update question to indciate it has answers
                    question.has_code_answers = true
                    question.has_code_answers_for_analysis = true
                    # include question in public download
                    # question.can_download = true
                  else
                    puts "******************************"
                    puts "Line #{line_number} of #{file_answers_complete} has a question code #{key} that could not be found in the list of questions."
                    puts "******************************"
                  end
                else
                  puts "******************************"
                  puts "ERROR"
                  puts "An error occurred on line #{line_number} of #{file_answers_complete} while parsing the answers."
                  puts "This line was not in the correct format of: [1] \"Question Code || Answer Value || Answer Text\""
                  puts "******************************"
                  break
                end
              end
            end
          end
        end

        if !is_spreadsheet
          # if answers exists, write to csv file
          if answers_complete.length > 0
            puts "saving complete answers to csv"
            puts "++ - there were #{answers_complete.length} total answers recorded for #{answers_complete.map{|x| x[0]}.uniq.length} questions"
            CSV.open(file_answers_complete, 'w') do |csv|
              answers_complete.each do |answer|
                csv << answer
              end
            end
          end


          puts "=============================="
          puts "reading in incomplete answers from sps file #{file_sps}"
          # open the sps file and convert the list of answers into a csv file
          # row format: question_code, answer code, answer text
          answers_incomplete = []
          found_labels = false
          next_line_question = false
          question_code = nil
          line_number = 0
          File.open(file_sps, "r") do |f|
            f.each_line do |line|
              line_number += 1
        #      puts "++ line #{line_number}"
              if found_labels
                if clean_text(line) == '.'
        #          puts "++ - found '.', stopping parsing of answers"
                  # this is the end of the list of answers so stop
                  break
                elsif clean_text(line) == '/'
        #          puts "++ - found /"
                  # this is the end of a set of answers for a question
                  question_code = nil
                  next_line_question = true
                else
                  # if this line is a question, start a new row array and save the question
                  # else this is an answer
                  if next_line_question
        #            puts "++ - found question: #{line}"
                    next_line_question = false
                    question_code = clean_text(line)
                  else
                    # this is an answer, record row in format: [question_code, value, text]
                    # line is in format of: value "text"

                    # strip space at beginning and end of line
                    answer = clean_text(line)
                    # get index of space between value and text
                    # index will be used to pull out the answer code and answer text
        #            puts "++ -- found answer: #{line}"

                    index = answer.index(' "')
                    if index.nil?
                      puts "******************************"
                      puts "ERROR"
                      puts "An error occurred on line #{line_number} of #{file_sps} while parsing the answers."
                      puts "This line was not in the correct format of: value 'answer text'"
                      puts "******************************"
                      break
                    else
                      answers_incomplete << [question_code, answer[0..index-1], answer[index+2..-2]]
                    end

                  end
                end
              elsif clean_text(line) == 'VALUE LABELS'
                # found beginning of list of answers
        #        puts "++++++++++++++ found value labels on line #{line_number}"
                found_labels = true
              end
            end
          end

          puts "=============================="

          # if answers exists, write to csv file
          if answers_incomplete.length > 0
            puts "saving incomplete answers to csv"
            puts "++ - there were #{answers_incomplete.length} total answers recorded for #{answers_incomplete.map{|x| x[0]}.uniq.length} questions"
            CSV.open(file_answers_incomplete, 'w') do |csv|
              answers_incomplete.each do |answer|
                csv << answer
              end
            end
          end

          puts "=============================="
          # if complete answers length != bad answers length, show error message
          # this will happen if the data contains values that are not in the defined list of answers
          if answers_complete.length != answers_incomplete.length
            complete_questions = answers_complete.map{|x| x[0]}.uniq
            incomplete_questions = answers_incomplete.map{|x| x[0]}.uniq
            # record question codes to questions_with_bad_answers attribute
            self.questions_with_bad_answers = complete_questions - incomplete_questions
            puts "******************************"
            puts "WARNING"
            puts "When parsing your file, we found that there are #{complete_questions.length - incomplete_questions.length} questions "
            puts "that contain values that are not listed as one of the possible answers."
            puts "We suggest you review the values for these questions and fix accordingly."
  #          puts "Here are the questions that had this issue:"
  #          puts (complete_questions - incomplete_questions).map{|x| "#{x}\n"}
            puts "******************************"
          end
        end
      end
    else
      puts "******************************"
      puts "WARNING"
      puts "The required R script file or the data file to process do not exist"
      puts "******************************"
    end

    return true
  end

private



  #######################
  # run r-script for spss file
  def process_spss(file_to_process, file_r, file_sps, file_data, file_questions, file_answers_complete)
    puts "=============================="
    puts "$$$$$$ process_spss"
    puts "=============================="
    # run the R script
    result = system 'Rscript', '--default-packages=foreign,MASS', file_r, file_to_process, file_data, file_sps, file_questions, file_answers_complete

    return result
  end


  #######################
  # run r-script for stata file
  def process_stata(file_to_process, file_r, file_sps, file_data, file_questions, file_answers_complete)
    puts "=============================="
    puts "$$$$$$ process_stata"
    puts "=============================="
    # run the R script
    begin
      result = system 'Rscript', '--default-packages=foreign,MASS', file_r, file_to_process, file_data, file_sps, file_questions, file_answers_complete
    rescue => e
      puts "!!!!!!!!!!!!!!!! an error occurred - #{e.inspect}"
      result = nil
    end

    puts "Error was #{$?}"

    puts "@@@@@@@ result = #{result}"

    if result == true
      # the questions need to be put into a csv format like is returned from spss so can use the common processing code above

      puts "=============================="
      puts "reading in questions from #{file_questions} and converting to csv"
      # format of each line of file is: [1] "Question Code || Question Text || Variable Code"
      questions_formatted = []
      has_var_questions = false
      if File.exists?(file_questions)
        line_number = 0
        File.open(file_questions, "r") do |f|
          f.each_line do |line|
            # take out the [1] " at the beginning and the closing "
            question = clean_text(line).gsub('[1] "', '').gsub(/\"$/, '')
            values = question.split(' || ')
            if values.length.between?(1,3)
              # record that there are variables being used in this dataset
              has_var_questions = true if values.length == 3 && has_var_questions == false

              # save for writing to csv
              questions_formatted << [clean_text(values[0]), values[1].present? ? clean_text(values[1]) : nil, values[2].present? ? clean_text(values[2]) : nil]
            else
              puts "******************************"
              puts "ERROR"
              puts "An error occurred on line #{line_number} of #{file_questions} while parsing the questions."
              puts "This line was not in the correct format of: [1] \"Question Code || Question Text\""
              puts "******************************"
              break
            end
          end
        end
      end

      # write the re-formatted questions to csv file
      if questions_formatted.present?
        puts "saving re-formatted questions to csv"
        puts "++ - there were #{questions_formatted.length} total questions recorded"
        CSV.open(file_questions, 'w') do |csv|
          questions_formatted.each do |question|
            csv << question
          end
        end
      end

      puts "=============================="
      # STATA files might use variables to define the answers so the variable answer set can easily be re-used
      # if this file is using variables, then create the answers file using the correct code values
      # if not, make a copy of the answer file with the proper name
      temp_file = file_answers_complete.gsub(/.csv$/, '_temp.csv')

      if has_var_questions
        puts "--- the file IS using variables for the answers so NEED to re-process the answer file"

        puts "reading in answers with variables from #{temp_file} and re-creating using correct question codes"
        # format of each line of file is: [1] "Variable Code || Answer Value || Answer Text"
        # need format to be: [1] "Question Code || Answer Value || Answer Text"
        temp_answers_formatted = []
        if File.exists?(temp_file)
          line_number = 0
          File.open(temp_file, "r") do |f|
            f.each_line do |line|
              # take out the [1] " at the beginning and the closing "
              answer = clean_text(line).gsub('[1] "', '').gsub(/\"$/, '')
              values = answer.split(' || ')
              if values.length == 3
                temp_answers_formatted << [clean_text(values[0]), clean_text(values[1]), clean_text(values[2])]
              else
                puts "******************************"
                puts "ERROR"
                puts "An error occurred on line #{line_number} of #{temp_file} while parsing the questions."
                puts "This line was not in the correct format of: [1] \"Question Code || Answer Value || Answer Text\""
                puts "******************************"
                break
              end
            end
          end
        end

        if temp_answers_formatted.present?
          # now have answers
          # build correct answer file by going through each question and seeing if it has answers
          # if so, add to array that will be used to write out to file
          # correct format is: [1] "Question Code || Answer Value || Answer Text"
          # - this format is needed so common processing code above will read it and process it properly
          answers_formatted = []
          questions_formatted.each do |question|
            code = question[0]
            code = question[2] if question[2].present?

            matches = temp_answers_formatted.select{|x| x[0].downcase == code.downcase}

            if matches.present?
              # found answers for this question
              answers_formatted << matches.map{|match| "#{question[0]} || #{match[1]} || #{match[2]}"}
            end
          end

          # get rid of the nested arrays
          answers_formatted.flatten!

          # write the re-formatted answers to csv file
          if answers_formatted.present?
            puts "saving re-formatted answers with correct question code to csv"
            puts "++ - there were #{answers_formatted.length} total answers recorded"
            # correct format is: [1] "Question Code || Answer Value || Answer Text"
            File.open(file_answers_complete, 'w') do |f|
              answers_formatted.each do |answer|
                f << %Q{[1] "#{answer}"}
                f << "\n"
              end
            end
          end
        end
      else
        puts "--- the file is not using variables for the answers so no need to re-process the answer file"
        # just make a copy of the file using the correct name
        #FileUtils.cp temp_file file_answers_complete
      end

    end

    return result
  end


  #######################
  # pull data out of spreadsheet and into new files
  def process_spreadsheet(file_to_process, file_data, file_questions, file_answers_complete)
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
        # only add answer if it exists
        # - if answers are all of same type, sort them, else do not
        items = data_items.map{|x| x[index]}.select{|x| x.present?}.uniq
        items.sort! if items.map{|x| x.class}.uniq.length == 1
        items.each do |uniq_answer|
          answers << [code, uniq_answer, uniq_answer]
        end
      end


      # now save the files
      # questions
      puts "- writing question file"
      CSV.open(file_questions, 'w') do |csv|
        questions.each do |row|
          csv << row
        end
      end

      # answers
      puts "- writing answer file"
      CSV.open(file_answers_complete, 'w') do |csv|
        answers.each do |row|
          csv << row
        end
      end

      # data
      puts "- writing data file"
      CSV.open(file_data, 'w') do |csv|
        (2..data.last_row).each do |index|
          csv << data.row(index)
        end
      end

      result = true

    end

    return result
  end

  def self.clean_data_item(text)
    if !text.nil?
      x = text.gsub('\\n', ' ').gsub('\\r', ' ').strip
      if x.present?
        return x
      end
    end
    return nil
  end

  #### OLD

  # #######################
  # # pull data out of csv and into new files
  # def process_csv(file_to_process, file_data, file_questions, file_answers_complete)
  #   puts "=============================="
  #   puts "$$$$$$ process_csv"
  #   puts "=============================="
  #   result = nil

  #   data = CSV.read(File.open(file_to_process))
  #   if data.present?
  #     # get headers and remove from csv data
  #     headers = data.shift
  #     questions = [] # array of [code, question]
  #     answers = [] # array of [code, answer value, answer text]

  #     # clean up data and remove \N
  #     data.select{|row| row.select{|cell| cell.include?('\N')}.each{|x| x.replace('')}}

  #     # get the questions
  #     headers.each_with_index{|x, i| questions << ["#{@@spreadsheet_question_code}#{i+1}", x]}
  #     # get the answers
  #     (0..headers.length-1).each do |index|
  #       code = questions[index][0]
  #       data.map{|x| x[index]}.uniq.sort.each do |uniq_answer|
  #         # only add answer if it exists
  #         if uniq_answer.strip.present?
  #           answers << [code, uniq_answer, uniq_answer]
  #         end
  #       end
  #     end

  #     # now save the files
  #     # questions
  #     CSV.open(file_questions, 'w') do |csv|
  #       questions.each do |row|
  #         csv << row
  #       end
  #     end

  #     # answers
  #     CSV.open(file_answers_complete, 'w') do |csv|
  #       answers.each do |row|
  #         csv << row
  #       end
  #     end

  #     # data
  #     CSV.open(file_data, 'w') do |csv|
  #       data.each do |row|
  #         csv << row
  #       end
  #     end

  #     result = true
  #   end
  #   return result
  # end

end
