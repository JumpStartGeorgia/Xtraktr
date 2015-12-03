# remove permalink key from highlights


Highlight.all.each do |h|
  options = Rack::Utils.parse_query(Base64.urlsafe_decode64(h.embed_id))
  qc = options["question_code"].present? ? options["question_code"] : nil
  bd = options["broken_down_by_code"].present? ? options["broken_down_by_code"] : nil

  
  if h.dataset.present?
    q = h.dataset.questions.with_code(qc) 
    is_comparative = bd.present? 
    is_categorical = q.data_type == 1
    is_numerical = q.data_type == 2
    type = nil
    if is_comparative
      if is_categorical
        type = "crosstab"
      elsif is_numerical
        type = "scatter"
      end
    else 
      if is_categorical
        type = options["chart_type"].present? && options["chart_type"] == "pie" ? "pie" : "bar"
      elsif is_numerical
        type = "histogramm"
      end
    end
    # if q
    #   puts q.text + q.data_type.to_s
    # end
  elsif h.time_series.present?
    type = "time_series"
  else
    puts "#{h.id} - error"
  end

  if(options["chart_type"].present?)
    options.delete("chart_type")
  end

  if type.present? 
    options["visual_type"] = Highlight::VISUAL_TYPES[type.to_sym]
    h.visual_type = Highlight::VISUAL_TYPES[type.to_sym]
    h.embed_id = Base64.urlsafe_encode64(options.to_query)
    h.save
    puts "#{h.id} - done"
  else
    puts "#{h.id} - error type"
  end
  


  # if !(h.dataset.present? || h.time_series.present?) 
  #   h.remove
  # end
  # if options.has_key?('permalink')
  #   puts "- has permalink, removing"
  #   options.delete('permalink')
  #   highlight.embed_id = Base64.urlsafe_encode64(options.to_query)
  #   highlight.save
  # end

end