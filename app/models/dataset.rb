class Dataset < CustomTranslation
  require 'process_data_file'
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip
  include Mongoid::Search
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

  embeds_many :questions, cascade_callbacks: true do
    # these are functions that will query the questions documents

    # get the question that has the provided code
    def with_code(code)
      where(:code => code.downcase).first
    end

    def with_codes(codes)
      where(:code => codes)
    end

    def not_in_codes(codes)
      nin(:code => codes)
    end

    def for_analysis_not_in_codes(codes)
      nin(:code => codes).where(:exclude => false, :has_code_answers => true)
    end

    def with_original_code(original_code)
      where(:original_code => original_code).first
    end

    # get questions that are not excluded and have code answers
    def for_analysis
      where(:exclude => false, :has_code_answers => true).to_a
    end

    # get count questions that are not excluded and have code answers
    def for_analysis_count
      where(:exclude => false, :has_code_answers => true).count
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
      where(:exclude => false, :has_code_answers => true).only(:code).map{|x| x.code}
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
      where(:is_mappable => true, :has_code_answers => true)
    end

    # get questions that are not mappable
    def not_mappable
      where(:is_mappable => false, :has_code_answers => true)
    end

  end
  accepts_nested_attributes_for :questions

  # store the data
  has_many :data_items, dependent: :destroy do
    # these are functions that will query the data_items documents

    # get the data item with this code
    def with_code(code)
      where(:code => code.downcase).first
    end

    # get the data array for the provided code
    def code_data(code)
      x = where(:code => code.downcase).first
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
      :datafile, :public, :private_share_key, #:codebook,
      :source, :source_url, :start_gathered_at, :end_gathered_at, :released_at,
      :languages, :default_language, :stats_attributes, :urls_attributes,
      :title_translations, :description_translations, :methodology_translations, :source_translations, :source_url_translations,
      :reset_download_files, :category_mappers_attributes, :category_ids

  attr_accessor :category_ids

  TYPE = {:onevar => 'onevar', :crosstab => 'crosstab'}

  FOLDER_PATH = '/system/datasets'
  JS_FILE = 'shapes.js'
  DOWNLOAD_FOLDER = 'data_download'

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
  index ({ :'questions.has_code_answers' => 1})
  index ({ :'questions.exclude' => 1})
  index ({ :'questions.shapeset_id' => 1})
  index ({ :'questions.answers.can_exclude' => 1})
  index ({ :'questions.answers.sort_order' => 1})
  index ({ :'questions.answers.exclude' => 1})
  index ({ :private_share_key => 1})
  index ({ :'reports.title' => 1})
  index ({ :'reports.released_at' => 1})


  #############################
  # Full text search
  search_in :title, :description, :methodology, :source, :questions => [:original_code, :text, :notes, :answers => [:text]]

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
    where(id: id).by_user(user_id).first
  end

  def self.only_id_title_languages
    only(:id, :title, :languages)
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

  # get the shape file url
  def self.shape_file_url(dataset_id)
    url = nil
    x = only('urls.shape_file').find(dataset_id)
    url = x.urls.shape_file if x.present?

    return url
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

  #############################

  def categories
    Category.in(id: self.category_mappers.map {|x| x.category_id } ).to_a
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
  #   - [ [id, name], [id, name], ... ]
  def map_question_to_shape(question_id, shapeset_id, mappings)
    logger.debug "====== map_question_to_shape start"
    success = false
    # get the question
    q = self.questions.find_by(id: question_id)

    if q.present?
      logger.debug "====== found question"
      # set the shapeset
      q.shapeset_id = shapeset_id

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

  # #############################
  # #############################
  # ## Data analysis
  # #############################
  # #############################

  # ### perform a summary analysis of one question_code in
  # ### the data_items
  # ### - question_code: code of question to analyze and put along row of crosstab
  # # - options:
  # #   - filter: if provided, indicates a field and value to filter the data by
  # #           format: {code: ____, value: ______}
  # #   - exclude_dkra: flag indicating if don't know/refuse to answer answers should be ignored
  # def data_onevar_analysis(question_code, options={})
  #   start = Time.now

  #   filter = options[:filter]
  #   exclude_dkra = options[:exclude_dkra] == true
  #   logger.debug "//////////// data_onevar_analysis - question_code: #{question_code}, filter: #{filter}, exclude_dkra: #{exclude_dkra}"

  #   result = {}

  #   # get the question/answers
  #   result[:row_code] = question_code
  #   row_question = self.questions.with_code(question_code)
  #   result[:row_question] = row_question.text
  #   # if exclude_dkra is true, only get use the answers that cannot be excluded
  #   result[:row_answers] = exclude_dkra == true ? row_question.answers.must_include_for_analysis : row_question.answers.all_for_analysis
  #   result[:type] = TYPE[:onevar]
  #   result[:counts] = []
  #   result[:percents] = []
  #   result[:total_responses] = nil
  #   result[:chart] = {}

  #   # if the row question/answers were found, continue
  #   if result[:row_question].present? && result[:row_answers].present?

  #     # get the data for this code
  #     data = self.data_items.code_data(question_code)

  #     # if filter provided, then get data for filter
  #     # and then only pull out the code data that matches
  #      if filter.present?
  #       filter_data = self.data_items.code_data(filter[:code])
  #       if filter_data.present?
  #         # merge the data and filter
  #         # and then pull out the data that has the corresponding filter value
  #         merged_data = filter_data.zip(data)
  #         data = merged_data.select{|x| x[0].to_s == filter[:value].to_s}.map{|x| x[1]}
  #       end
  #     end

  #     if data.present?
  #       # do not want to count nil values
  #       counts =  data.select{|x| x.present?}
  #                 .each_with_object(Hash.new(0)) { |item,counts| counts[item.to_s] += 1 }

  #       logger.debug "== total time to get counts = #{(Time.now - start)*1000} ms"

  #       # now put it all together

  #       # - create counts
  #       result[:row_answers].each do |row_answer|
  #         # look for count for this row answer
  #         count = counts[row_answer.value.to_s]
  #         if count.present?
  #           result[:counts] << count
  #         else
  #           result[:counts] << 0
  #         end
  #       end

  #       # - take counts and turn into percents
  #       total = result[:counts].inject(:+)
  #       # if total is 0, then set percent to 0
  #       if total == 0
  #         result[:percents] = Array.new(result[:counts].length){0}
  #       else
  #         result[:counts].each do |count_item|
  #           result[:percents] << (count_item.to_f/total*100).round(2)
  #         end
  #       end

  #       # - record the total number of responses
  #       result[:total_responses] = result[:counts].inject(:+).to_i

  #       # - format data for charts
  #       # pie chart requires data to be in following format:
  #       # [ {name, y, count, answer_value}, {name, y, count, answer_value}, ...]
  #       result[:chart][:data] = []
  #       (0..result[:row_answers].length-1).each do |index|
  #         result[:chart][:data] << {
  #           name: result[:row_answers][index].text,
  #           y: result[:percents][index],
  #           count: result[:counts][index],
  #           answer_value: result[:row_answers][index].value
  #         }
  #       end

  #       # - if row is a mappable variable, create the map data
  #       if row_question.is_mappable?
  #         result[:map] = {}
  #         result[:map][:data] = []
  #         result[:map][:question_code] = question_code

  #         result[:row_answers].each_with_index do |row_answer, row_index|
  #           # store in highmaps format: {shape_name, display_name, value, count}
  #           result[:map][:data] << {:shape_name => row_answer.shape_name, :display_name => row_answer.text, :value => result[:percents][row_index], :count => result[:counts][row_index]}
  #         end
  #       end

  #     end
  #   end

  #   logger.debug "== total time = #{(Time.now - start)*1000} ms"
  #   return result
  # end


  # ### perform a crosstab analysis between two question codes in data_items
  # ### - question_code1: code of question to analyze and put along row of crosstab
  # ### - question_code2: code of question to analyze and put along columns of crosstab
  # def data_crosstab_analysis(question_code1, question_code2, options={})
  #   start = Time.now

  #   filter = options[:filter]
  #   exclude_dkra = options[:exclude_dkra] == true
  #   logger.debug "//////////// data_crosstab_analysis - question_code1: #{question_code1}, question_code2: #{question_code2}, filter: #{filter}, exclude_dkra: #{exclude_dkra}"

  #   result = {}

  #   # get the question/answers
  #   result[:row_code] = question_code1
  #   row_question = self.questions.with_code(question_code1)
  #   result[:row_question] = row_question.text
  #   # if exclude_dkra is true, only get use the answers that cannot be excluded
  #   result[:row_answers] = exclude_dkra == true ? row_question.answers.must_include_for_analysis : row_question.answers.all_for_analysis
  #   result[:column_code] = question_code2
  #   col_question = self.questions.with_code(question_code2)
  #   result[:column_question] = col_question.text
  #   # if exclude_dkra is true, only get use the answers that cannot be excluded
  #   result[:column_answers] = exclude_dkra == true ? col_question.answers.must_include_for_analysis : col_question.answers.all_for_analysis
  #   result[:type] = TYPE[:crosstab]
  #   result[:counts] = []
  #   result[:percents] = []
  #   result[:total_responses] = nil
  #   result[:chart] = {}

  #   # if the row and col question/answers were found, continue
  #   if result[:row_question].present? && result[:row_answers].present? && result[:column_question].present? && result[:column_answers].present?
  #     # get uniq values
  #     row_answers = result[:row_answers].map{|x| x.value}.sort
  #     col_answers = result[:column_answers].map{|x| x.value}.sort
  #     logger.debug "unique row answers = #{row_answers}"
  #     logger.debug "unique col answers = #{col_answers}"

  #     # get the values for the codes from the data
  #     data1 = self.data_items.code_data(question_code1)
  #     data2 = self.data_items.code_data(question_code2)

  #     row_items = data1.uniq
  #     col_items = data2.uniq

  #     logger.debug "uniq row items = #{row_items}"
  #     logger.debug "uniq col items = #{col_items}"

  #     # merge the data arrays into one array that
  #     # has nested arrays
  #     data = data1.zip(data2)

  #    # if filter provided, then get data for filter
  #     # and then only pull out the code data that matches
  #      if filter.present?
  #       filter_data = self.data_items.code_data(filter[:code])
  #       if filter_data.present?
  #         # merge the data and filter
  #         # and then pull out the data that has the corresponding filter value
  #         merged_data = filter_data.zip(data)
  #         data = merged_data.select{|x| x[0].to_s == filter[:value].to_s}.map{|x| x[1]}
  #       end
  #     end

  #     counts = {}

  #     # for each existing row answer
  #     row_items.each do |row_item|
  #       # do not process nil values
  #       if row_item.present?
  #         # get the col values that exist with this answer
  #         # and then count how many times each appears
  #         # do not process nil values for x[1]
  #         counts[row_item.to_s] = data.select{|x| x[0] == row_item && x[1].present?}.map{|x| x[1]}
  #                                   .each_with_object(Hash.new(0)) { |item,counts| counts[item.to_s] += 1 }
  #       end
  #     end

  #     logger.debug "== total time to get data = #{(Time.now - start)*1000} ms"

  #     if counts.present?
  #       # now put it all together

  #       # - create counts
  #       result[:row_answers].each do |r|
  #         data_row = []
  #         row_counts = counts[r.value.to_s]
  #         if row_counts.present?
  #           result[:column_answers].each do |c|
  #             col_count = row_counts[c.value.to_s]
  #             if col_count.present?
  #               data_row << col_count
  #             else
  #               data_row << 0
  #             end
  #           end
  #         else
  #           data_row = Array.new(result[:column_answers].length){0}
  #         end
  #         result[:counts] << data_row
  #       end

  #       # - take counts and turn into percents
  #       totals = []
  #       logger.debug "counts = \n #{result[:counts]}"
  #       result[:counts].each do |count_row|
  #         total = count_row.inject(:+)
  #         logger.debug " - row total = #{total}"
  #         totals << total
  #         if total > 0
  #           percent_row = []
  #           count_row.each do |item|
  #             percent_row << (item.to_f/total*100).round(2)
  #           end
  #           result[:percents] << percent_row
  #         else
  #           result[:percents] << Array.new(count_row.length){0}
  #         end
  #       end
  #       logger.debug "----------"
  #       logger.debug " - totals = #{totals}"
  #       logger.debug " - total = #{totals.inject(:+).to_i}"

  #       # - record the total number of responses
  #       result[:total_responses] = totals.inject(:+).to_i

  #       # - format data for charts
  #       result[:chart][:labels] = result[:row_answers].map{|x| x.text}
  #       result[:chart][:data] = []
  #       counts = result[:counts].transpose

  #       (0..result[:column_answers].length-1).each do |index|
  #         item = {}
  #         item[:name] = result[:column_answers][index].text
  #         item[:data] = counts[index]
  #         result[:chart][:data] << item
  #       end

  #       # - if row or column is a mappable variable, create the map data
  #       if row_question.is_mappable? || col_question.is_mappable?
  #         result[:map] = {}
  #         result[:map][:data] = {}

  #         # if the row is the mappable, recompute percents so columns add up to 100%
  #         if row_question.is_mappable?
  #           result[:map][:question_code] = question_code1
  #           result[:map][:filter] = col_question.text
  #           result[:map][:filters] = result[:column_answers]

  #           counts = result[:counts].transpose
  #           percents = []
  #           counts.each do |count_row|
  #             total = count_row.inject(:+)
  #             if total > 0
  #               percent_row = []
  #               count_row.each do |item|
  #                 percent_row << (item.to_f/total*100).round(2)
  #               end
  #               percents << percent_row
  #             else
  #               percents << Array.new(count_row.length){0}
  #             end
  #           end

  #           result[:column_answers].each_with_index do |col_answer, col_index|
  #             # create hash to store the data for this answer
  #             result[:map][:data][col_answer.value.to_s] = []

  #             # now store the results for each item
  #             (0..result[:row_answers].length-1).each do |index|
  #               # store in highmaps format: {name, value, count}
  #               result[:map][:data][col_answer.value.to_s] << {:shape_name => result[:row_answers][index].shape_name, :display_name => result[:row_answers][index].text, :value => percents[col_index][index], :count => counts[col_index][index]}
  #             end
  #           end

  #         else
  #           result[:map][:question_code] = question_code2
  #           result[:map][:filter] = row_question.text
  #           result[:map][:filters] = result[:row_answers]

  #           result[:row_answers].each_with_index do |row_answer, row_index|
  #             # create hash to store the data for this answer
  #             result[:map][:data][row_answer.value.to_s] = []

  #             # now store the results for each item
  #             (0..result[:column_answers].length-1).each do |index|
  #               # store in highmaps format: {shape_name, display_name, value, count}
  #               result[:map][:data][row_answer.value.to_s] << {:shape_name => result[:column_answers][index].shape_name, :display_name => result[:column_answers][index].text, :value => result[:percents][row_index][index], :count => result[:counts][row_index][index]}
  #             end
  #           end
  #         end
  #       end
  #     end
  #   end

  #   logger.debug "== total time = #{(Time.now - start)*1000} ms"
  #   return result
  # end

