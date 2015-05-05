# encoding: utf-8
module ExportData
  require 'csv'
  require 'zipruby'

  # create a zip file of the request type
  # if type is not codebook, include coodebook in zip
  # update dataset with path to the file
  # type = codebook, csv, spss, stata, r
  def self.create_file(dataset, type)

    # make sure path exists
    FileUtils.mkpath("#{Rails.public_path}#{dataset.data_download_staging_path}")    

    # set path to codebook here since used in all methods
    @codebook_file = 'codebook.txt'
    @codebook_file_path = "#{Rails.public_path}#{dataset.data_download_staging_path}/#{@codebook_file}"

    # set readme file name to appear in zip file
    @zip_file = 'README.txt'

    # all options require codebook, so create it
    codebook(dataset)

    # generate the requested files
    case type
      when 'csv'
        csv(dataset)
      when 'spss'
        spss(dataset)
      when 'stata'
        stata(dataset)
      when 'r'
        r(dataset)
    end

  end


  # create all files for a dataset that do not exist yet
  def self.create_all_files(dataset)
    start = Time.now

    # make sure path exists
    FileUtils.mkpath("#{Rails.public_path}#{dataset.data_download_staging_path}")    

    # set path to codebook here since used in all methods
    @codebook_file = 'codebook.txt'
    @codebook_file_path = "#{Rails.public_path}#{dataset.data_download_staging_path}/#{@codebook_file}"

    codebook(dataset)
    csv(dataset)
    spss(dataset)
    stata(dataset)
    r(dataset)

    puts "@@@@@ it took #{(Time.now-start).round(3)} seconds to create all files for dataset"
  end


  # make sure all datasets have data files
  def self.create_all_dataset_files
    start = Time.now
    
    Dataset.all.each do |dataset|
      puts ">>> dataset: #{dataset.title}"
      # make sure dataset has url object
      dataset.create_urls_object
      # create the data files for this dataset
      create_all_files(dataset)
    end

    puts ">>>>>>>> it took #{(Time.now-start).round(3)} seconds to create all files for all datasets"
  end

