namespace :migration do
  desc "update shapeset records to use the localization fields"
  task :shapeset_localization => :environment do
    require "./db/migrate/shapeset_localization.rb"
  end


  desc "update dataset records to use the localization fields"
  task :dataset_localization => :environment do
    require "./db/migrate/dataset_localization.rb"
  end
end