=begin old methods for use with data attribute

  ### perform a summary analysis of one hash key in
  ### the data array
  ### - row: name of key to put along row of crosstab
  def data_onevar_analysis1(row, options={})
    start = Time.now
#    logger.debug "--------------------"
#    logger.debug "--------------------"

    result = {}
    data = []

    # get the question/answers
    result[:row_code] = row
    row_question = self.questions.with_code(row)
    result[:row_question] = row_question.text
    result[:row_answers] = row_question.answers.sort_by{|x| x.sort_order}
    result[:type] = TYPE[:onevar]
    result[:counts] = []
    result[:percents] = []
    result[:total_responses] = nil
    result[:chart] = {}

    # if the row question/answers were found, continue
    if result[:row_question].present? && result[:row_answers].present?
      # get uniq values
      row_answers = result[:row_answers].map{|x| x.value}.sort
      logger.debug "unique row values = #{row_answers}"

      # get the counts of each row value
      map = "
        function(){
          if (!this.data){
            return;
          }

          for (var i = 0; i < this.data.length; i++) {
            if (this.data[i]['#{row}'] != null){
              emit(this.data[i]['#{row}'].toString(), 1 );
            }
          }

        }
      "

#      logger.debug map
#      logger.debug "---"

      # countRowValue will be an array of ones from the map function above
      # for the total number of times that the row value appears in data
      # count the length of the array to see how many times it appears
      reduce = "
        function(rowValue, countRowValue) {
          return countRowValue.length;
        };
      "

