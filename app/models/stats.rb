class Stats
  include Mongoid::Document
  include Mongoid::Timestamps

  #############################

  belongs_to :dataset

  #############################

  field :questions_analyzable, type: Integer, default: 0
  field :public_questions_analyzable, type: Integer, default: 0
  field :questions_good, type: Integer, default: 0
  field :questions_no_text, type: Integer, default: 0
  field :questions_no_answers, type: Integer, default: 0
  field :questions_bad_answers, type: Integer, default: 0
  field :data_records, type: Integer

  #############################
  
  attr_accessible :data_records, :questions_good, :questions_no_text, :public_questions_analyzable,
      :question_no_answers, :questions_bad_answers, :questions_analyzable, :dataset_id

  #############################
  ## Indexes
  index ({ :dataset_id => 1})
  index ({ :public_questions_analyzable => 1})

  #############################
  ## Scopes
  
  def self.public_question_count
    sum(:public_questions_analyzable)
  end


end