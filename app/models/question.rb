class Question < CustomTranslation

  #############################  Constants
  
  DATA_TYPE_VALUES = { :unknown => 0, :categorical => 1, :numerical => 2 }

  #############################

  include Mongoid::Document

  #############################

  belongs_to :shapeset

  #############################


  # all codes are downcased and '.' are replaced with '|'
  field :code, type: String
  field :original_code, type: String
  field :text, type: String, localize: true
  field :notes, type: String, localize: true
  # whether or not the questions has answers
  field :has_code_answers, type: Boolean, default: false
  # whether or not the questions has answers that can be analzyed
  field :has_code_answers_for_analysis, type: Boolean, default: false
  # whether or not the question should not be included in the analysis
  field :exclude, type: Boolean, default: false
  # whether or not the question is tied to a shapeset
  field :is_mappable, type: Boolean, default: false
  # whether or not the range for the map is fixed at 100 or adjusts to max percent
  field :has_map_adjustable_max_range, type: Boolean, default: false
  # whether or not the question should be included in public download
  field :can_download, type: Boolean, default: false
  # whether or not the answers has a can exclude
  field :has_can_exclude_answers, type: Boolean, default: false
  # which group this question belongs
  field :group_id, type: Moped::BSON::ObjectId
  # number indicating the sort order
  field :sort_order, type: Integer
  # indicate that this question is a weight
  field :is_weight, type: Boolean, default: false
  # question type, possible values = [nil, categorical, numerical]
  field :data_type, type: Integer, default: 0
  # statistics on numerical data_type
  field :descriptive_statistics, type: Object  

  embedded_in :dataset

  embeds_many :answers, cascade_callbacks: true do
    # these are functions that will query the answers documents

    # see if answers have can exclude
    def has_can_exclude?
      where(can_exclude: true).count > 0 ? true : false
    end

    # get the unique answer values
    def unique_values
      only(:values).map{|x| x.value}
    end

    # get the answer that has the provide value
    def with_value(value)
      where(:value => value).first
    end

    # get answers that are not excluded
    def all_for_analysis
      where(:exclude => false)
        .order_by([[:sort_order, :asc], [:text, :asc]])
    end

    # get answers that must be included for analysis
    def must_include_for_analysis
      where(:can_exclude => false, :exclude => false)
        .order_by([[:sort_order, :asc], [:text, :asc]])
    end

    def sorted
      order_by([[:sort_order, :asc], [:text, :asc]])
    end

  end
  accepts_nested_attributes_for :answers, :reject_if => lambda { |x|
    (x[:text_translations].blank? || x[:text_translations].keys.length == 0 || x[:text_translations][x[:text_translations].keys.first].blank?) && x[:value].blank?
    }, :allow_destroy => true

  embeds_one :numerical, class_name: "Numerical", cascade_callbacks: true
  accepts_nested_attributes_for :numerical, :allow_destroy => true
  # , :reject_if => lambda { |x|
  #   (x[:data_type].blank? || x[:data_type] != 2)
  #   }, :allow_destroy => true
  #############################
  # indexes
  # index ({ :code => 1})
  # index ({ :text => 1})
  # index ({ :has_code_answers => 1})
  # index ({ :is_mappable => 1})

  #############################
  attr_accessible :code, :text, :original_code, :has_code_answers, :has_code_answers_for_analysis, :is_mappable, :has_can_exclude_answers, :has_map_adjustable_max_range,
      :answers_attributes, :exclude, :text_translations, :notes, :notes_translations, :group_id, :sort_order, :is_weight, :numerical_attributes

  #############################
  # Validations
  validates_presence_of :code, :original_code
#  validate :validate_translations # can't run this because question text might not exist

  # validate the translation fields
  # text field needs to be validated for presence
  def validate_translations
#    logger.debug "***** validates question translations"
    if self.dataset.default_language.present?
#      logger.debug "***** - default is present; text = #{self.text_translations[self.dataset.default_language]}"
      if self.text_translations[self.dataset.default_language].blank?