#      logger.debug reduce
#      logger.debug "---"

      data << Dataset.where(:id => self.id).map_reduce(map, reduce).out(inline: true).to_a

      # flatten the data
#      logger.debug "++ data length was = #{data.length}"
      data.flatten!
#      logger.debug "++ data length = #{data.length}"

      logger.debug "== total time to get data = #{(Time.now - start)*1000} ms"

      if data.present?
        # now put it all together
        # - create counts
        result[:row_answers].each do |row_answer|
          # look for match in data
          data_match = data.select{|x| x['_id'].to_s == row_answer.value.to_s}.first
          if data_match.present?
            result[:counts] << data_match['value']
          else
            result[:counts] << 0
          end
        end

        # - take counts and turn into percents
        total = result[:counts].inject(:+)
        # if total is 0, then set percent to 0
        if total == 0
          result[:percents] = Array.new(result[:counts].length){0}
        else
          result[:counts].each do |count_item|
            result[:percents] << (count_item.to_f/total*100).round(2)
          end
        end

        # - record the total number of responses
#        result[:total_responses] = result[:counts].inject(:+).to_i
        result[:total_responses] = result[:counts].inject(:+).to_i

        # - format data for charts
        # pie chart requires data to be in following format:
        # [ {name, y, count}, {name, y, count}, ...]
        result[:chart][:data] = []
        (0..result[:row_answers].length-1).each do |index|
          result[:chart][:data] << {
            name: result[:row_answers][index].text,
            y: result[:percents][index],
            count: result[:counts][index],
          }
        end

        # - if row is a mappable variable, create the map data
        if row_question.is_mappable?
          result[:map] = {}
          result[:map][:data] = []
          result[:map][:question_code] = row

          result[:row_answers].each_with_index do |row_answer, row_index|
            # store in highmaps format: {name, value, count}
            result[:map][:data] << {:name => row_answer.text, :value => result[:percents][row_index], :count => result[:counts][row_index]}
          end
        end
      end
    end

    logger.debug "== total time = #{(Time.now - start)*1000} ms"

    return result
  end

  ### perform a crosstab analysis between two hash keys in
  ### the data array
  ### - row: name of key to put along row of crosstab
  ### - col: name of key to put along the columns of crosstab
  def data_crosstab_analysis1(row, col, options={})
    start = Time.now
