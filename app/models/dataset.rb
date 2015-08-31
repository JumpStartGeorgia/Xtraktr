class Dataset < CustomTranslation
  require 'process_data_file'
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip
  include Mongoid::Search
  include Mongoid::Slug
  include ProcessDataFile # script in lib folder that will convert datafile to csv and then load into appropriate fields


  #############################

  belongs_to :user

  #############################
  # paperclip data file storage
  has_mongoid_attached_file :datafile, :url => "/system/datasets/:id/original/:filename", :use_timestamp => false
#  has_mongoid_attached_file :codebook, :url => "/system/datasets/:id/codebook/:filename", :use_timestamp => false

  field :title, type: String, localize: true
  field :description, type: String, localize: true
  field :methodology, type: String, localize: true
  field :source, type: String, localize: true
  field :source_url, type: String, localize: true
  field :start_gathered_at, type: Date
  field :end_gathered_at, type: Date
  field :released_at, type: Date
  # whether or not dataset can be shown to public
  field :public, type: Boolean, default: false
  # when made public
  field :public_at, type: Date
  # indicate if questions_with_bad_answers has data
  field :has_warnings, type: Boolean, default: false
  # array of hashes {code1: value1, code2: value2, etc}
#  field :data, type: Array
  # array of question codes who possibly have answer values that are not in the provided list of possible answers
  field :questions_with_bad_answers, type: Array
  # array of question codes that do not have text for question