#        logger.debug "***** -- text not present!"
        errors.add(:base, I18n.t('errors.messages.translation_default_lang',
            field_name: self.class.human_attribute_name('text'),
            language: Language.get_name(self.dataset.default_language),
            msg: I18n.t('errors.messages.blank')) )
      end
    end
  end


  #############################
  ## override get methods for fields that are localized
  def text
    # if the title is not present, show the code
    x = get_translation(self.text_translations, self.dataset.current_locale, self.dataset.default_language)
    return x.present? ? x : self.original_code
  end
  def notes
    get_translation(self.notes_translations, self.dataset.current_locale, self.dataset.default_language)
  end


  #############################
  # callbacks

  before_save :update_flags
  before_save :check_mappable
  after_save :update_stats
  before_save :check_if_dirty

  def trigger_all_callbacks
    self.update_flags
    self.check_mappable
    self.check_if_dirty(false)
    self.update_stats
  end

  def update_flags
   logger.debug "******** updating question flags for #{self.code}"
    self.has_code_answers = self.answers.count > 0
    self.has_code_answers_for_analysis = self.answers.all_for_analysis.count > 0
    self.has_can_exclude_answers = self.answers.has_can_exclude?

    return true
  end

  # if is_mappable changed, tell the dataset to update its flag
  def check_mappable
    if self.shapeset_id_changed?
      self.is_mappable = self.shapeset_id.present?
      if !self.is_mappable?
        self.has_map_adjustable_max_range = false
      end
      self.dataset.update_mappable_flag
    end
    return true
  end

  # if the exclude flag changes, update the dataset stats
  def update_stats
    logger.debug "@@@@@@@ question update stats"
    if self.exclude_changed?
      self.dataset.update_stats
    end
    return true
  end

  # if the question changed, make sure the dataset.reset_download_files flag is set to true
  # if the only change is to the flags, the donwload does not need to be updated
  def check_if_dirty(save_dataset=true)
    puts "======= question changed? #{self.changed?}; changed: #{self.changed}"
    ignore = [:has_can_exclude_answers, :has_code_answers, :has_code_answers_for_analysis]
    changed = self.changed
    if changed.present?
      # delete the keys we do not care about
      ignore.each{|x| changed.delete(x)}
    end
    if self.changed? && changed.present?
      puts "========== question changed!, setting reset_download_files = true"
      self.dataset.reset_download_files = true
      self.dataset.save if save_dataset
    end
    return true
  end

  #############################

  # create a list of values that are in the data but not an answer value
  def missing_answers
    unique_code_data = self.dataset.data_items.unique_code_data(self.code)
    unique_values = self.answers.unique_values
    if unique_code_data.present?
      return (unique_code_data - unique_values).delete_if{|x| x.nil?}
    else
      return nil
    end
  end


  def code_with_text
    "#{self.original_code} - #{self.text}"
  end

  def group
    self.dataset.groups.find(self.group_id) if self.group_id.present?
  end
  
  # create json for groups
  def json_for_groups(selected=false)
    {
      id: self.id,
      code: self.code,
      original_code: self.original_code,
      text: self.text,
      selected: selected
    }
  end

  # get the weights for this question
  def weights(ignore_id=nil)
    self.dataset.weights.for_question(self.code, ignore_id)
  end

  # get the weight titles for this question
  def weight_titles(ignore_id=nil)
    return weights(ignore_id).map{|x| x.text}
  end
  def unknown_type?
    return data_type == DATA_TYPE_VALUES[:unknown]
  end
  def categorical_type?
    return data_type == DATA_TYPE_VALUES[:categorical]
  end
  def numerical_type?
    return data_type == DATA_TYPE_VALUES[:numerical]
  end
  def has_type?
    return data_type != DATA_TYPE_VALUES[:unknown]
  end
  def data_type_s
    vals = DATA_TYPE_VALUES
    if data_type.is_a? Integer 
      vals.keys.each {|x|
        return x.to_s if vals[x] == data_type
      }
    end
    nil
  end
  def self.type(t)
    vals = Question::DATA_TYPE_VALUES
    if t.is_a? Integer 
      vals.keys.each {|x|
        return x if vals[x] == t 
      }
    elsif t.is_a? Symbol
      return vals[t] if vals.has_key?(t) 
    end
    nil
  end

end