#    logger.debug "--------------------"
#    logger.debug "--------------------"

    result = {}
    data = []

    # get the question/answers
    result[:row_code] = row
    row_question = self.questions.with_code(row)
    result[:row_question] = row_question.text
    result[:row_answers] = row_question.answers.sort_by{|x| x.sort_order}
    result[:column_code] = col
    col_question = self.questions.with_code(col)
    result[:column_question] = col_question.text
    result[:column_answers] = col_question.answers.sort_by{|x| x.sort_order}
    result[:type] = TYPE[:crosstab]
    result[:counts] = []
    result[:percents] = []
    result[:total_responses] = nil
    result[:chart] = {}


    # if the row and col question/answers were found, continue
    if result[:row_question].present? && result[:row_answers].present? && result[:column_question].present? && result[:column_answers].present?

      # get uniq values
      row_answers = result[:row_answers].map{|x| x.value}.sort
      col_answers = result[:column_answers].map{|x| x.value}.sort
      logger.debug "unique row values = #{row_answers}"
      logger.debug "unique col values = #{col_answers}"

      col_answers.each do |c|
#        logger.debug "--------------------"
#        logger.debug "c = #{c}"

        # need to make sure the row value and c value are recorded as strings
        # for if it is an int, the javascript function turns it into a decimal
        # (2 -> 2.0) and then comparisons do not work!
        # - use the if statement to only emit when the row has this value of c and both the row and col have a value
        map = "
          function() {
             if (!this.data){
              return;
             }
             for (var i = 0; i < this.data.length; i++) {
              if (this.data[i]['#{row}'] != null && this.data[i]['#{col}'] != null && this.data[i]['#{col}'].toString() == '#{c}'){
                emit(this.data[i]['#{row}'].toString(), { '#{col}': '#{c}', count: 1 });
              }
             }
          };
        "

