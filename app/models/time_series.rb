class TimeSeries < CustomTranslation
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Search
  include Mongoid::Slug

  #############################

  belongs_to :user

  #############################

  field :title, type: String, localize: true
  field :description, type: String, localize: true
  # whether or not dataset can be shown to public
  field :public, type: Boolean, default: false
  # when made public
  field :public_at, type: Date
  # key to access dataset that is not public
  field :private_share_key, type: String
  field :languages, type: Array
  field :default_language, type: String
  field :permalink, type: String

  has_many :category_mappers, dependent: :destroy do
    def category_ids
      pluck(:category_id)
    end
  end

  has_many :highlights, dependent: :destroy do
    # get highlight by embed id
    def with_embed_id(embed_id)
      where(embed_id: embed_id).first
    end

    # get embeds id for this tome series
    def embed_ids
      pluck(:embed_id)
    end
  end
  
  has_many :datasets, class_name: 'TimeSeriesDataset', dependent: :destroy do
    def sorted
      order_by([[:sort_order, :asc], [:title, :asc]]).to_a
    end

    def dataset_ids
      only(:dataset_id).order_by([[:sort_order, :asc], [:title, :asc]]).map(:dataset_id)
    end
  end 

  embeds_many :questions, class_name: 'TimeSeriesQuestion' do
    # get the question that has the provided code
    def with_code(code)
      where(:code => code.downcase).first
    end

    # get the dataset question records for the provided code
    def dataset_questions_in_code(code)
      with_code(code).dataset_questions
    end
  
    def sorted
      order_by([[:code, :asc]])
    end

    # get all of the questions codes in this time series for a dataset
    def codes_for_dataset(dataset_id)
      map{|x| x.dataset_questions}.flatten.select{|x| x.dataset_id == dataset_id}.map{|x| x.code}
    end    

    # get just the codes
    def unique_codes
      only(:code).map{|x| x.code}
    end

  end

  #############################

  accepts_nested_attributes_for :datasets, reject_if: :all_blank
  accepts_nested_attributes_for :questions, reject_if: :all_blank
  accepts_nested_attributes_for :category_mappers, reject_if: :all_blank, :allow_destroy => true

  attr_accessible :title, :description, :user_id, 
      :public, :private_share_key, 
      :datasets_attributes, :questions_attributes,
      :languages, :default_language,
      :title_translations, :description_translations, 
      :category_mappers_attributes, :category_ids, :permalink

  attr_accessor :category_ids

  #############################
  # indexes
  index ({ :title => 1})
  index ({ :public => 1})
  index ({ :public_at => 1})
  index ({ :private_share_key => 1})
  index ({ :user_id => 1})
  index ({ :'questions.code' => 1})
  index ({ :'questions.original_code' => 1})
  index ({ :'questions.text' => 1})
  index ({ :'questions.answers.can_exclude' => 1})
  index ({ :'questions.answers.sort_order' => 1})

  #############################
  # Full text search
  search_in :title, :description, :questions => [:original_code, :text, :notes, :answers => [:text]]

  #############################
  # permalink slug
  # if the dataset is public, use the permalink field value if it exists, else the default lang title
  slug :permalink, :title, :public, history: true do |d|
    if d.public?
      if d.permalink.present?
        d.permalink.to_url
      else
        d.title_translations[d.default_language].to_url
      end
    else
      return nil
    end
  end

  #############################
  # Validations
  validates_presence_of :default_language
  validate :validate_languages
  validate :validate_translations
  validate :validate_dataset_presence

  # validate that at least one item in languages exists
  def validate_languages
    # first remove any empty items
    self.languages.delete("")
    logger.debug "***** validates languages: #{self.languages.blank?}"
    if self.languages.blank?
      errors.add(:languages, I18n.t('errors.messages.blank'))
    else
      # make sure each locale in languages is in Language
      self.languages.each do |locale|
        if Language.where(:locale => locale).count == 0
          errors.add(:languages, I18n.t('errors.messages.invalid_language', lang_locale: locale))
        end
      end
    end
  end

  # validate the translation fields
  # title field need to be validated for presence
  def validate_translations
    logger.debug "***** validates dataset translations"
    if self.default_language.present?
      logger.debug "***** - default is present; title = #{self.title_translations[self.default_language]}"
      if self.title_translations[self.default_language].blank?
        logger.debug "***** -- title not present!"
        errors.add(:base, I18n.t('errors.messages.translation_default_lang', 
            field_name: self.class.human_attribute_name('title'),
            language: Language.get_name(self.default_language),
            msg: I18n.t('errors.messages.blank')) )
      end
    end
  end 

  # make sure at least two datasets exist
  def validate_dataset_presence
    if self.datasets.blank? || self.datasets.length < 2
      logger.debug "***** -- not enough datasets!"
      errors.add(:base, I18n.t('errors.messages.dataset_length'))
    end
  end

  #############################
  ## override get methods for fields that are localized
  def title
    get_translation(self.title_translations)
  end
  def description
    get_translation(self.description_translations)
  end


  #############################
  # Callbacks
  after_initialize :set_category_ids
  before_create :create_private_share_key
  before_save :set_public_at

  # this is used in the form to set the categories
  def set_category_ids
    self.category_ids = self.category_mappers.category_ids
  end

  # create private share key that allows people to access this dataset if it is not public
  def create_private_share_key
    if self.private_share_key.blank?
      self.private_share_key = SecureRandom.hex
    end
    return true
  end

  # if public and public at not exist, set it
  # else, make nil
  def set_public_at
    if self.public? && self.public_at.nil?
      self.public_at = Time.now.to_date
    elsif !self.public?
      self.public_at = nil
    end
  end

  #############################
  # Scopes

  def self.only_id_title
    only(:id, :title)
  end

  def self.only_id_title_description
    only(:id, :title, :description)
  end

  def self.meta_only
    without(:questions)
  end

  def self.search(q)
    full_text_search(q)
  end

  def self.sorted_title
    order_by([[:title, :asc]])
  end

  def self.sorted
    sorted_title
  end

  def self.sorted_public_at
    order_by([[:public_at, :desc], [:title, :asc]])
  end

  def self.recent
    sorted_public_at
  end

  def self.is_public
    where(public: true)
  end

  def self.by_private_key(key)
    where(private_share_key: key).first
  end

  def self.by_user(user_id)
    # where(user_id: user_id)
    all
  end

  # get the record if the user is the owner
  def self.by_id_for_user(id, user_id)
    # where(id: id).by_user(user_id).first
    by_user(user_id).find(id)
  end

  def self.categorize(cat)
    cat = Category.find_by(permalink: cat) 
    if cat.present?
      self.in(id: CategoryMapper.where(category_id: cat.id).pluck(:time_series_id))
    else
      all
    end
  end
  

  #############################

  # get list of all dates included in time series
  def dates_included
    self.datasets.sorted.map{|x| x.title}
  end


  def categories
    Category.in(id: self.category_mappers.map {|x| x.category_id } ).to_a
  end



  #############################

  # automatically assign match questions from all the datasets
  # returns the number of questions that were matched
  def automatically_assign_questions
    start = Time.now
    count = 0

    # get datasets
    dataset_ids = self.datasets.sorted.map{|x| x.dataset_id}

    # get datasets
    datasets = {}
    dataset_ids.each do |dataset_id|
      datasets[dataset_id] = Dataset.find(dataset_id)
    end


    # get existing time series codes for each dataset
    existing = {}
    dataset_ids.each do |dataset_id|
      existing[dataset_id] = self.questions.codes_for_dataset(dataset_id)
      puts "- dataset #{dataset_id} has #{existing[dataset_id].length} codes already on file" 
    end


    # get all codes for each dataset
    all_codes = {}
    dataset_ids.each do |dataset_id|
      all_codes[dataset_id] = datasets[dataset_id].questions.unique_codes_for_analysis
      puts "- dataset #{dataset_id} has #{all_codes[dataset_id].length} codes for analysis" 
    end

    # remove codes that are already matched
    to_compare = {}
    dataset_ids.each do |dataset_id|
      to_compare[dataset_id] = all_codes[dataset_id] - existing[dataset_id]
      puts "- dataset #{dataset_id} has #{to_compare[dataset_id].length} codes to try to match"
    end

    # find matches
    matches = to_compare.values.flatten.group_by{|x| x}.select{|k, v| v.size == dataset_ids.length}.keys
    puts "- found #{matches.length} matches"

    # create record for each match
    matches.each do |code|
      puts "- adding question with code #{code}"
      # create question
      q = self.questions.build
      dataset_ids.each do |dataset_id|
        question = datasets[dataset_id].questions.with_code(code)
        if question.present?
          # if the q record has not been populated, do it
          if q.code.nil?
            q.code = question.code
            q.original_code = question.original_code
            q.text_translations = question.text_translations
            q.notes_translations = question.notes_translations
          end

          q.dataset_questions.build(code: question.code, text_translations: question.text_translations, dataset_id: dataset_id)
        end

      end

      # create answers

      # get unique list of answer values
      values = []
      question_answers = {}
      dataset_ids.each do |dataset_id|
        question_answers[dataset_id] = datasets[dataset_id].questions.with_code(code).answers.all_for_analysis
        values << question_answers[dataset_id].map{|x| x.value}
        puts "- dataset #{dataset_id} has #{question_answers[dataset_id].length} answers"
      end
      # get unique values
      values.flatten!.uniq!.sort!

      # for each value, create a record
      values.each do |value|
        a = q.answers.build
        dataset_ids.each do |dataset_id|
          dataset_answer = question_answers[dataset_id].select{|x| x.value == value}.first

          # create dataset answer record
          if dataset_answer.present?
            # if this is the first found answer, use it to create the answer record 
            if a.value.blank?
              a.value = dataset_answer.value
              a.text = dataset_answer.text
              a.sort_order = dataset_answer.sort_order
              a.can_exclude = dataset_answer.can_exclude
            end

            a.dataset_answers.build(value: dataset_answer.value, text_translations: dataset_answer.text_translations, dataset_id: dataset_id)
          end
        end
      end

      q.save
      count+=1
    end

    puts "added #{count} questions"

    puts "== total time = #{(Time.now - start)} seconds"

    return count
  end


end