#  field :questions_with_no_text, type: Array
  # indicates if any questions in this dataset have been connected to a shapeset
  field :is_mappable, type: Boolean, default: false
  # record the extension of the file
  field :file_extension, type: String
  # key to access dataset that is not public
  field :private_share_key, type: String
  field :languages, type: Array
  field :default_language, type: String
  field :reset_download_files, type: Boolean, default: true
  field :force_reset_download_files, type: Boolean, default: false
  field :permalink, type: String

  has_many :category_mappers, dependent: :destroy do
    def category_ids
      pluck(:category_id)
    end
  end
  accepts_nested_attributes_for :category_mappers, reject_if: :all_blank, :allow_destroy => true

  has_many :highlights, dependent: :destroy do
    # get highlight by embed id
    def with_embed_id(embed_id)
      where(embed_id: embed_id).first
    end

    # get embeds id for this dataset
    def embed_ids
      pluck(:embed_id)
    end
  end


  embeds_many :groups, cascade_callbacks: true do
    # get groups that are at the top level (are not sub-groups)
    # if exclude_id provided, remove it from the list
    def main_groups(exclude_id=nil)
      if exclude_id.present?
        where(parent_id: nil).nin(id: exclude_id)
      else
        where(parent_id: nil)
      end
    end

    # get sub-groups of a group
    def sub_groups(parent_id)
      where(parent_id: parent_id)
    end

  end
  accepts_nested_attributes_for :groups

  embeds_many :weights, cascade_callbacks: true do
    # get the default weight
    def default
      where(is_default: true).first
    end

    # get the weight with the question code
    def with_code(code)
      where(code: code).first
    end

    # get all of the weights except for the one passed in
    def get_all_but(id)
      ne(id: id)
    end

    # get the weights for a question
    def for_question(code, ignore_id=nil)
      if ignore_id.present?
        return self.nin(id: ignore_id).or({is_default: true}, {applies_to_all: true}, {:codes.in => [code] })
      else
        return self.or({is_default: true}, {applies_to_all: true}, {:codes.in => [code] })
      end
    end

    # get codes of questions that are being used as weights
    # - if current code is passed in, do not include this code in the list
    def weight_codes(current_code=nil)
      x = only(:code).map{|x| x.code}
      if current_code.present?
        x.delete(current_code)
      end
      return x
    end

  end
  accepts_nested_attributes_for :weights


  embeds_many :questions, cascade_callbacks: true do
    # these are functions that will query the questions documents

    # get the question that has the provided code
    def with_code(code)
      where(:code => code.downcase).first if code.present?
    end

    def text_with_code(code)
      x = only(:title).where(:code => code.downcase).first
      if x.present?
        return x.text
      else
        return nil
      end
    end

    def with_codes(codes)
      any_in(code: codes)
    end

    def not_in_codes(codes)
      nin(:code => codes)
    end

    def for_analysis_not_in_codes(codes)
      nin(:code => codes).where(:exclude => false, :has_code_answers_for_analysis => true)
    end

    def with_original_code(original_code)
      where(:original_code => original_code).first
    end

    # get questions that can be included in download for public
    def for_download
      where(:can_download => true)
    end

    # get questions that are not excluded and have code answers
    def for_analysis
      where(:exclude => false, :has_code_answers_for_analysis => true).to_a
    end

    # get questions that are not excluded and have code answers
    def for_analysis_with_exclude_questions
      where(:has_code_answers_for_analysis => true).to_a
    end

    # get count questions that are not excluded and have code answers
    def for_analysis_count
      where(:exclude => false, :has_code_answers_for_analysis => true).count
    end

    # get all of the questions with code answers
    def with_code_answers
      where(:has_code_answers => true).to_a
    end

    # get all of the questions with no code answers
    def with_no_code_answers
      where(:has_code_answers => false).to_a
    end

    # get all questions with the shapeset_id
    def with_shapeset(shapeset_id)
      where(shapeset_id: shapeset_id)
    end

    # determine if a question has this shapeset
    def has_shapeset?(shapeset_id)
      where(shapeset_id: shapeset_id).count > 0
    end

    def all_answers
      only(:code, :answers)
    end

    # get just the codes
    def unique_codes
      only(:code).map{|x| x.code}
    end

    # get just the codes that can be analyzed
    def unique_codes_for_analysis
      where(:exclude => false, :has_code_answers_for_analysis => true).only(:code).map{|x| x.code}
    end

    # get all questions that are mappable
    def are_mappable
      where(:is_mappable => true)
    end

    # get questions that are not excluded
    def not_excluded
      where(:exlucde => false)
    end

    # mark the question exclude flag as true for the ids provided
    def add_exclude(ids)
      where(:_id.in => ids).each do |q|
        q.exclude = true
      end
      return nil
    end

    # mark the question exclude flag as false for the ids provided
    def remove_exclude(ids)
      where(:_id.in => ids).each do |q|
        q.exclude = false
      end
      return nil
    end

    # mark the question can download flag as true for the ids provided
    def add_can_download(ids)
      where(:_id.in => ids).each do |q|
        q.can_download = true
      end
      return nil
    end

    # mark the question can download flag as false for the ids provided
    def remove_can_download(ids)
      where(:_id.in => ids).each do |q|
        q.can_download = false
      end
      return nil
    end

    # mark the answer exclude flag as true for the ids provided
    def add_answer_exclude(ids)
      map{|x| x.answers}.flatten.select{|x| ids.index(x.id.to_s).present?}.each do |a|
        a.exclude = true
      end
      return nil
    end

    # mark the answer exclude flag as false for the ids provided
    def remove_answer_exclude(ids)
      map{|x| x.answers}.flatten.select{|x| ids.index(x.id.to_s).present?}.each do |a|
        a.exclude = false
      end
      return nil
    end

    # mark the answer can_exclude flag as true for the ids provided
    def add_answer_can_exclude(ids)
      map{|x| x.answers}.flatten.select{|x| ids.index(x.id.to_s).present?}.each do |a|
        a.can_exclude = true
      end
      return nil
    end

    # mark the answer can_exclude flag as false for the ids provided
    def remove_answer_can_exclude(ids)
      map{|x| x.answers}.flatten.select{|x| ids.index(x.id.to_s).present?}.each do |a|
        a.can_exclude = false
      end
      return nil
    end

    # get questions that are mappable
    def mappable
      where(:is_mappable => true, :has_code_answers_for_analysis => true)
    end

    # get questions that are not mappable
    def not_mappable
      where(:is_mappable => false, :has_code_answers_for_analysis => true)
    end

    # get questions that are not assigned to groups
    def not_assigned_group
      where(group_id: nil)
    end

    # get questions that are assigned to a group
    def assigned_to_group(group_id, type='all')
      case type
        when 'download'
          where(group_id: group_id, can_download: true).to_a
        when 'analysis'
          where(group_id: group_id, exclude: false, has_code_answers_for_analysis: true).to_a
        when 'anlysis_with_exclude_questions'
          where(group_id: group_id, has_code_answers_for_analysis: true).to_a
        else
          where(group_id: group_id)
      end
    end

    # get count of questions that are assigned to a group
    def count_assigned_to_group(group_id)
      where(group_id: group_id).count
    end

    # get questions that are not assigned to groups
    # - only get the id, code and title
    def not_assigned_group_meta_only
      where(group_id: nil).only(:id, :code, :original_code, :title, :sort_order)
    end

    # get questions that are assigned to a group
    # - only get the id, code and title
    def assigned_to_group_meta_only(group_id)
      where(group_id: group_id).only(:id, :code, :original_code, :title, :sort_order)
    end

    # set the group id for the provided questions
    def assign_group(ids, group_id)
      where(:_id.in => ids).each do |q|
        if q.group_id != group_id
          q.group_id = group_id
          q.sort_order = nil
        end
      end
      return nil
    end

    # get questions that are not being used as weights and have no answers
    def available_to_be_weights(current_code=nil)
      nin(:code => base.weights.weight_codes(current_code)).where(has_code_answers: false)
    end

    # get questions without code answers and that are not weights
    # - used in time series when selecting question with unique ids
    def available_to_have_unique_ids
      where(has_code_answers: false)
    end

  end
  accepts_nested_attributes_for :questions

  # store the data
  has_many :data_items, dependent: :destroy do
    # these are functions that will query the data_items documents

    # get the data item with this code
    def with_code(code)
      where(:code => code.downcase).first if code.present?
    end

    # get the data array for the provided code
    def code_data(code)
      x = where(:code => code.downcase).first if code.present?
      if x.present?
        return x.data
      else
        return nil
      end
    end

    # get the unique data answers for the provided code
    def unique_code_data(code)
      x = code_data(code)
      if x.present?
        return x.uniq
      else
        return nil
      end
    end
  end
  accepts_nested_attributes_for :data_items

  # reports written based off of this data
  has_many :reports, dependent: :destroy do

    def sorted
      order_by([[:released_at, :desc], [:title, :asc]])
    end

  end
  accepts_nested_attributes_for :reports, :reject_if => :all_blank, :allow_destroy => true

  # mapping of time series to datasets
  has_many :time_series_datasets, dependent: :destroy

  # record stats about this dataset
  has_one :stats, class_name: "Stats", dependent: :destroy
  accepts_nested_attributes_for :stats

  # related files for the dataset
  embeds_one :urls, class_name: 'DatasetFiles', cascade_callbacks: true
  accepts_nested_attributes_for :urls

  #############################

  attr_accessible :title, :description, :methodology, :user_id, :has_warnings,
      :data_items_attributes, :questions_attributes, :reports_attributes, :questions_with_bad_answers,
      :weights_attributes,
      :datafile, :public, :private_share_key, #:codebook,
      :source, :source_url, :start_gathered_at, :end_gathered_at, :released_at,
      :languages, :default_language, :stats_attributes, :urls_attributes,
      :title_translations, :description_translations, :methodology_translations, :source_translations, :source_url_translations,
      :reset_download_files, :force_reset_download_files, :category_mappers_attributes, :category_ids, :permalink, :groups_attributes

  attr_accessor :category_ids, :var_arranged_items, :check_question_exclude_status

  TYPE = {:onevar => 'onevar', :crosstab => 'crosstab'}

  FOLDER_PATH = '/system/datasets'
  JS_FILE = 'shapes.js'
  DOWNLOAD_FOLDER = 'data_download'
  ADMIN_DOWNLOAD_FOLDER = 'complete'

  #############################
  # indexes
  index ({ :title => 1})
  index ({ :released_at => 1})
  index ({ :user_id => 1})
  index ({ :shapeset_id => 1})
  index ({ :public => 1})
  index ({ :public_at => 1})
  index ({ :is_mappable => 1})
  index ({ :'questions.code' => 1})
  index ({ :'questions.original_code' => 1})
  index ({ :'questions.text' => 1})
  index ({ :'questions.is_mappable' => 1})
  index ({ :'questions.can_download' => 1})
  index ({ :'questions.has_code_answers' => 1})
  index ({ :'questions.has_code_answers_for_analysis' => 1})
  index ({ :'questions.exclude' => 1})
  index ({ :'questions.shapeset_id' => 1})
  index ({ :'questions.answers.can_exclude' => 1})
  index ({ :'questions.answers.sort_order' => 1})
  index ({ :'questions.answers.exclude' => 1})
  index ({ :'questions.sort_order' => 1})
  index ({ :'questions.group_id' => 1})
  index ({ :'questions.is_weight' => 1})
  index ({ :private_share_key => 1})
  index ({ :'reports.title' => 1})
  index ({ :'reports.released_at' => 1})
  index ({ :'groups.parent_id' => 1})
  index ({ :'groups.sort_order' => 1})
  index ({ :'weights.is_defualt' => 1})
  index ({ :'weights.applies_to_all' => 1})
  index ({ :'weights.codes' => 1})


  #############################
  # Full text search
  search_in :title, :description, :methodology, :source, :questions => [:original_code, :text, :notes, :answers => [:text]]


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
      d.id.to_s
    end
  end

  #############################
  # Validations
  validates_presence_of :default_language
  # validates_attachment :codebook,
  #     :content_type => { :content_type => ["text/plain", "application/pdf", "application/vnd.oasis.opendocument.text", "application/vnd.openxmlformats-officedocument.wordprocessingml.document", "application/msword"] }
  # validates_attachment_file_name :codebook, :matches => [/txt\Z/i, /pdf\Z/i, /odt\Z/i, /doc?x\Z/i]
  validates_attachment :datafile, :presence => true,
      :content_type => { :content_type => ["application/x-spss-sav", "application/x-stata-dta", "application/octet-stream", "text/csv", "application/vnd.oasis.opendocument.spreadsheet", "application/vnd.ms-excel", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"] }
  validates_attachment_file_name :datafile, :matches => [/sav\Z/i, /dta\Z/i, /csv\Z/i, /ods\Z/i, /xls\Z/i, /xlsx\Z/i]
  validate :validate_languages
  validate :validate_translations
  validate :validate_url

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
  # title and, source field need to be validated for presence
  def validate_translations
    logger.debug "***** validates dataset translations"
    if self.default_language.present?
      logger.debug "***** - default is present; title = #{self.title_translations[self.default_language]}; source = #{self.source_translations[self.default_language]}"
      if self.title_translations[self.default_language].blank?
        logger.debug "***** -- title not present!"
        errors.add(:base, I18n.t('errors.messages.translation_default_lang',
            field_name: self.class.human_attribute_name('title'),
            language: Language.get_name(self.default_language),
            msg: I18n.t('errors.messages.blank')) )
      end
      if self.source_translations[self.default_language].blank?
        logger.debug "***** -- source not present!"
        errors.add(:base, I18n.t('errors.messages.translation_default_lang',
            field_name: self.class.human_attribute_name('source'),
            language: Language.get_name(self.default_language),
            msg: I18n.t('errors.messages.blank')) )
      end
    end
  end

  # have to do custom url validation because validate format with does not work on localized fields
  def validate_url
    self.source_url_translations.keys.each do |key|
      if self.source_url_translations[key].present? && (self.source_url_translations[key] =~ URI::regexp(['http','https'])).nil?
        errors.add(:base, I18n.t('errors.messages.translation_any_lang',
            field_name: self.class.human_attribute_name('source_url'),
            language: Language.get_name(key),
            msg: I18n.t('errors.messages.invalid')) )
        return
      end
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
  def methodology
    get_translation(self.methodology_translations)
  end
  def source
    get_translation(self.source_translations)
  end
  def source_url
    get_translation(self.source_url_translations)
  end


  #############################
  # Callbacks

  after_initialize :set_category_ids
  before_create :process_file
  after_create :create_quick_data_downloads
  before_save :create_urls_object
  before_create :create_private_share_key
  after_destroy :delete_dataset_files
  before_save :update_flags
  after_save :update_stats
  before_save :set_public_at
  before_save :check_if_dirty
  before_save :check_question_excludes


  # when saving mass changes, callbacks in question model not being called so forcing the call here
  def check_question_excludes
    if self.check_question_exclude_status.present? && self.check_question_exclude_status == true
      self.questions.each do |q|
        q.update_flags
        q.update_stats
      end
    end
  end


  # this is used in the form to set the categories
  def set_category_ids
    self.category_ids = self.category_mappers.category_ids
  end

  # process the datafile and save all of the information from it
  def process_file
    process_data_file

    # udpate meta data
    update_flags

    return true
  end

  # create quick data files downloads using csv from processing
  def create_quick_data_downloads
    require 'export_data'
    ExportData.create_all_files(self, true)

    return true
  end

  # create the urls object on create so have place to store urls
  def create_urls_object
    self.build_urls if self.urls.nil?
    return true
  end

  # create private share key that allows people to access this dataset if it is not public
  def create_private_share_key
    if self.private_share_key.blank?
      self.private_share_key = SecureRandom.hex
    end
    return true
  end

  # make sure all of the data files that were generated for this dataset are deleted
  def delete_dataset_files
    path = "#{Rails.public_path}/#{FOLDER_PATH}/#{self.id}"
    FileUtils.rm_r(path) if File.exists?(path)
  end

  def update_flags
    logger.debug "==== update_flags"
    logger.debug "==== - bad answers = #{self.questions_with_bad_answers.present?}; no answers = #{self.questions.with_no_code_answers.present?}; no question text = #{self.no_question_text_count}"
    logger.debug "==== - has_warnings was = #{self.has_warnings}"
    self.has_warnings = self.questions_with_bad_answers.present? ||
                        self.questions.with_no_code_answers.present? ||
                        self.no_question_text_count > 0

    logger.debug "==== - has_warnings = #{self.has_warnings}"

    return true
  end

  def update_stats
    logger.debug "==== update stats"

    self.build_stats if self.stats.nil?

    # how many questions can be analyzed
    self.stats.questions_analyzable = self.questions.for_analysis_count

    # how many questions can be analyzed if dataset is public
    self.stats.public_questions_analyzable = self.public? ? self.questions.for_analysis_count : 0

    # how many questions have answers
    self.stats.questions_good = self.questions.nil? ? 0 : self.questions.with_code_answers.length

    # how many questions don't have answers
    self.stats.questions_no_answers = self.questions.nil? ? 0 : self.questions.with_no_code_answers.length

    # how many questions don't have text
    self.stats.questions_no_text = self.no_question_text_count

    # how many questions have bad answers
    self.stats.questions_bad_answers = self.questions_with_bad_answers.nil? ? 0 : self.questions_with_bad_answers.length
    # how many data records
    self.stats.data_records = self.data_items.blank? ? 0 : self.data_items.first.data.length

    self.stats.save

    return true
  end

  # this is called from an embeded question if the is_mappable value changed in that question
  def update_mappable_flag
    logger.debug "==== question mappable = #{self.questions.index{|x| x.is_mappable == true}.present?}"
    self.is_mappable = self.questions.index{|x| x.is_mappable == true}.present?

    # if this dataset is mappable, create the js file with the geojson in it
    # else, delete the js file
    if self.is_mappable?
      logger.debug "=== creating js file"

      # make sure the urls object exists
      create_urls_object

      # create hash of shapes in format: {code => geojson, code => geojson}
      shapes = {}
      self.questions.are_mappable.each do |question|
        shapes[question.code] = question.shapeset.get_geojson
      end

      # write geojson to file
      File.open(js_shapefile_file_path, 'w') do |f|
        f << "var highmap_shapes = " + shapes.to_json
      end

      # now compress the file so browsers will use it
      # from: http://stackoverflow.com/a/24497338
      Zlib::GzipWriter.open(js_gz_shapefile_file_path) do |gz|
        File.open(js_shapefile_file_path, 'rb') do |f|
         while chunk = f.read(16*1024) do
           gz.write chunk
         end
        end
        gz.close
      end

      # record the shape file url
      self.urls.shape_file = js_shapefile_url_path

    else
      # delete js file
      logger.debug "==== deleting shape js file at #{js_shapefile_file_path}"
      FileUtils.rm js_shapefile_file_path if File.exists?(js_shapefile_file_path)
      FileUtils.rm js_gz_shapefile_file_path if File.exists?(js_gz_shapefile_file_path)

      # remove the shape file url
      self.urls.shape_file = nil

    end

    self.save

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
    return true
  end

  # if the dataset changed, make sure the reset_download_files flag is set to true
  # if change is only reset_download_files and reset_download_files = false, do nothing
  def check_if_dirty
    logger.debug "======= dataset changed? #{self.changed?}; changed: #{self.changed}"
    logger.debug "======= languages changed? #{self.languages_changed?}; change: #{self.languages_change}"
    logger.debug "======= reset_download_files changed? #{self.reset_download_files_changed?} change: #{self.reset_download_files_change}"
    if self.changed? && !(self.changed.include?('reset_download_files') && self.reset_download_files == false)
      logger.debug "========== dataset changed!, setting reset_download_files = true"
      self.reset_download_files = true
    end
    return true
  end


  #############################
  # Scopes

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

  def self.sorted_released_at
    order_by([[:released_at, :desc], [:title, :asc]])
  end

  def self.categorize(cat)
    cat = Category.find_by(permalink: cat)
    if cat.present?
      self.in(id: CategoryMapper.where(category_id: cat.id).pluck(:dataset_id))
    else
      all
    end
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

  # get the status of the download files
  def self.download_files_up_to_date?(id, user_id)
    x = by_user(user_id).only(:reset_download_files).find(id)
    if x.present?
      return !x.reset_download_files?
    else
      return true
    end
  end


  def self.only_id_title_languages
    only(:id, :title, :languages)
  end

  def self.meta_only
    without(:questions)
  end

  def self.get_slug(id)
    x = only(:_slugs).find(id)
    x.present? ? x.slug : nil
  end

  def self.only_id_title_description
    only(:id, :title, :description)
  end

  # get all datasets that are mappable
  def self.are_mappable
    where(is_mappable: true)
  end

  def self.with_shapeset(shapeset_id)
    ds = []
    x = are_mappable
    if x.present?
      x.each do |dataset|
        if dataset.questions.has_shapeset?(shapeset_id)
          ds << dataset
        end
      end
    end
    return ds
  end

  # get the datasets that are missing download files or needs to have their files recreated due to changes
  def self.needs_download_files
    self.or({:reset_download_files => true}, {:urls.exists => false}, {:'urls.codebook'.exists => false})
  end

  # get the datasets that have been requested to generate download files now
  def self.needs_download_files_now
    self.where({:force_reset_download_files => true})
  end

  # get the shape file url
  def self.shape_file_url(dataset_id)
    url = nil
    x = only('urls.shape_file').find(dataset_id)
    url = x.urls.shape_file if x.present?

    return url
  end


  # get the groups and questions in sorted order
  # options:
  # - question_type - type of questions to get (download, analysis, anlysis_with_exclude_questions, or all)
  # - reload_items - if items already exist, reload them (default = false)
  # - group_id - arrange the groups/questions that are in this group_id
  # - include_groups - flag indicating if should get groups (default = false)
  # - include_subgroups - flag indicating if subgroups should also be loaded (default = false)
  # - include_questions - flag indicating if should get questions (default = false)
  # - include_group_with_no_items - flag indicating if should include groups even if it has no items, possibly due to other flags (default = false)
  def arranged_items(options={})
    Rails.logger.debug "@@@@@@@@@@@@@@ dataset arranged_items"
    if self.var_arranged_items.nil? || self.var_arranged_items.empty? || options[:reload_items]
      Rails.logger.debug "@@@@@@@@@@@@@@ - building, options = #{options}"
      self.var_arranged_items = build_arranged_items(options)
    end

    return self.var_arranged_items
  end

  # returnt an array of sorted gruops and questions, that match the provided options
  # options:
  # - question_type - type of questions to get (download, analysis, anlysis_with_exclude_questions, or all)
  # - group_id - arrange the groups/questions that are in this group_id
  # - include_groups - flag indicating if should get groups (default = false)
  # - include_subgroups - flag indicating if subgroups should also be loaded (default = false)
  # - include_questions - flag indicating if should get questions (default = false)
  # - include_group_with_no_items - flag indicating if should include groups even if it has no items, possibly due to other flags (default = false)
  def build_arranged_items(options={})
    Rails.logger.debug "=============== build start; options = #{options}"
    indent = options[:group_id].present? ? '    ' : ''
    Rails.logger.debug "#{indent}^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
    Rails.logger.debug "#{indent}=============== build start; options = #{options}"
    items = []

    if options[:include_groups] == true
      Rails.logger.debug "#{indent}=============== -- include groups"
      # get the groups
      # - if group id provided, get subgroups in that group
      # - else get main groups
      groups = []
      if options[:group_id].present?
        groups << self.groups.sub_groups(options[:group_id])
      else
        groups << self.groups.main_groups
      end
      groups.flatten!

      # if a group has items, add it
      group_options = options.dup
      group_options[:include_groups] = options[:include_subgroups] == true
      groups.each do |group|
        Rails.logger.debug "#{indent}>>>>>>>>>>>>>>> #{group.title}"
        Rails.logger.debug "#{indent}=============== checking #{group.title} for subgroups"

        # get all items for this group (subgroup/questions)
        group_options[:group_id] = group.id
        group.var_arranged_items = build_arranged_items(group_options)
        # only add the group if it has content
        if group.var_arranged_items.present? || options[:include_group_with_no_items] == true
          items << group
          Rails.logger.debug "#{indent}>>>>>>>>>>>>>> ----- added #{group.var_arranged_items.length} items for #{group.title}"
        end

      end
    end

    if options[:include_questions] == true
      Rails.logger.debug "#{indent}=============== -- include questions"
      # get questions that are assigned to groups
      # - if group_id not provided, then getting questions that are not assigned to group
      items << case options[:question_type]
        when 'download'
          self.questions.where(:can_download => true, :group_id => options[:group_id])
        when 'analysis'
          self.questions.where(:exclude => false, :has_code_answers_for_analysis => true, :group_id => options[:group_id])
        when 'anlysis_with_exclude_questions'
          self.questions.where(:has_code_answers_for_analysis => true, :group_id => options[:group_id])
        else
          self.questions.where(:group_id => options[:group_id])
      end
    end

    items.flatten!

    Rails.logger.debug "#{indent}=============== there are a total of #{items.length} items added"


    # sort these items
    # way to sort: sort only items that have sort_order, then add groups with no sort_order, then add questions with no sort_order
    items = items.select{|x| x.sort_order.present?}.sort_by{|x| x.sort_order} +
              items.select{|x| x.class == Group && x.sort_order.nil?} +
              items.select{|x| x.class == Question && x.sort_order.nil?}


    return items
  end

  #############################
  ## paths to dataset related files

  # get the js shape file path
  def js_shapefile_file_path
    "#{Rails.public_path}/#{FOLDER_PATH}/#{self.id}/#{JS_FILE}"
  end

  def js_gz_shapefile_file_path
    "#{Rails.public_path}/#{FOLDER_PATH}/#{self.id}/#{JS_FILE}.gz"
  end

  def js_shapefile_url_path
    "#{FOLDER_PATH}/#{self.id}/#{JS_FILE}"
  end

  def data_download_path
    "#{FOLDER_PATH}/#{self.id}/#{DOWNLOAD_FOLDER}"
  end

  def data_download_staging_path
    "#{FOLDER_PATH}/#{self.id}/#{DOWNLOAD_FOLDER}/staging"
  end

  def admin_data_download_path
    "#{FOLDER_PATH}/#{self.id}/#{DOWNLOAD_FOLDER}/#{ADMIN_DOWNLOAD_FOLDER}"
  end

  def admin_data_download_staging_path
    "#{FOLDER_PATH}/#{self.id}/#{DOWNLOAD_FOLDER}/#{ADMIN_DOWNLOAD_FOLDER}/staging"
  end

  #############################

  def categories
    Category.in(id: self.category_mappers.map {|x| x.category_id } ).to_a
  end

  def is_weighted?
    self.weights.present?
  end

  # get list of quesitons with no text
  def questions_with_no_text
    self.questions.select{|x| x.text_translations[self.default_language] == nil}
  end

  # get count of quesitons with no text
  def no_question_text_count
    questions_with_no_text.length
  end

  # indicate the file type based off of the file extension
  def file_type
    case self.file_extension
    when 'csv'
      'CSV'
    when 'xls'
      'XLS'
    when 'dta'
      'STATA'
    when 'sav'
      'SPSS'
    else
      ''
    end
  end


  #############################

  # assign a question to a shapeset
  # - question_id - id of question to update
  # - shapeset_id - id of shapeset to assign
  # - mappings - array of arrays containing answer id and shape name
  # - has_map_adjustable_max_range - flag indicating if question map has adjustable range
  #   - [ [id, name], [id, name], ... ]
  def map_question_to_shape(question_id, shapeset_id, mappings, has_map_adjustable_max_range=false)
    logger.debug "====== map_question_to_shape start"
    success = false
    # get the question
    q = self.questions.find_by(id: question_id)

    if q.present?
      logger.debug "====== found question"
      # set the shapeset
      q.shapeset_id = shapeset_id
      # set the max range flag
      q.has_map_adjustable_max_range = has_map_adjustable_max_range

      # set the shape name for each answer
      logger.debug "====== #{mappings.length} mappings"
      mappings.each do |mapping|
        logger.debug "====== mapping = #{mapping}"
        # find answer
        a = q.answers.find_by(id: mapping[0])

        logger.debug "====== found answer = #{a.present?}"

        # assign name
        a.shape_name = mapping[1] if a.present?
      end

      # save
      success = q.save
    end

    logger.debug "====== success = #{success}"

    return success
  end

  # remove all map settings for this question
  def remove_question_shape_mapping(question_id)
    success = false
    # get the question
    q = self.questions.find_by(id: question_id)

    if q.present?
      # reset shape id
      q.shapeset_id = nil

      # reset shape name for each answer
      q.answers.each do |answer|
        answer.shape_name = nil
      end

      # save
      success = q.save
    end

    return success
  end


  ##################################
  ##################################
  ## CSV upload and download
  ##################################
  ##################################
  QUESTION_HEADERS={code: 'Question Code', question: 'Question', exclude: 'Exclude Question from Analysis (leave blank to show question)'}
  # create csv to download questions
  # columns: code, text (for each translation), exclude
  def generate_questions_csv
    csv_data = CSV.generate do |csv|
      # create header for csv
      header = [QUESTION_HEADERS[:code]]
      locales = self.languages_sorted
      locales.each do |locale|
        header << "#{QUESTION_HEADERS[:question]} (#{locale})"
      end
      header << QUESTION_HEADERS[:exclude]
      csv << header

      # add questions
      self.questions.each do |question|
        row = [question.original_code]
        locales.each do |locale|
          if question.text_translations[locale].present?
            row << question.text_translations[locale]
          else
            row << ''
          end
        end
        row << (question.exclude == true ? 'Y' : nil)
        csv << row
      end
    end

    return csv_data
  end


  # create csv to download answers
  # columns: code, value, text (for each translation), exclude, can exclude
  ANSWER_HEADERS={code: 'Question Code', value: 'Value', sort: 'Sort Order', answer: 'Answer', exclude: 'Exclude Answer from Analysis (leave blank to show answer)', can_exclude: 'Can Exclude During Analysis (leave blank to always show answer)'}
  def generate_answers_csv
    csv_data = CSV.generate do |csv|
      # create header for csv
      header = [ANSWER_HEADERS[:code], ANSWER_HEADERS[:value], ANSWER_HEADERS[:sort]]
      locales = self.languages_sorted
      locales.each do |locale|
        header << "#{ANSWER_HEADERS[:answer]} (#{locale})"
      end
      header << [ANSWER_HEADERS[:exclude], ANSWER_HEADERS[:can_exclude]]
      csv << header.flatten

      # add questions
      self.questions.with_code_answers.each do |question|
        question.answers.sorted.each do |answer|
          row = [question.original_code]
          row << answer.value
          row << answer.sort_order
          locales.each do |locale|
            if answer.text_translations[locale].present?
              row << answer.text_translations[locale]
            else
              row << ''
            end
          end
          row << (answer.exclude == true ? 'Y' : nil)
          row << (answer.can_exclude == true ? 'Y' : nil)
          csv << row
        end
      end
    end

    return csv_data
  end


  # read in the csv and update the question text as necessary
  def process_questions_csv(file)
    start = Time.now
    infile = file.read
    n, msg = 0, ""
    locales = self.languages_sorted
    orig_locale = I18n.locale

    # to indicate where the columns are in the csv doc
    indexes = Hash[locales.map{|x| [x,nil]}]
    indexes['code'] = nil
    indexes['exclude'] = nil

    # create counter to see how many items in each locale changed
    counts = Hash[locales.map{|x| [x,0]}]
    counts['overall'] = 0

    CSV.parse(infile) do |row|
      startRow = Time.now
      n += 1
      puts "@@@@@@@@@@@@@@@@@@ processing row #{n}"

      if n == 1
        foundAllHeaders = false
        # look at headers and set indexes
        # - doing this in case the user re-arranged the columns
        # if header in csv is not known, throw error

        # code
        idx = row.index(QUESTION_HEADERS[:code])
        indexes['code'] = idx if idx.present?
        # exclude
        idx = row.index(QUESTION_HEADERS[:exclude])
        indexes['exclude'] = idx if idx.present?

        # text translations
        locales.each do |locale|
          idx = row.index("#{QUESTION_HEADERS[:question]} (#{locale})")
          indexes[locale] = idx if idx.present?
        end

        if !indexes.values.include?(nil)
          # found all columns, so can stop
          foundAllHeaders = true
        end

        if !foundAllHeaders
            msg = I18n.t('mass_uploads_msgs.bad_headers')
            puts "@@@@@@@@@@> #{msg}"
          return msg
        end

        puts "%%%%%%%%%% col indexes = #{indexes}"

      else
        # get question for this row
        question = self.questions.with_original_code(row[indexes['code']])
        if question.nil?
          msg = I18n.t('mass_uploads_msgs.missing_code', n: n, code: row[indexes['code']])
          puts "@@@@@@@@@@> #{msg}"
          return msg
        end


        # if value exist for exclude, assume it means true
        question.exclude = row[indexes['exclude']].present?

        locale_found = false
        locales.each do |locale|
          # if question text is provided and not the same, update it
          I18n.locale = locale.to_sym
          if row[indexes[locale]].present? && question.text != row[indexes[locale]].strip
            puts "- setting text for #{locale}"
            question.text = clean_string(row[indexes[locale]].strip)
            counts[locale] += 1
            locale_found = true
          end
        end
        counts['overall'] += 1 if locale_found

        puts "---> question.valid = #{question.valid?}"

        puts "******** time to process row: #{Time.now-startRow} seconds"
        puts "************************ total time so far : #{Time.now-start} seconds"
      end
    end

    puts "=========== valid = #{self.valid?}; errors = #{self.errors.full_messages}"

    success = self.save

    puts "=========== success save = #{success}"

    puts "****************** total changes: #{counts.map{|k,v| k + ' - ' + v.to_s}.join(', ')}"
    puts "****************** time to process question csv: #{Time.now-start} seconds for #{n} rows"

    I18n.locale = orig_locale

    return msg, counts
  end



  # read in the csv and update the answer text as necessary
  def process_answers_csv(file)
    start = Time.now
    infile = file.read
    n, msg = 0, ""
    locales = self.languages_sorted
    last_question_code = nil
    question = nil
    orig_locale = I18n.locale

    # to indicate where the columns are in the csv doc
    indexes = Hash[locales.map{|x| [x,nil]}]
    indexes['code'] = nil
    indexes['value'] = nil
    indexes['sort_order'] = nil
    indexes['exclude'] = nil
    indexes['can_exclude'] = nil

    # create counter to see how many items in each locale changed
    counts = Hash[locales.map{|x| [x,0]}]
    counts['overall'] = 0

    CSV.parse(infile.force_encoding('utf-8')) do |row|
      startRow = Time.now
      # translation_changed = false
      n += 1
      puts "@@@@@@@@@@@@@@@@@@ processing row #{n}"

      if n == 1
        foundAllHeaders = false
        # look at headers and set indexes
        # - doing this in case the user re-arranged the columns
        # if header in csv is not known, throw error

        # code
        idx = row.index(ANSWER_HEADERS[:code])
        indexes['code'] = idx if idx.present?
        # value
        idx = row.index(ANSWER_HEADERS[:value])
        indexes['value'] = idx if idx.present?
        # sort_order
        idx = row.index(ANSWER_HEADERS[:sort])
        indexes['sort_order'] = idx if idx.present?
        # exclude
        idx = row.index(ANSWER_HEADERS[:exclude])
        indexes['exclude'] = idx if idx.present?
        # can exclude
        idx = row.index(ANSWER_HEADERS[:can_exclude])
        indexes['can_exclude'] = idx if idx.present?

        # text translations
        locales.each do |locale|
          idx = row.index("#{ANSWER_HEADERS[:answer]} (#{locale})")
          indexes[locale] = idx if idx.present?
        end

        if !indexes.values.include?(nil)
          # found all columns, so can stop
          foundAllHeaders = true
        end

        if !foundAllHeaders
            msg = I18n.t('mass_uploads_msgs.bad_headers')
          return msg
        end

        puts "%%%%%%%%%% col indexes = #{indexes}"

      else
        ########################
        # have to save the question and all of its answers
        # if try to just save an answer, mongoid uses incorrect index for question
        ########################

        # if the question is different, save the previous question before moving on to the new question
        if last_question_code != row[indexes['code']]
          # get question for this row
          question = self.questions.with_original_code(row[indexes['code']])
          if question.nil?
            msg = I18n.t('mass_uploads_msgs.missing_code', n: n, code: row[indexes['code']])
            return msg
          end
        end

        # get answer for this row
        answer = question.answers.with_value(row[indexes['value']])
        if answer.nil?
          msg = I18n.t('mass_uploads.answers.missing_answer', n: n, code: row[indexes['code']], value: row[indexes['value']])
          return msg
        end


        # if value exist for exclude, assume it means true
        answer.sort_order = row[indexes['sort_order']]
        answer.exclude = row[indexes['exclude']].present?
        answer.can_exclude = row[indexes['can_exclude']].present?

        # temp_text = answer.text_translations.dup
        locale_found = false
        locales.each do |locale|
          I18n.locale = locale.to_sym
          # if answer text is provided and not the same, update it
          if row[indexes[locale]].present? && answer.text != row[indexes[locale]].strip
            puts "- setting text for #{locale}"
            # question.text_will_change!
            answer.text = clean_string(row[indexes[locale]].strip)
            counts[locale] += 1
            locale_found = true
          end
        end
        counts['overall'] += 1 if locale_found

        puts "******** time to process row: #{Time.now-startRow} seconds"
        puts "************************ total time so far : #{Time.now-start} seconds"
      end
    end

    puts "=========== valid = #{self.valid?}; errors = #{self.errors.full_messages}"

    self.save

    puts "****************** total changes: #{counts.map{|k,v| k + ' - ' + v.to_s}.join(', ')}"
    puts "****************** time to process answer csv: #{Time.now-start} seconds for #{n} rows"

    I18n.locale = orig_locale

    return msg, counts
  end

end