#        logger.debug map
#        logger.debug "---"

        reduce = "
          function(rowKey, columnValues) {
            return { '#{col}': '#{c}', count: columnValues.length };
          };
        "

#        logger.debug reduce
#        logger.debug "---"

        data << Dataset.where(:id => self.id).map_reduce(map, reduce).out(inline: true).to_a


      end


      # flatten the data
#      logger.debug "++ data length was = #{data.length}"
      data.flatten!
#      logger.debug "++ data length = #{data.length}"
      logger.debug "-----------"
      logger.debug data.inspect
      logger.debug "-----------"

      logger.debug "== total time to get data = #{(Time.now - start)*1000} ms"

      if data.present?
        # now put it all together

        # - create counts
        result[:row_answers].each do |r|
          data_row = []
          result[:column_answers].each do |c|
            data_match = data.select{|x| x['_id'].to_s == r.value.to_s && x['value'][col].to_s == c.value.to_s}
            if data_match.present?
              data_row << data_match.map{|x| x['value']['count']}.inject(:+)
            else
              data_row << 0
            end
          end
          result[:counts] << data_row
        end

        # - take counts and turn into percents
        totals = []
        logger.debug "counts = \n #{result[:counts]}"
        result[:counts].each do |count_row|
          total = count_row.inject(:+)
          logger.debug " - row total = #{total}"
          totals << total
          if total > 0
            percent_row = []
            count_row.each do |item|
              percent_row << (item.to_f/total*100).round(2)
            end
            result[:percents] << percent_row
          else
            result[:percents] << Array.new(count_row.length){0}
          end
        end
        logger.debug "----------"
        logger.debug " - totals = #{totals}"
        logger.debug " - total = #{totals.inject(:+).to_i}"

        # - record the total number of responses
        result[:total_responses] = totals.inject(:+).to_i

        # - format data for charts
        result[:chart][:labels] = result[:row_answers].map{|x| x.text}
        result[:chart][:data] = []
        counts = result[:counts].transpose

        (0..result[:column_answers].length-1).each do |index|
          item = {}
          item[:name] = result[:column_answers][index].text
          item[:data] = counts[index]
          result[:chart][:data] << item
        end

        # - if row or column is a mappable variable, create the map data
        if row_question.is_mappable? || col_question.is_mappable?
          result[:map] = {}
          result[:map][:data] = {}

          # if the row is the mappable, recompute percents so columns add up to 100%
          if row_question.is_mappable?
            result[:map][:question_code] = row
            result[:map][:filter] = col_question.text
            result[:map][:filters] = result[:column_answers]

            counts = result[:counts].transpose
            percents = []
            counts.each do |count_row|
              total = count_row.inject(:+)
              if total > 0
                percent_row = []
                count_row.each do |item|
                  percent_row << (item.to_f/total*100).round(2)
                end
                percents << percent_row
              else
                percents << Array.new(count_row.length){0}
              end
            end

            result[:column_answers].each_with_index do |col_answer, col_index|
              # create hash to store the data for this answer
              result[:map][:data][col_answer.value.to_s] = []

              # now store the results for each item
              (0..result[:row_answers].length-1).each do |index|
                # store in highmaps format: {name, value, count}
                result[:map][:data][col_answer.value.to_s] << {:name => result[:row_answers][index].text, :value => percents[col_index][index], :count => counts[col_index][index]}
              end
            end

          else
            result[:map][:question_code] = col
            result[:map][:filter] = row_question.text
            result[:map][:filters] = result[:row_answers]

            result[:row_answers].each_with_index do |row_answer, row_index|
              # create hash to store the data for this answer
              result[:map][:data][row_answer.value.to_s] = []

              # now store the results for each item
              (0..result[:column_answers].length-1).each do |index|
                # store in highmaps format: {name, value, count}
                result[:map][:data][row_answer.value.to_s] << {:name => result[:column_answers][index].text, :value => result[:percents][row_index][index], :count => result[:counts][row_index][index]}
              end
            end
          end
        end
      end
    end

    logger.debug "== total time = #{(Time.now - start)*1000} ms"
    return result
  end
