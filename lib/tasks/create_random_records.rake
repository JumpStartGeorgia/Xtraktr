namespace :create_random_records do

  ##########################################################
  desc "assign random categories to datasets / time series"
  task :categories => :environment do |t, args|
    max = 5

    category_ids = Category.pluck(:id)

    Dataset.all.each do |dataset|
      # if already have categories, skip it
      if !dataset.category_mappers.present?
        random_ids = category_ids.sample(rand(max)+1)

        puts "- adding #{random_ids.length} dataset categories for #{dataset.title}"

        random_ids.each do |id|
          dataset.category_mappers.create(category_id: id)
        end
      end
    end

    puts "--------"

    TimeSeries.all.each do |time_series|
      # if already have categories, skip it
      if !time_series.category_mappers.present?
        random_ids = category_ids.sample(rand(max)+1)

        puts "- adding #{random_ids.length} time series categories for #{time_series.title}"

        random_ids.each do |id|
          time_series.category_mappers.create(category_id: id)
        end
      end
    end
  end


  ##########################################################
  desc "assign random highlights to datasets / time series"
  task :highlights => :environment do |t, args|
    max = 5

    Highlight.destroy_all

    Dataset.is_public.each do |dataset|
      # if already have highlights, skip it
      if !dataset.highlights.present?

        # get random question_codes
        random_codes = dataset.questions.unique_codes_for_analysis.sample(rand(max)+1)

        puts "- adding #{random_codes.length} dataset highlights for #{dataset.title}"

        random_codes.each_with_index do |code, index|
          # if the index is 3, create a time series with the first code
          if index == 3
            params = {dataset_id: dataset.id, question_code: code, broken_down_by_code: random_codes[0], visual_type: 'chart', with_chart_data: true, with_map_data: true, with_title: true}
            embed_id = Base64.urlsafe_encode64(params.to_query)
            dataset.highlights.create(embed_id: embed_id, visual_type: 2)
          else
            params = {dataset_id: dataset.id, question_code: code, visual_type: 'chart', with_chart_data: true, with_map_data: true, with_title: true}
            embed_id = Base64.urlsafe_encode64(params.to_query)
            dataset.highlights.create(embed_id: embed_id, visual_type: 1)
          end
        end
      end
    end

    puts "--------"

    TimeSeries.is_public.each do |time_series|
      # if already have highlights, skip it
      if !time_series.highlights.present?
        # get random question_codes
        random_codes = time_series.questions.unique_codes.sample(rand(max)+1)

        puts "- adding #{random_codes.length} time series highlights for #{time_series.title}"

        random_codes.each do |code|
          # build the embed_id
          params = {time_series_id: time_series.id, question_code: code, visual_type: 'chart', with_chart_data: true, with_map_data: true, with_title: true}
          embed_id = Base64.urlsafe_encode64(params.to_query)
          time_series.highlights.create(embed_id: embed_id, visual_type: 3)
        end
      end
    end

    # now assign one highlight to home page
    public_dataset_ids = Dataset.is_public.pluck(:id)
    highlight = Highlight.in(dataset_id: public_dataset_ids).skip(rand(Highlight.in(dataset_id: public_dataset_ids).count)).first
    highlight.show_home_page = true
    highlight.save
  end

end

