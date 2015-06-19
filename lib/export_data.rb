# encoding: utf-8
module ExportData
  require 'csv'
  require 'zipruby'

  # create a zip file of the request type
  # if type is not codebook, include coodebook in zip
  # update dataset with path to the file
  # type = codebook, csv, spss, stata, r
  def self.create_file(dataset, type, use_processed_csv=false)
    start = Time.now

    # @app_key_name = 'xtraktr'
    @app_key_name = 'unicef'


    # set readme file name to appear in zip file
    @readme_file = 'README.txt'

    @dataset_download_path = "#{Rails.public_path}#{dataset.data_download_path}"
    @dataset_download_staging_path = "#{Rails.public_path}#{dataset.data_download_staging_path}"
    @admin_dataset_download_path = "#{Rails.public_path}#{dataset.admin_data_download_path}"
    @admin_dataset_download_staging_path = "#{Rails.public_path}#{dataset.admin_data_download_staging_path}"

    # make sure dataset has url object
    dataset.create_urls_object
    get_url_params(dataset)

    current_locale = dataset.current_locale.dup

    # create files for each locale in the dataset
    dataset.languages.each do |locale|
      puts "@@@@@@@@@@@@@@@@ creating files for locale #{locale}"

      dataset.current_locale = locale

      # the process of creating the text version csv is time consuming
      # this var saves it the first time it is created and then all proceeding calls use it again
      # need to reset the variable when the locale changes so can get data in correct language
      @csv_text_data = {}

      # make sure path exists
      FileUtils.mkpath("#{@dataset_download_path}/#{dataset.current_locale}")    
      FileUtils.mkpath("#{@dataset_download_staging_path}/#{dataset.current_locale}")    
      FileUtils.mkpath("#{@admin_dataset_download_path}/#{dataset.current_locale}")    
      FileUtils.mkpath("#{@admin_dataset_download_staging_path}/#{dataset.current_locale}")    

      # set path to codebook here since used in all methods
      @codebook_file = 'codebook.txt'
      @codebook_file_path = "#{@dataset_download_staging_path}/#{dataset.current_locale}/#{@codebook_file}"
      @admin_codebook_file_path = "#{@admin_dataset_download_staging_path}/#{dataset.current_locale}/#{@codebook_file}"

      # all options require codebook, so create it
      codebook(dataset)

      # generate the requested files
      case type
        when 'csv'
          csv(dataset, use_processed_csv)
        when 'spss'
          spss(dataset, use_processed_csv)
        when 'stata'
          stata(dataset, use_processed_csv)
        when 'r'
          r(dataset, use_processed_csv)
      end

    end

    dataset.current_locale = current_locale
    set_url_params(dataset)

    dataset.save

    puts "@@@@@@@@@@@@@@@@ it took #{(Time.now-start).round(3)} seconds to create #{type} files for dataset"

    return nil
  end


  # create all files for a dataset that do not exist yet
  def self.create_all_files(dataset, use_processed_csv=false)
    start = Time.now

    # @app_key_name = 'xtraktr'
    @app_key_name = 'unicef'

    # set readme file name to appear in zip file
    @readme_file = 'README.txt'

    @dataset_download_path = "#{Rails.public_path}#{dataset.data_download_path}"
    @dataset_download_staging_path = "#{Rails.public_path}#{dataset.data_download_staging_path}"
    @admin_dataset_download_path = "#{Rails.public_path}#{dataset.admin_data_download_path}"
    @admin_dataset_download_staging_path = "#{Rails.public_path}#{dataset.admin_data_download_staging_path}"

    # make sure dataset has url object
    dataset.create_urls_object
    get_url_params(dataset)

    current_locale = dataset.current_locale.dup    

    # create files for each locale in the dataset
    dataset.languages.each do |locale|
      puts "@@@@@@@@@@@@@@@@ creating files for locale #{locale}"

      dataset.current_locale = locale

      # the process of creating the text version csv is time consuming
      # this var saves it the first time it is created and then all proceeding calls use it again
      # need to reset the variable when the locale changes so can get data in correct language
      @csv_text_data = {}

      # make sure path exists
      FileUtils.mkpath("#{@dataset_download_path}/#{dataset.current_locale}")    
      FileUtils.mkpath("#{@dataset_download_staging_path}/#{dataset.current_locale}")    
      FileUtils.mkpath("#{@admin_dataset_download_path}/#{dataset.current_locale}")    
      FileUtils.mkpath("#{@admin_dataset_download_staging_path}/#{dataset.current_locale}")    

      # set path to codebook here since used in all methods
      @codebook_file = 'codebook.txt'
      @codebook_file_path = "#{@dataset_download_staging_path}/#{dataset.current_locale}/#{@codebook_file}"
      @admin_codebook_file_path = "#{@admin_dataset_download_staging_path}/#{dataset.current_locale}/#{@codebook_file}"

      codebook(dataset)
      csv(dataset, use_processed_csv)
      spss(dataset, use_processed_csv)
      stata(dataset, use_processed_csv)
      r(dataset, use_processed_csv)

    end

    dataset.current_locale = current_locale
    set_url_params(dataset)

    # indicate that the files are up to date
    # unless using procesed csv because the real files still need to be created
    dataset.reset_download_files = use_processed_csv
    
    dataset.save

    puts "@@@@@@@@@@@@@@@@ it took #{(Time.now-start).round(3)} seconds to create all files for dataset"
  end


  # make sure all datasets have data files
  def self.create_all_dataset_files(use_processed_csv=false)
    start = Time.now
    puts "*** use_processed_csv = #{use_processed_csv}"
    
    Dataset.needs_download_files.each do |dataset|
      puts ">>>>>>>>>> dataset: #{dataset.title}"
      # create the data files for this dataset
      create_all_files(dataset, use_processed_csv)
    end

    puts ">>>>>>>> it took #{(Time.now-start).round(3)} seconds to create all files for all datasets"
  end


  #########################################
  #########################################
  #########################################
  #########################################

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

    # create the public files
    generate_codebook(dataset)

    # create the admin files
    generate_codebook(dataset, true)


    puts "-- it took #{(Time.now-start).round(3)} seconds to create the codebook files"
    return nil  
  end


  #########################################
  #########################################
  # create codebook file
  # format: 
  # question code - question
  # answers:
  #   value - text
  def self.generate_codebook(dataset, is_admin=false)
    puts ">>> generating codebook, is admin = #{is_admin} "
    start = Time.now

    codebook_file_path = is_admin ? @admin_codebook_file_path : @codebook_file_path
    download_path = is_admin ? @admin_dataset_download_path : @dataset_download_path
    staging_path = is_admin ? @admin_dataset_download_staging_path : @dataset_download_staging_path
    zip_name = "codebook.zip"
    readme_name = "readme_codebook.txt"
    zip_file_path = "#{download_path}/#{dataset.current_locale}/#{zip_name}"
    readme_file_path = "#{staging_path}/#{dataset.current_locale}/#{readme_name}"

    # create the codebook
    if !File.exists?(codebook_file_path) || dataset.reset_download_files?
      output = ''

      # add title
      output << dataset.title
      output << "\n"
      output << "Codebook Generated On: #{I18n.l(start, format: :file)}"
      output << "\n\n"

      # add each question/answer
      # - use only questions/answers that can be downloaded and analyzed
      questions = is_admin ? dataset.questions : dataset.questions.for_download
      questions.each do |question|
        output << "--------------"
        output << "\n"
        output << "#{question.original_code} - #{clean_text(question.text)}"
        output << "\n"
        if question.notes.present?
          output << "#{I18n.t('app.common.notes')}: #{question.notes}"        
          output << "\n"
        end
        output << "#{I18n.t('app.common.answers')}:"
        output << "\n"
        answers = is_admin ? question.answers : question.answers.all_for_analysis
        answers.each do |answer|
          output << "  #{answer.value} - #{clean_text(answer.text)}"
          output << "\n"
        end
        output << "\n"
      end

      #######################
      # create codebook file
      puts "- creating codebook file"
      File.open(codebook_file_path, 'w') {|f| f.write(output) }
    end


    # create the readme
    create_readme(readme_file_path, 'codebook', dataset)

    # create the zip file
    create_zip(dataset, zip_file_path, [
        {file_name: @readme_file, file_path: readme_file_path},
        {file_name: @codebook_file, file_path: codebook_file_path}
      ]
    )

    # record the path to the file in the dataset
    if is_admin
      @urls[:admin_codebook][dataset.current_locale] = "#{dataset.admin_data_download_path}/#{dataset.current_locale}/#{zip_name}"
    else
      @urls[:codebook][dataset.current_locale] = "#{dataset.data_download_path}/#{dataset.current_locale}/#{zip_name}"
    end

    puts "--- it took #{(Time.now-start).round(3)} seconds to create the codebook file, is admin = #{is_admin}"
    return nil  
  end


  #########################################
  #########################################
  # create csv file
  def self.csv(dataset, use_processed_csv=false)
    puts '>> creating csv'
    start = Time.now

    csv_file = "csv.csv"
    csv_file_path = "#{@dataset_download_staging_path}/#{dataset.current_locale}/#{csv_file}"
    
    csv_data = nil
    if !File.exists?(csv_file_path) || dataset.reset_download_files?
      puts "-- building csv data"
      start_csv = Time.now
      csv_data = build_csv(dataset, with_raw_data: false, with_header: true)
      puts "-- it took #{(Time.now-start_csv).round(3)} seconds to build the csv data"
    end

    # create the public files
    generate_csv(dataset, csv_data, use_processed_csv)

    # create the admin files
    generate_csv(dataset, csv_data, use_processed_csv, true)
    
    puts "-- it took #{(Time.now-start).round(3)} seconds to create the csv files"
    return nil  
  end

  # create csv file
  def self.generate_csv(dataset, csv_data, use_processed_csv=false, is_admin=false)
    puts ">>> generating csv, is admin = #{is_admin} "
    start = Time.now

    codebook_file_path = is_admin ? @admin_codebook_file_path : @codebook_file_path
    download_path = is_admin ? @admin_dataset_download_path : @dataset_download_path
    staging_path = is_admin ? @admin_dataset_download_staging_path : @dataset_download_staging_path

    csv_file = "csv.csv"
    zip_name = "csv.zip"
    readme_name = "readme_csv.txt"
    csv_file_path = "#{staging_path}/#{dataset.current_locale}/#{csv_file}"
    readme_file_path = "#{staging_path}/#{dataset.current_locale}/#{readme_name}"
    zip_file_path = "#{download_path}/#{dataset.current_locale}/#{zip_name}"
    
    #######################
    # create csv file
    if !File.exists?(csv_file_path) || dataset.reset_download_files?
      if use_processed_csv
        puts "- copying processed csv file"
        copy_processed_csv(dataset, csv_file_path)
      else
        puts "- creating csv file"
        File.open(csv_file_path, 'w') {|f| f.write(is_admin ? csv_data[:admin] : csv_data[:public]) }
      end
    end

    # create the readme
    create_readme(readme_file_path, 'csv', dataset)

    # create the zip file
    create_zip(dataset, zip_file_path, [
        {file_name: @readme_file, file_path: readme_file_path},
        {file_name: @codebook_file, file_path: codebook_file_path},
        {file_name: csv_file, file_path: csv_file_path}
      ]
    )

    # record the path to the file in the dataset
    if is_admin
      @urls[:admin_csv][dataset.current_locale] = "#{dataset.admin_data_download_path}/#{dataset.current_locale}/#{zip_name}"
    else
      @urls[:csv][dataset.current_locale] = "#{dataset.data_download_path}/#{dataset.current_locale}/#{zip_name}"
    end
    
    puts "--- it took #{(Time.now-start).round(3)} seconds to create the csv file, is admin = #{is_admin}"
    return nil  
  end



  #########################################
  #########################################
  # create spss file
  # notes 
  # - strings cannot be more than 60 chars
  def self.spss(dataset, use_processed_csv=false)
    puts '>> creating spss'
    start = Time.now

    csv_file = "spss.csv"
    csv_file_path = "#{@dataset_download_staging_path}/#{dataset.current_locale}/#{csv_file}"
    

    csv_data = nil
    if (!File.exists?(csv_file_path) || dataset.reset_download_files?) && !use_processed_csv
      puts "- building csv data"
      start_csv = Time.now
      csv_data = build_csv(dataset)
      puts "-- it took #{(Time.now-start_csv).round(3)} seconds to build the csv data"
    end

    # create the public files
    generate_spss(dataset, csv_data, use_processed_csv)

    # create the admin files
    generate_spss(dataset, csv_data, use_processed_csv, true)

    puts "-- it took #{(Time.now-start).round(3)} seconds to create the spss and csv files"
    return nil
  end


  # create spss file
  # notes 
  # - strings cannot be more than 60 chars
  def self.generate_spss(dataset, csv_data, use_processed_csv=false, is_admin=false)
    puts ">>> generating spss, is admin = #{is_admin}"
    start = Time.now

    output = ''

    questions = is_admin ? dataset.questions : dataset.questions.for_download
    codebook_file_path = is_admin ? @admin_codebook_file_path : @codebook_file_path
    download_path = is_admin ? @admin_dataset_download_path : @dataset_download_path
    staging_path = is_admin ? @admin_dataset_download_staging_path : @dataset_download_staging_path

    csv_file = "spss.csv"
    spss_file = 'spss.sps'
    zip_name = "spss.zip"
    readme_name = "readme_spss.txt"
    spss_file_path = "#{staging_path}/#{dataset.current_locale}/#{spss_file}"
    csv_file_path = "#{staging_path}/#{dataset.current_locale}/#{csv_file}"
    readme_file_path = "#{staging_path}/#{dataset.current_locale}/#{readme_name}"
    zip_file_path = "#{download_path}/#{dataset.current_locale}/#{zip_name}"
    

    if !File.exists?(spss_file_path) || dataset.reset_download_files?
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
        answers = is_admin ? question.answers : question.answers.all_for_analysis
        if answers.present?
          output << "/ \n"
          output << question.original_code
          output << " \n"
          answers.each do |answer|
            output << ' ' # not needed - just to make it easier to read
            output << answer.value
            output << ' "'
            output << shorten_text(clean_text(answer.text))
            output << "\" \n"
          end
        end
      end
      output << " . \n\n"


      # finish the file
      output << 'EXECUTE.'

      # write out spss file
      File.open(spss_file_path, 'w') {|f| f.write(output) }
    end

    #######################
    # create csv file
    if !File.exists?(csv_file_path) || dataset.reset_download_files?
      if use_processed_csv
        puts "- copying processed csv file to #{csv_file_path}"
        copy_processed_csv(dataset, csv_file_path)
      else
        puts "- creating csv file at #{csv_file_path}"
        File.open(csv_file_path, 'w') {|f| f.write(is_admin ? csv_data[:admin] : csv_data[:public]) }
      end
    end

    # create the readme
    create_readme(readme_file_path, 'spss', dataset)

    # create the zip file
    create_zip(dataset, zip_file_path, [
        {file_name: @readme_file, file_path: readme_file_path},
        {file_name: @codebook_file, file_path: codebook_file_path},
        {file_name: csv_file, file_path: csv_file_path},
        {file_name: spss_file, file_path: spss_file_path}
      ]
    )

    # record the path to the file in the dataset
    if is_admin
      @urls[:admin_spss][dataset.current_locale] = "#{dataset.admin_data_download_path}/#{dataset.current_locale}/#{zip_name}"
    else
      @urls[:spss][dataset.current_locale] = "#{dataset.data_download_path}/#{dataset.current_locale}/#{zip_name}"
    end

    puts "--- it took #{(Time.now-start).round(3)} seconds to create the spss and csv files, is admin = #{is_admin}"
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
  def self.stata(dataset, use_processed_csv=false)
    puts '>> creating stata'
    start = Time.now

    csv_file = "stata.csv"
    csv_file_path = "#{@dataset_download_staging_path}/#{dataset.current_locale}/#{csv_file}"

    csv_data = nil
    if (!File.exists?(csv_file_path) || dataset.reset_download_files?) && !use_processed_csv
      puts "- building csv data"
      start_csv = Time.now
      csv_data = build_csv(dataset, with_raw_data: false)
      puts "-- it took #{(Time.now-start_csv).round(3)} seconds to build the csv data"
    end

    # create the public files
    generate_stata(dataset, csv_data, use_processed_csv)

    # create the admin files
    generate_stata(dataset, csv_data, use_processed_csv, true)

    puts "-- it took #{(Time.now-start).round(3)} seconds to create the stata and csv files"
    return nil
  end

  # create stata file
  # notes:
  # if provide the automatic flag, stata will automatically create the variable values
  # you tell stata that the variable has unique values by add ':name_fmt' after question code
  # create labels:
      # label define sexfmt 0 "Male" 1 "Female"
      # infile str16 name sex:sexfmt age using persons        
  def self.generate_stata(dataset, csv_data, use_processed_csv=false, is_admin=false)
    puts ">>> creating stata, is_admin = #{is_admin}"
    start = Time.now

    output = ''

    questions = is_admin ? dataset.questions : dataset.questions.for_download
    codebook_file_path = is_admin ? @admin_codebook_file_path : @codebook_file_path
    download_path = is_admin ? @admin_dataset_download_path : @dataset_download_path
    staging_path = is_admin ? @admin_dataset_download_staging_path : @dataset_download_staging_path

    csv_file = "stata.csv"
    stata_file = "stata.do"
    zip_name = "stata.zip"
    readme_name = "readme_stata.txt"
    stata_file_path = "#{staging_path}/#{dataset.current_locale}/#{stata_file}"
    csv_file_path = "#{staging_path}/#{dataset.current_locale}/#{csv_file}"
    readme_file_path = "#{staging_path}/#{dataset.current_locale}/#{readme_name}"
    zip_file_path = "#{download_path}/#{dataset.current_locale}/#{zip_name}"


    if !File.exists?(stata_file_path) || dataset.reset_download_files?
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

    #######################
    # create csv file
    if !File.exists?(csv_file_path) || dataset.reset_download_files?
      if use_processed_csv
        puts "- copying processed csv file"
        copy_processed_csv(dataset, csv_file_path)
      else
        puts "- creating csv file"
        File.open(csv_file_path, 'w') {|f| f.write(is_admin ? csv_data[:admin] : csv_data[:public]) }
      end
    end

    # create the readme
    create_readme(readme_file_path, 'stata', dataset)

    # create the zip file
    create_zip(dataset, zip_file_path, [
        {file_name: @readme_file, file_path: readme_file_path},
        {file_name: @codebook_file, file_path: codebook_file_path},
        {file_name: csv_file, file_path: csv_file_path},
        {file_name: stata_file, file_path: stata_file_path}
      ]
    )

    # record the path to the file in the dataset
    if is_admin
      @urls[:admin_stata][dataset.current_locale] = "#{dataset.admin_data_download_path}/#{dataset.current_locale}/#{zip_name}"
    else
      @urls[:stata][dataset.current_locale] = "#{dataset.data_download_path}/#{dataset.current_locale}/#{zip_name}"
    end

    puts "--- it took #{(Time.now-start).round(3)} seconds to create the stata and csv files, is admin = #{is_admin}"
    return nil
  end


  #########################################
  #########################################
  # create r file that reads in csv file
  def self.r(dataset, use_processed_csv=false)
    puts '>> creating r'
    start = Time.now

    csv_file = "r.csv"
    csv_file_path = "#{@dataset_download_staging_path}/#{dataset.current_locale}/#{csv_file}"

    csv_data = nil
    if (!File.exists?(csv_file_path) || dataset.reset_download_files?) && !use_processed_csv
      puts "- building csv data"
      start_csv = Time.now
      csv_data = build_csv(dataset, with_raw_data: false, with_header_code_only: true)
      puts "-- it took #{(Time.now-start_csv).round(3)} seconds to build the csv data"
    end

    # create the public files
    generate_r(dataset, csv_data, use_processed_csv)

    # create the admin files
    generate_r(dataset, csv_data, use_processed_csv, true)


    puts "-- it took #{(Time.now-start).round(3)} seconds to create the r and csv files"
    return nil
  end


  #########################################
  #########################################
  # create r file that reads in csv file
  def self.generate_r(dataset, csv_data, use_processed_csv=false, is_admin=false)
    puts ">>> generating r, is admin = #{is_admin} "
    start = Time.now

    output = ''

    questions = is_admin ? dataset.questions : dataset.questions.for_download
    codebook_file_path = is_admin ? @admin_codebook_file_path : @codebook_file_path
    download_path = is_admin ? @admin_dataset_download_path : @dataset_download_path
    staging_path = is_admin ? @admin_dataset_download_staging_path : @dataset_download_staging_path

    csv_file = "r.csv"
    r_file = 'r.r'
    zip_name = "r.zip"
    readme_name = "readme_r.txt"
    r_file_path = "#{staging_path}/#{dataset.current_locale}/#{r_file}"
    csv_file_path = "#{staging_path}/#{dataset.current_locale}/#{csv_file}"
    readme_file_path = "#{staging_path}/#{dataset.current_locale}/#{readme_name}"
    zip_file_path = "#{download_path}/#{dataset.current_locale}/#{zip_name}"


    if !File.exists?(r_file_path) || dataset.reset_download_files?
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

    #######################
    # create csv file
    if !File.exists?(csv_file_path) || dataset.reset_download_files?
      if use_processed_csv
        puts "- copying processed csv file"
        copy_processed_csv(dataset, csv_file_path)
      else
        puts "- creating csv file"
        File.open(csv_file_path, 'w') {|f| f.write(is_admin ? csv_data[:admin] : csv_data[:public]) }
      end
    end

    # create the readme
    create_readme(readme_file_path, 'r', dataset)

    # create the zip file
    create_zip(dataset, zip_file_path, [
        {file_name: @readme_file, file_path: readme_file_path},
        {file_name: @codebook_file, file_path: codebook_file_path},
        {file_name: csv_file, file_path: csv_file_path},
        {file_name: r_file, file_path: r_file_path}
      ]
    )

    # record the path to the file in the dataset
    if is_admin
      @urls[:admin_r][dataset.current_locale] = "#{dataset.admin_data_download_path}/#{dataset.current_locale}/#{zip_name}"
    else
      @urls[:r][dataset.current_locale] = "#{dataset.data_download_path}/#{dataset.current_locale}/#{zip_name}"
    end

    puts "--- it took #{(Time.now-start).round(3)} seconds to create the r and csv files, is admin = #{is_admin}"
    return nil
  end


  #########################################
  #########################################
  #########################################
  #########################################

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

  # build csv for both public and admin downloads
  # return hash with admin array and public array
  def self.build_csv(dataset, options={})
    with_raw_data = options[:with_raw_data].nil? ? true : options[:with_raw_data]
    with_header = options[:with_header].nil? ? false : options[:with_header]
    with_header_code_only = options[:with_header_code_only].nil? ? false : options[:with_header_code_only]

    data = {admin: [], public: []}
    header = []
    csv = {admin: [], public: []}

    if dataset.present? && dataset.questions.present?
      dataset.questions.each do |question|
        if with_header_code_only
          header << question.original_code
        else
          header << "#{question.original_code} - #{question.text}"
        end

        if with_raw_data
          # use the data values
          data[:public] << dataset.data_items.code_data(question.code)
          data[:admin] << dataset.data_items.code_data(question.code)
        else
          # replace the data values with the answer text
          # if the data has already been created on a previous call, use it
          if @csv_text_data.present? && @csv_text_data[question.code].present?
            data[:public] << @csv_text_data[question.code][:public]
            data[:admin] << @csv_text_data[question.code][:admin]
          else
            # get original data
            question_data_admin = dataset.data_items.code_data(question.code)
            question_data_public = question_data_admin.dup

            # now replace data values with answer text
            question.answers.sorted.each do |answer|
              # only need to update the public if this answer is not excluded
              if !answer.exclude
                question_data_public.select{ |x| x == answer.value }.each{ |x| x.replace( answer.text ) }
              end
              question_data_admin.select{ |x| x == answer.value }.each{ |x| x.replace( answer.text ) }
            end

            # save for use by other calls to this method
            @csv_text_data[question.code] = {}
            @csv_text_data[question.code][:public] = question_data_public
            @csv_text_data[question.code][:admin] = question_data_admin

            data[:public] << question_data_public
            data[:admin] << question_data_admin
          end
        end
      end

      # now use transpose to get in proper format
      # - for admin, get all data
      csv[:admin] = CSV.generate do |csv_row|
        if with_header || with_header_code_only
          csv_row << header
        end

        data[:admin].transpose.each do |row|
          csv_row << row.map{|x| 
            y = x.nil? || x.empty? ? nil : clean_text(x)
            y.present? ? y : nil
          }
        end
      end

      # for public, only get data that is downloadable
      public_indexes = dataset.questions.each_index.select{|i| dataset.questions[i].can_download?}
      csv[:public] = CSV.generate do |csv_row|
        public_header = []
        public_data = []

        # if the index is in public_indexes, keep it
        (0..data[:public].length-1).each do |index|
          if public_indexes.include?(index)
            public_header << header[index]
            public_data << data[:public][index]
          end
        end

        if with_header || with_header_code_only
          csv_row << public_header
        end

        public_data.transpose.each do |row|
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
    # it is possible that the dataset locale is not an app locale
    # if this is the case, use the current locale
    locale = I18n.available_locales.include?(dataset.current_locale.to_sym) ? dataset.current_locale : I18n.locale
    # if the dataset is public, use the public url, else the admin one
    url = dataset.public? ? url_helpers.explore_data_dashboard_url(locale: locale, id: dataset.slug) : url_helpers.dataset_url(locale: I18n.locale, id: dataset.slug)
    # if the urls updated_at does not exist, use the dataset updated_at
    date = dataset.urls.updated_at.present? ? dataset.urls.updated_at : dataset.updated_at

    if !File.exists?(file_name) || dataset.reset_download_files?
      puts '- creating readme'
      # heading
      output << I18n.t('export_data.dataset', title: dataset.title)
      output << "\n"
      output << I18n.t('export_data.download_from', app_name: I18n.t("app.common.#{@app_key_name}.app_name"), url: url)
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
  def self.create_zip(dataset, zip_file_path, files=[])

    FileUtils.rm zip_file_path if dataset.reset_download_files? && File.exists?(zip_file_path)

    if !File.exists?(zip_file_path)
      puts "- creating zip"
      # zip the files and move to the main folder
      Zip::Archive.open(zip_file_path, Zip::CREATE) do |zipfile|
        zipfile.add_dir(dataset.title)
        files.each do |file|
          # args: file name (with directory), source
          zipfile.add_file("#{dataset.title}/#{file[:file_name]}", file[:file_path])
        end
      end
    end
  end


  def self.copy_processed_csv(dataset, csv_file_path)
    # path to the processed csv file
    processed_file_path = "#{Rails.public_path}/system/datasets/#{dataset.id}/processed/data.csv"
    
    FileUtils.cp processed_file_path, csv_file_path if File.exists?(processed_file_path)
  end

  #########################################
  #########################################
  ## mongoid does not detect a change in value if updating a translation locale like: x.title_translations['en'] = 'title'
  ## instead, you have replace the entire translations attribute
  ## and that is what these functions are for
  ## the first one saves the exisitng values locally
  ## then after the local values are updated, the urls object is updated

  def self.get_url_params(dataset)
    @urls = {codebook: {}, csv: {}, r: {}, spss: {}, stata: {}, admin_codebook: {}, admin_csv: {}, admin_r: {}, admin_spss: {}, admin_stata: {}}
    @urls[:codebook] = dataset.urls.codebook_translations.dup if dataset.urls.codebook_translations.present?
    @urls[:csv] = dataset.urls.csv_translations.dup if dataset.urls.csv_translations.present?
    @urls[:r] = dataset.urls.r_translations.dup if dataset.urls.r_translations.present?
    @urls[:spss] = dataset.urls.spss_translations.dup if dataset.urls.spss_translations.present?
    @urls[:stata] = dataset.urls.stata_translations.dup if dataset.urls.stata_translations.present?

    @urls[:admin_codebook] = dataset.urls.admin_codebook_translations.dup if dataset.urls.admin_codebook_translations.present?
    @urls[:admin_csv] = dataset.urls.admin_csv_translations.dup if dataset.urls.admin_csv_translations.present?
    @urls[:admin_r] = dataset.urls.admin_r_translations.dup if dataset.urls.admin_r_translations.present?
    @urls[:admin_spss] = dataset.urls.admin_spss_translations.dup if dataset.urls.admin_spss_translations.present?
    @urls[:admin_stata] = dataset.urls.admin_stata_translations.dup if dataset.urls.admin_stata_translations.present?
  end

  def self.set_url_params(dataset)
    dataset.urls.codebook_translations = @urls[:codebook] if @urls[:codebook].present?
    dataset.urls.csv_translations = @urls[:csv] if @urls[:csv].present?
    dataset.urls.r_translations = @urls[:r] if @urls[:r].present?
    dataset.urls.spss_translations = @urls[:spss] if @urls[:spss].present?
    dataset.urls.stata_translations = @urls[:stata] if @urls[:stata].present?

    dataset.urls.admin_codebook_translations = @urls[:admin_codebook] if @urls[:admin_codebook].present?
    dataset.urls.admin_csv_translations = @urls[:admin_csv] if @urls[:admin_csv].present?
    dataset.urls.admin_r_translations = @urls[:admin_r] if @urls[:admin_r].present?
    dataset.urls.admin_spss_translations = @urls[:admin_spss] if @urls[:admin_spss].present?
    dataset.urls.admin_stata_translations = @urls[:admin_stata] if @urls[:admin_stata].present?
  end




end