=end



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

    CSV.parse(infile.force_encoding('utf-8')) do |row|
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
            question.text = row[indexes[locale]].strip
            counts[locale] += 1
            locale_found = true
          end          
        end
        counts['overall'] += 1 if locale_found

        puts "---> question.valid = #{question.valid?}"

        # # if the record changed, save the changes
        # if question.changed?
        #   if question.save
        #     counts['overall'] += 1
        #   else
        #     msg = I18n.t('mass_uploads_msgs.questions.not_save', n: n, msg: question.errors.full_messages)
        #     return msg
        #   end
        # end

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
      logger.debug "@@@@@@@@@@@@@@@@@@ processing row #{n}"

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

        logger.debug "%%%%%%%%%% col indexes = #{indexes}"

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
            answer.text = row[indexes[locale]].strip
            counts[locale] += 1
            locale_found = true
          end
        end
        counts['overall'] += 1 if locale_found

        logger.debug "******** time to process row: #{Time.now-startRow} seconds"
        logger.debug "************************ total time so far : #{Time.now-start} seconds"
      end
    end

    puts "=========== valid = #{self.valid?}; errors = #{self.errors.full_messages}"

    self.save

    # # make sure the last set of questions is change if needed
    # if question.present? && question.changed?
    #   if question.save
    #     counts['overall'] += 1
    #   else
    #     msg = I18n.t('mass_uploads_msgs.answers.not_save', n: n, msg: answer.errors.full_messages)
    #     return msg
    #   end
    # end

    logger.debug "****************** total changes: #{counts.map{|k,v| k + ' - ' + v.to_s}.join(', ')}"
    logger.debug "****************** time to process answer csv: #{Time.now-start} seconds for #{n} rows"

    I18n.locale = orig_locale

    return msg, counts
  end

end
