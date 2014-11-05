class Stats
  include Mongoid::Document

  field :questions_good, type: Integer, default: 0
  field :questions_no_text, type: Integer, default: 0
  field :questions_no_answers, type: Integer, default: 0
  field :questions_bad_answers, type: Integer, default: 0
  field :data_records, type: Integer


  embedded_in :dataset

  #############################
  
  attr_accessible :data_records, :questions_good, :questions_no_text, :question_no_answers, :questions_bad_answers

  #############################


end