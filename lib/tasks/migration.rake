namespace :migration do
  desc "update shapeset records to use the localization fields"
  task :shapeset_localization => :environment do
    require "./db/migrate/shapeset_localization.rb"
  end


  desc "update dataset records to use the localization fields"
  task :dataset_localization => :environment do
    require "./db/migrate/dataset_localization.rb"
  end


  desc "move dataset stats to own documents (not embed)"
  task :move_stats => :environment do
    require "./db/migrate/move_stats.rb"
  end
end