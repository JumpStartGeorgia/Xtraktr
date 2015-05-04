# encoding: utf-8
module ExportData
  require 'csv'

  #########################################
  #########################################
  # create codebook file
  # format: 
  # question code - question
  # answers:
  #   value - text
  def self.codebook
    start = Time.now

    output = ''
    d = Dataset.first
    questions = d.questions.for_analysis
    puts "- there are #{questions.length} questions"
    filename = clean_filename(d.title)
    text_file = "#{Rails.root}/tmp/#{filename}_CODEBOOK.txt"

    # add title
    output << d.title
    output << "\n"
    output << "Codebook Generated On: #{I18n.l(start, format: :file)}"
    output << "\n\n"

    # add each question/answer
    questions.each do |question|
      output << "--------------"
      output << "\n"
      output << "#{question.original_code} - #{clean_text(question.text)}"
      output << "\n"
      if question.notes.present?
        output << "Notes: #{question.notes}"        
        output << "\n"
      end
      output << "Answers:"
      output << "\n"
      question.answers.all_for_analysis.each do |answer|
        output << "  #{answer.value} - #{clean_text(answer.text)}"
        output << "\n"
      end
      output << "\n"
    end

    #######################
    # create text file
    puts "- creating text file"
    File.open(text_file, 'w') {|f| f.write(output) }


    puts "-- it took #{(Time.now-start).round(3)} seconds to create the codebook file"
    return nil  
  end


  #########################################
  #########################################
  # create csv file
  def self.csv
    start = Time.now

    output = ''
    d = Dataset.first
    questions = d.questions.for_analysis
    puts "- there are #{questions.length} questions"
    filename = clean_filename(d.title)
    csv_file = "#{Rails.root}/tmp/#{filename}.csv"
    
    #######################
    # create csv file
    puts "- creating csv file"
    File.open(csv_file, 'w') {|f| f.write(build_csv(d, questions, with_raw_data: false, with_header: true)) }

    puts "-- it took #{(Time.now-start).round(3)} seconds to create the csv file"
    return nil  
  end



  #########################################
  #########################################
  # create spss file
  # notes 
  # - strings cannot be more than 60 chars
  def self.spss
    start = Time.now

    output = ''
    d = Dataset.first
    questions = d.questions.for_analysis
    puts "- there are #{questions.length} questions"
    filename = clean_filename(d.title)
    csv_filename = "#{filename}_SPSS.csv"
    spss_file = "#{Rails.root}/tmp/#{filename}.sps"
    csv_file = "#{Rails.root}/tmp/#{csv_filename}"
    

    #######################
    ## create spss file
    puts "- writing to file: #{spss_file}"

    # add title
    output << "TITLE \"#{shorten_text(d.title)}\".\n\n"

    # add data list file line
    output << '* IMPORTANT: you must update the path to the file to include the full path (e.g., C:\Desktop\...).'
    output << "\n"
    output << "DATA LIST FILE= \"#{csv_filename}\"  free (\",\")\n"


    # add question codes
    output << '/ '
    questions.each do |question|
      output << question.original_code
      output << ' '
    end
    output << " . \n\n"

    # add variable labels (question code/text)
    output << "VARIABLE LABELS \n"
    questions.each do |question|
      output << question.original_code
      output << ' "'
      output << shorten_text(clean_text(question.text))
      # output << question.original_code
      output << "\" \n"
    end
    output << " . \n\n"


    # add value labels (answer)
    output << "VALUE LABELS \n"
    questions.each do |question|
      output << "/ \n"
      output << question.original_code
      output << " \n"
      question.answers.all_for_analysis.each do |answer|
        output << ' ' # not needed - just to make it easier to read
        output << answer.value
        output << ' "'
        output << shorten_text(clean_text(answer.text))
        output << "\" \n"
      end
    end
    output << " . \n\n"


    # finish the file
    output << 'EXECUTE.'

    # write out spss file
    File.open(spss_file, 'w') {|f| f.write(output) }


    #######################
    # create csv file
    puts "- creating csv file"
    File.open(csv_file, 'w') {|f| f.write(build_csv(d, questions)) }

    puts "-- it took #{(Time.now-start).round(3)} seconds to create the spss and csv files"
    return nil
  end


  #########################################
  #########################################
  # create stata file
  # notes:
  # if provide the automatic flag, stata will automatically create the variable values
  # you tell stata that the variable has unique values by add ':name_fmt' after question code
  # create labels:
      # label define sexfmt 0 "Male" 1 "Female"
      # infile str16 name sex:sexfmt age using persons        
  def self.stata
    start = Time.now

    output = ''
    d = Dataset.first
    questions = d.questions.for_analysis
    puts "- there are #{questions.length} questions"
    filename = clean_filename(d.title)
    csv_filename = "#{filename}_STATA.csv"
    stata_file = "#{Rails.root}/tmp/#{filename}.do"
    csv_file = "#{Rails.root}/tmp/#{csv_filename}"

    #######################
    # create stata file
    output << '* IMPORTANT: you must update the path to the file at the end of the next line to include the full path (e.g., C:\Desktop\...)'
    output << "\n\n"
    output << 'infile '
    questions.each do |question|
      output << question.original_code
      if question.has_code_answers
        output << ":#{question.original_code}_fmt"
      end
      output << ' '
    end
    output << " using  #{csv_filename} , automatic "

    # write out spss file
    File.open(stata_file, 'w') {|f| f.write(output) }


    #######################
    # create csv file
    puts "- creating csv file"
    File.open(csv_file, 'w') {|f| f.write(build_csv(d, questions, with_raw_data: false)) }


    puts "-- it took #{(Time.now-start).round(3)} seconds to create the stata and csv files"
    return nil
  end



private

  def self.clean_filename(text)
    if !text.nil?
      return text.strip.latinize.to_ascii.gsub(' ', '_').gsub(/[\\ \/ \: \* \? \" \< \> \| \, \. ]/,'')[0..50]
    end
    return text
  end

  def self.clean_text(text)

    if !text.nil?
      x = text.gsub('\\n', ' ').gsub('\\r', ' ').strip 
      if x.present?
        return x
      end
    end
    return nil
  end

  def self.shorten_text(text)
    if text.length > 50
      return text[0..50]
    end
    return text
  end

  def self.build_csv(dataset, questions, options={})
    with_raw_data = options[:with_raw_data].nil? ? true : options[:with_raw_data]
    with_header = options[:with_header].nil? ? false : options[:with_header]

    data = []
    header = []
    csv = nil

    if dataset.present? && questions.present?
      questions.each do |question|
        header << "#{question.original_code} - #{question.text}"

        if with_raw_data
          # use the data values
          data << dataset.data_items.code_data(question.code)
        else
          # replace the data values with the answer text

          # get original data
          question_data = dataset.data_items.code_data(question.code)

          # now replace data values with answer text
          question.answers.all_for_analysis.each do |answer|
            question_data.select{ |x| x == answer.value }.each{ |x| x.replace( answer.text ) }
          end

          data << question_data
        end
      end

      # now use transpose to get in proper format
      csv = CSV.generate do |csv_row|
        if with_header
          csv_row << header
        end

        data.transpose.each do |row|
          csv_row << row.map{|x| 
            y = x.nil? || x.empty? ? nil : clean_text(x)
            y.present? ? y : nil
          }
        end
      end
    end

    return csv
  end

end