private


  #########################################
  #########################################
  # create codebook file
  # format: 
  # question code - question
  # answers:
  #   value - text
  def self.codebook(dataset)
    puts '>> creating codebok'
    start = Time.now

    output = ''
    questions = dataset.questions.for_analysis

    filename = clean_filename(dataset.title)
    zip_name = "codebook.zip"
    zip_file_path = "#{Rails.public_path}#{dataset.data_download_path}/#{zip_name}"
    readme_name = "readme_codebook.txt"
    readme_file_path = "#{Rails.public_path}#{dataset.data_download_staging_path}/#{readme_name}"

    if !File.exists?(@codebook_file_path)
      # add title
      output << dataset.title
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
      # create codebook file
      puts "- creating codebook file"
      File.open(@codebook_file_path, 'w') {|f| f.write(output) }
    end

    # create the readme
    create_readme(readme_file_path, 'codebook', dataset)

    # create the zip file
    create_zip(dataset.title, zip_file_path, [
        {file_name: @zip_file, file_path: readme_file_path},
        {file_name: @codebook_file, file_path: @codebook_file_path}
      ]
    )

    # record the path to the file in the dataset
    dataset.urls.codebook = "#{dataset.data_download_path}/#{zip_name}"
    dataset.save

    puts "-- it took #{(Time.now-start).round(3)} seconds to create the codebook file"
    return nil  
  end


  #########################################
  #########################################
  # create csv file
  def self.csv(dataset)
    puts '>> creating csv'
    start = Time.now

    output = ''
    questions = dataset.questions.for_analysis

    filename = clean_filename(dataset.title)
    csv_file = "csv.csv"
    csv_file_path = "#{Rails.public_path}#{dataset.data_download_staging_path}/#{csv_file}"
    zip_name = "csv.zip"
    zip_file_path = "#{Rails.public_path}#{dataset.data_download_path}/#{zip_name}"
    readme_name = "readme_csv.txt"
    readme_file_path = "#{Rails.public_path}#{dataset.data_download_staging_path}/#{readme_name}"
    
    if !File.exists?(csv_file_path)
      #######################
      # create csv file
      puts "- creating csv file"
      File.open(csv_file_path, 'w') {|f| f.write(build_csv(dataset, questions, with_raw_data: false, with_header: true)) }
    end

    # create the readme
    create_readme(readme_file_path, 'csv', dataset)

    # create the zip file
    create_zip(dataset.title, zip_file_path, [
        {file_name: @zip_file, file_path: readme_file_path},
        {file_name: @codebook_file, file_path: @codebook_file_path},
        {file_name: csv_file, file_path: csv_file_path}
      ]
    )

    # record the path to the file in the dataset
    dataset.urls.csv = "#{dataset.data_download_path}/#{zip_name}"
    dataset.save

    puts "-- it took #{(Time.now-start).round(3)} seconds to create the csv file"
    return nil  
  end



  #########################################
  #########################################
  # create spss file
  # notes 
  # - strings cannot be more than 60 chars
  def self.spss(dataset)
    puts '>> creating spss'
    start = Time.now

    output = ''
    questions = dataset.questions.for_analysis

    filename = clean_filename(dataset.title)
    csv_file = "spss.csv"
    spss_file = 'spss.sps'
    spss_file_path = "#{Rails.public_path}#{dataset.data_download_staging_path}/#{spss_file}"
    csv_file_path = "#{Rails.public_path}#{dataset.data_download_staging_path}/#{csv_file}"
    zip_name = "spss.zip"
    zip_file_path = "#{Rails.public_path}#{dataset.data_download_path}/#{zip_name}"
    readme_name = "readme_spss.txt"
    readme_file_path = "#{Rails.public_path}#{dataset.data_download_staging_path}/#{readme_name}"
    

    if !File.exists?(spss_file_path)
      #######################
      ## create spss file
      puts "- creating spss file"

      # add title
      output << "TITLE \"#{shorten_text(dataset.title)}\".\n\n"

      # add data list file line
      output << "***********************************"
      output << "\n"
      output << '* IMPORTANT: you must update the path to the file to include the full path (e.g., C:\Desktop\...).'
      output << "\n"
      output << "***********************************"
      output << "\n"
      output << "DATA LIST FILE= \"#{csv_file}\"  free (\",\")\n"


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
      File.open(spss_file_path, 'w') {|f| f.write(output) }
    end

    if !File.exists?(csv_file_path)
      #######################
      # create csv file
      puts "- creating csv file"
      File.open(csv_file_path, 'w') {|f| f.write(build_csv(dataset, questions)) }
    end

    # create the readme
    create_readme(readme_file_path, 'spss', dataset)

    # create the zip file
    create_zip(dataset.title, zip_file_path, [
        {file_name: @zip_file, file_path: readme_file_path},
        {file_name: @codebook_file, file_path: @codebook_file_path},
        {file_name: csv_file, file_path: csv_file_path},
        {file_name: spss_file, file_path: spss_file_path}
      ]
    )

    # record the path to the file in the dataset
    dataset.urls.spss = "#{dataset.data_download_path}/#{zip_name}"
    dataset.save


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
  def self.stata(dataset)
    puts '>> creating stata'
    start = Time.now

    output = ''
    questions = dataset.questions.for_analysis

    filename = clean_filename(dataset.title)
    csv_file = "stata.csv"
    stata_file = "stata.do"
    stata_file_path = "#{Rails.public_path}#{dataset.data_download_staging_path}/#{stata_file}"
    csv_file_path = "#{Rails.public_path}#{dataset.data_download_staging_path}/#{csv_file}"
    zip_name = "stata.zip"
    zip_file_path = "#{Rails.public_path}#{dataset.data_download_path}/#{zip_name}"
    readme_name = "readme_stata.txt"
    readme_file_path = "#{Rails.public_path}#{dataset.data_download_staging_path}/#{readme_name}"

    if !File.exists?(stata_file_path)
      #######################
      # create stata file
      puts "- creating stata file"
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
      output << " using  #{csv_file} , automatic "

      # write out stata file
      File.open(stata_file_path, 'w') {|f| f.write(output) }
    end

    if !File.exists?(csv_file_path)
      #######################
      # create csv file
      puts "- creating csv file"
      File.open(csv_file_path, 'w') {|f| f.write(build_csv(dataset, questions, with_raw_data: false)) }
    end

    # create the readme
    create_readme(readme_file_path, 'stata', dataset)

    # create the zip file
    create_zip(dataset.title, zip_file_path, [
        {file_name: @zip_file, file_path: readme_file_path},
        {file_name: @codebook_file, file_path: @codebook_file_path},
        {file_name: csv_file, file_path: csv_file_path},
        {file_name: stata_file, file_path: stata_file_path}
      ]
    )

    # record the path to the file in the dataset
    dataset.urls.stata = "#{dataset.data_download_path}/#{zip_name}"
    dataset.save


    puts "-- it took #{(Time.now-start).round(3)} seconds to create the stata and csv files"
    return nil
  end


  #########################################
  #########################################
  # create r file that reads in csv file
  def self.r(dataset)
    puts '>> creating r'
    start = Time.now

    output = ''
    questions = dataset.questions.for_analysis

    filename = clean_filename(dataset.title)
    csv_file = "r.csv"
    r_file = 'r.r'
    r_file_path = "#{Rails.public_path}#{dataset.data_download_staging_path}/#{r_file}"
    csv_file_path = "#{Rails.public_path}#{dataset.data_download_staging_path}/#{csv_file}"
    zip_name = "r.zip"
    zip_file_path = "#{Rails.public_path}#{dataset.data_download_path}/#{zip_name}"
    readme_name = "readme_r.txt"
    readme_file_path = "#{Rails.public_path}#{dataset.data_download_staging_path}/#{readme_name}"


    if !File.exists?(r_file_path)
      #######################
      # create r file
      puts "- creating r file"
      output << '#! /usr/bin/env Rscript'
      output << "\n\n"
      output << "###########################"
      output << "\n"
      output << "# IMPORTANT: update the setwd line below to the directory where the csv file is located"
      output << "\n"
      output << "###########################"
      output << "\n"
      output << "setwd(\".\")"    
      output << "\n\n"
      output << "# read in the csv file to a variable called 'data'"
      output << "\n"
      output << "data <- read.csv('#{csv_file}', header=TRUE)"
      output << "\n\n"
      output << "# quit"
      output << "\n"
      output << "q()"


      # write out r file
      File.open(r_file_path, 'w') {|f| f.write(output) }
    end


    if !File.exists?(csv_file_path)
      #######################
      # create csv file
      puts "- creating csv file"
      File.open(csv_file_path, 'w') {|f| f.write(build_csv(dataset, questions, with_raw_data: false, with_header_code_only: true)) }
    end

    # create the readme
    create_readme(readme_file_path, 'r', dataset)

    # create the zip file
    create_zip(dataset.title, zip_file_path, [
        {file_name: @zip_file, file_path: readme_file_path},
        {file_name: @codebook_file, file_path: @codebook_file_path},
        {file_name: csv_file, file_path: csv_file_path},
        {file_name: r_file, file_path: r_file_path}
      ]
    )

    # record the path to the file in the dataset
    dataset.urls.r = "#{dataset.data_download_path}/#{zip_name}"
    dataset.save


    puts "-- it took #{(Time.now-start).round(3)} seconds to create the r and csv files"
    return nil
  end


  #########################################
  #########################################
  #########################################
  #########################################

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

  #########################################
  #########################################

  def self.build_csv(dataset, questions, options={})
    with_raw_data = options[:with_raw_data].nil? ? true : options[:with_raw_data]
    with_header = options[:with_header].nil? ? false : options[:with_header]
    with_header_code_only = options[:with_header_code_only].nil? ? false : options[:with_header_code_only]

    data = []
    header = []
    csv = nil

    if dataset.present? && questions.present?
      questions.each do |question|
        if with_header_code_only
          header << question.original_code
        else
          header << "#{question.original_code} - #{question.text}"
        end

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
        if with_header || with_header_code_only
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

  #########################################
  #########################################

  def self.create_readme(file_name, type, dataset)
    output = ''
    url_helpers = Rails.application.routes.url_helpers
    url = dataset.public? ? url_helpers.explore_data_dashboard_url(locale: I18n.locale, id: dataset) : url_helpers.dataset_url(locale: I18n.locale, id: url)
    date = dataset.urls.updated_at.present? ? dataset.urls.updated_at : dataset.updated_at

    if !File.exists?(file_name)
      puts '- creating readme'
      # heading
      output << I18n.t('export_data.dataset', title: dataset.title)
      output << "\n"
      output << I18n.t('export_data.download_from', app_name: I18n.t('app.common.app_name'), url: url)
      output << "\n"
      output << I18n.t('export_data.last_update', date: I18n.l(date, format: :long))
      output << "\n\n\n"

      case type
        when 'codebook'
          output << I18n.t('export_data.instructions.codebook')
        when 'csv'
          output << I18n.t('export_data.instructions.csv', 
                    codebook: I18n.t('export_data.instructions.codebook'),
                    csv: I18n.t('export_data.instructions.csv_main'))
        when 'spss'
          output << I18n.t('export_data.instructions.spss', 
                    codebook: I18n.t('export_data.instructions.codebook'),
                    csv: I18n.t('export_data.instructions.csv_main'))
        when 'stata'
          output << I18n.t('export_data.instructions.stata', 
                    codebook: I18n.t('export_data.instructions.codebook'),
                    csv: I18n.t('export_data.instructions.csv_main'))
        when 'r'
          output << I18n.t('export_data.instructions.r', 
                    codebook: I18n.t('export_data.instructions.codebook'),
                    csv: I18n.t('export_data.instructions.csv_main'))
      end

      # write the file
      File.open(file_name, 'w') {|f| f.write(output) }
    end
  end

  #########################################
  #########################################


  # create a zip file with the files provided
  # - files is an array of hash: {file_name, file_path}
  #   where file_name is the name to use for the file in the zip
  def self.create_zip(title, zip_file_path, files=[])

    if !File.exists?(zip_file_path)
      puts "- creating zip"
      # zip the files and move to the main folder
      Zip::Archive.open(zip_file_path, Zip::CREATE) do |zipfile|
        zipfile.add_dir(title)
        files.each do |file|
          # args: file name (with directory), source
          zipfile.add_file("#{title}/#{file[:file_name]}", file[:file_path])
        end
      end
    end
  end

end