namespace :generate_files do

  desc "create the download data files for all datasets that are missing them or have reset_download_files = true; pass in [true] to do quick processing"
  task :download_data_files, [:use_processed_csv] => :environment do |t, args|
    require "export_data"
    args.with_defaults(:use_processed_csv => false)

    ExportData.create_all_dataset_files(args.use_processed_csv)
  end

end

