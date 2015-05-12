namespace :migration do
  # desc "OLD - update shapeset records to use the localization fields"
  # task :shapeset_localization => :environment do
  #   require "./db/migrate/shapeset_localization.rb"
  # end


  # desc "OLD - update dataset records to use the localization fields"
  # task :dataset_localization => :environment do
  #   require "./db/migrate/dataset_localization.rb"
  # end


  # desc "OLD - move dataset stats to own documents (not embed)"
  # task :move_stats => :environment do
  #   require "./db/migrate/move_stats.rb"
  # end


  desc "load the api documentation written for xtraktr"
  task :xtraktr_api_doc => :environment do
    require "./db/migrate/xtraktr_api_doc.rb"
  end


  desc "move time series datasets to own documents (not embed)"
  task :move_time_series_datasets => :environment do
    require "./db/migrate/move_time_series_datasets.rb"
  end


  desc "load dataset urls with shape_file path"
  task :set_urls_shapefile => :environment do
    require "./db/migrate/set_urls_shapefile.rb"
  end

end