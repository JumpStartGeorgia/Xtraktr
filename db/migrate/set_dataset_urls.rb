# set the urls to the download data files if they have been created


# get all datasets that are missing the urls
d = Dataset.where('urls.codebook' => nil)
puts "there are #{d.length} datasets that are missing urls"

d.each do |dataset|
  puts "----------------"
  puts "#{dataset.title}"
  dataset_download_path = "#{Rails.public_path}#{dataset.data_download_path}"

  
  if File.exists?(dataset_download_path) && Dir["#{dataset_download_path}/#{I18n.default_locale}/*"].length == 5
    puts " - files exist, updating urls"

    # make sure the urls obj exists
    dataset.create_urls_object

    #########################################
    #########################################
    ## mongoid does not detect a change in value if updating a translation locale like: x.title_translations['en'] = 'title'
    ## instead, you have replace the entire translations attribute
    ## and that is what these functions are for
    ## the first one saves the exisitng values locally
    ## then after the local values are updated, the urls object is updated
    urls = {codebook: {}, csv: {}, r: {}, spss: {}, stata: {}}
    urls[:codebook] = dataset.urls.codebook_translations.dup if dataset.urls.codebook_translations.present?
    urls[:csv] = dataset.urls.csv_translations.dup if dataset.urls.csv_translations.present?
    urls[:r] = dataset.urls.r_translations.dup if dataset.urls.r_translations.present?
    urls[:spss] = dataset.urls.spss_translations.dup if dataset.urls.spss_translations.present?
    urls[:stata] = dataset.urls.stata_translations.dup if dataset.urls.stata_translations.present?

    # create the urls
    I18n.available_locales.map{|x| x.to_s}.each do |locale|
      #codebook
      if urls[:codebook][locale].nil?
        puts " --> creating #{locale} codebook url"
        urls[:codebook][locale] = "#{dataset.data_download_path}/#{dataset.current_locale}/codebook.zip"
      end

      #csv
      if urls[:csv][locale].nil?
        puts " --> creating #{locale} csv url"
        urls[:csv][locale] = "#{dataset.data_download_path}/#{dataset.current_locale}/csv.zip"
      end

      #r
      if urls[:r][locale].nil?
        puts " --> creating #{locale} r url"
        urls[:r][locale] = "#{dataset.data_download_path}/#{dataset.current_locale}/r.zip"
      end

      #spss
      if urls[:spss][locale].nil?
        puts " --> creating #{locale} spss url"
        urls[:spss][locale] = "#{dataset.data_download_path}/#{dataset.current_locale}/spss.zip"
      end

      #stata
      if urls[:stata][locale].nil?
        puts " --> creating #{locale} stata url"
        urls[:stata][locale] = "#{dataset.data_download_path}/#{dataset.current_locale}/stata.zip"
      end
    end

    # save the urls
    dataset.urls.codebook_translations = urls[:codebook] if urls[:codebook].present?
    dataset.urls.csv_translations = urls[:csv] if urls[:csv].present?
    dataset.urls.r_translations = urls[:r] if urls[:r].present?
    dataset.urls.spss_translations = urls[:spss] if urls[:spss].present?
    dataset.urls.stata_translations = urls[:stata] if urls[:stata].present?

    dataset.save

  end
end
