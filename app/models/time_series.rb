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

  embeds_many :groups, class_name: 'TimeSeriesGroup', cascade_callbacks: true do
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

  embeds_many :weights, class_name: 'TimeSeriesWeight', cascade_callbacks: true do
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

  embeds_many :questions, class_name: 'TimeSeriesQuestion', cascade_callbacks: true do
    # get the question that has the provided code
    def with_code(code)
      where(:code => code.downcase).first if code.present?
    end

    def with_original_code(original_code)
      where(:original_code => original_code).first
    end

    def with_codes(codes)
      any_in(code: codes)
    end

    def not_in_codes(codes)
      nin(:code => codes)
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
          where(group_id: group_id, exclude: false, has_code_answers: true).to_a
        when 'anlysis_with_exclude_questions'
          where(group_id: group_id, has_code_answers: true).to_a
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

    # mark the answer can_exclude flag as true for the ids provided
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
      :category_mappers_attributes, :category_ids, :permalink,
      :weights_attributes, :groups_attributes

  attr_accessor :category_ids, :var_arranged_items

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
  index ({ :'questions.sort_order' => 1})
  index ({ :'questions.group_id' => 1})
  index ({ :'questions.is_weight' => 1})
  index ({ :'groups.parent_id' => 1})
  index ({ :'groups.sort_order' => 1})
  index ({ :'weights.is_defualt' => 1})
  index ({ :'weights.applies_to_all' => 1})
  index ({ :'weights.codes' => 1})

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
      d.id.to_s
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
    logger.debug "***** validates languages: empty languages = #{self.languages.blank?}"
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
    logger.debug "***** validates time series translations"
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

    return true
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
    logger.debug "---- set public at callback"
    if self.public? && self.public_at.nil?
      self.public_at = Time.now.to_date
    elsif !self.public?
      self.public_at = nil
    end
    return true
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

  def self.get_slug(id)
    x = only(:_slugs).find(id)
    x.present? ? x.slug : nil
  end

  def self.get_default_language(id)
    x = only(:default_language).find(id)
    x.present? ? x.default_language : nil
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

  def is_weighted?
    self.weights.present?
  end


  # get the groups and questions in sorted order
  # options:
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
      items << self.questions.where(:group_id => options[:group_id])
    end

    items.flatten!

    Rails.logger.debug "#{indent}=============== there are a total of #{items.length} items added"

    # sort these items
    # way to sort: sort only items that have sort_order, then add groups with no sort_order, then add questions with no sort_order
    items = items.select{|x| x.sort_order.present?}.sort_by{|x| x.sort_order} +
              items.select{|x| x.class == TimeSeriesGroup && x.sort_order.nil?} +
              items.select{|x| x.class == TimeSeriesQuestion && x.sort_order.nil?}


    return items
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
    # must have at least two items to make a match
    matches = to_compare.values.flatten.group_by{|x| x}.select{|k, v| v.size.between?(2,dataset_ids.length) }.keys
    puts "- found #{matches.length} matches"

    # create record for each match
    matches.each_with_index do |code, index|
      answer_values = []
      question_answers = {}

      # see if question already exists
      q = self.questions.with_code(code)
      # only continue if this quesiton does not exist in the time series yet
      if q.nil?
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
              q.sort_order = index + 1
            end

            if question.has_code_answers?
              q.dataset_questions.build(code: question.code, text_translations: question.text_translations, dataset_id: dataset_id)

              # get the answers for this question
              question_answers[dataset_id] = question.answers.all_for_analysis
              answer_values << question_answers[dataset_id].map{|x| x.value}
              puts "- dataset #{dataset_id} has #{question_answers[dataset_id].length} answers"
            end
          end
        end
      end

      # create answers

      # get unique list of answer values
      # -> answers were collected in above block when creating question
      answer_values.flatten!
      answer_values.uniq! if answer_values.present?
      answer_values.sort! if answer_values.present?

      # for each value, create a record
      answer_values.each do |value|
        a = q.answers.build
        dataset_ids.each do |dataset_id|
          if question_answers[dataset_id].present?
            dataset_answer = question_answers[dataset_id].select{|x| x.value == value}.first

            # create dataset answer record
            if dataset_answer.present?
              # if this is the first found answer, use it to create the answer record
              if a.value.blank?
                a.value = dataset_answer.value
                a.text_translations = dataset_answer.text_translations
                a.sort_order = dataset_answer.sort_order
                a.can_exclude = dataset_answer.can_exclude
              end

              a.dataset_answers.build(value: dataset_answer.value, text_translations: dataset_answer.text_translations, dataset_id: dataset_id)
            end
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

  ##################################
  ##################################
  ## CSV upload and download
  ##################################
  ##################################
  QUESTION_HEADERS={code: 'Question Code', question: 'Question'}
  # create csv to download questions
  # columns: code, text (for each translation)
  def generate_questions_csv
    csv_data = CSV.generate do |csv|
      # create header for csv
      header = [QUESTION_HEADERS[:code]]
      locales = self.languages_sorted
      locales.each do |locale|
        header << "#{QUESTION_HEADERS[:question]} (#{locale})"
      end
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
        csv << row
      end
    end

    return csv_data
  end

  def generate_questions_xlsx
    workbook = RubyXL::Workbook.new
    worksheet = workbook[0]

    # create header for csv
    worksheet.add_cell(0, 0, QUESTION_HEADERS[:code])
    locales = self.languages_sorted
    index = 1
    locales.each do |locale|
      worksheet.add_cell(0, index, "#{QUESTION_HEADERS[:question]} (#{locale})")
      index += 1
    end

    # add questions 
    r_index = 1
    self.questions.each do |question|
      
      worksheet.add_cell(r_index, 0, question.original_code)
      c_index = 1
      locales.each do |locale|
        worksheet.add_cell(r_index, c_index, question.text_translations[locale]) if question.text_translations[locale].present?
        c_index += 1
      end

      r_index += 1
    end

    return workbook.stream.string
  end


  # create csv to download answers
  # columns: code, value, text (for each translation), exclude, can exclude
  ANSWER_HEADERS={code: 'Question Code', value: 'Value', sort: 'Sort Order', answer: 'Answer', can_exclude: 'Can Exclude During Analysis (leave blank to always show answer)'}
  def generate_answers_csv
    csv_data = CSV.generate do |csv|
      # create header for csv
      header = [ANSWER_HEADERS[:code], ANSWER_HEADERS[:value], ANSWER_HEADERS[:sort]]
      locales = self.languages_sorted
      locales.each do |locale|
        header << "#{ANSWER_HEADERS[:answer]} (#{locale})"
      end
      header << ANSWER_HEADERS[:can_exclude]
      csv << header.flatten

      # add questions
      self.questions.each do |question|
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
          row << (answer.can_exclude == true ? 'Y' : nil)
          csv << row
        end
      end
    end

    return csv_data
  end
  def generate_answers_xlsx
    workbook = RubyXL::Workbook.new
    worksheet = workbook[0]

    # create header for csv
    worksheet.add_cell(0, 0, ANSWER_HEADERS[:code])
    worksheet.add_cell(0, 1, ANSWER_HEADERS[:value])
    worksheet.add_cell(0, 2, ANSWER_HEADERS[:sort])

    locales = self.languages_sorted
    index = 3
    locales.each do |locale|
      worksheet.add_cell(0, index, "#{ANSWER_HEADERS[:answer]} (#{locale})")
      index += 1
    end
    worksheet.add_cell(0, index, ANSWER_HEADERS[:can_exclude])    
    index += 1

    # add questions 
    r_index = 1
    self.questions.each do |question|
      question.answers.sorted.each do |answer|
        worksheet.add_cell(r_index, 0, question.original_code)
        worksheet.add_cell(r_index, 1, answer.value)
        worksheet.add_cell(r_index, 2, answer.sort_order)
        c_index = 3
        locales.each do |locale|
          worksheet.add_cell(r_index, c_index, answer.text_translations[locale]) if answer.text_translations[locale].present?
          c_index += 1
        end
        worksheet.add_cell(r_index, c_index, (answer.can_exclude == true ? 'Y' : nil))         
        r_index += 1
      end
    end

    return workbook.stream.string
  end

  # read in the csv and update the question text as necessary
  def process_questions_by_type(file, type)
    start = Time.now
    infile = file.read
    n, msg = 0, ""
    locales = self.languages_sorted
    orig_locale = I18n.locale

    # to indicate where the columns are in the csv doc
    indexes = Hash[locales.map{|x| [x,nil]}]
    indexes['code'] = nil

    # create counter to see how many items in each locale changed
    counts = Hash[locales.map{|x| [x,0]}]
    counts['overall'] = 0

    rows = []
    if type == :csv
      rows = CSV.parse(infile)
    elsif type == :xlsx
      workbook = RubyXL::Parser.parse_buffer(infile)
      rows = workbook[0]
    end
    

    rows.each do |row|
      startRow = Time.now
      n += 1
      #puts "@@@@@@@@@@@@@@@@@@ processing row #{n}"

      cells = type == :csv ? row : row.cells.map{|x| x && x.value }
      if n == 1
        foundAllHeaders = false
        # look at headers and set indexes
        # - doing this in case the user re-arranged the columns
        # if header in csv is not known, throw error

        # code
        idx = cells.index(QUESTION_HEADERS[:code])
        indexes['code'] = idx if idx.present?

        # text translations
        locales.each do |locale|
          idx = cells.index("#{QUESTION_HEADERS[:question]} (#{locale})")
          indexes[locale] = idx if idx.present?
        end

        if !indexes.values.include?(nil)
          # found all columns, so can stop
          foundAllHeaders = true
        end

        if !foundAllHeaders
            msg = I18n.t('mass_uploads_msgs.bad_headers')
            #puts "@@@@@@@@@@> #{msg}"
          return msg
        end

        #puts "%%%%%%%%%% col indexes = #{indexes}"
      else
        # get question for this row
        question = self.questions.with_original_code(cells[indexes['code']])
        if question.nil?
          msg = I18n.t('mass_uploads_msgs.missing_code', n: n, code: cells[indexes['code']])
          #puts "@@@@@@@@@@> #{msg}"
          return msg
        end

        locale_found = false
        locales.each do |locale|
          # if question text is provided and not the same, update it
          I18n.locale = locale.to_sym
          if cells[indexes[locale]].present? && question.text != cells[indexes[locale]].strip
            #puts "- setting text for #{locale}"
            question.text = clean_string(cells[indexes[locale]].strip)
            counts[locale] += 1
            locale_found = true
          end
        end
        counts['overall'] += 1 if locale_found

        #puts "---> question.valid = #{question.valid?}"

        #puts "******** time to process row: #{Time.now-startRow} seconds"
        #puts "************************ total time so far : #{Time.now-start} seconds"
      end
    end

    #puts "=========== valid = #{self.valid?}; errors = #{self.errors.full_messages}"

    success = self.save

    #puts "=========== success save = #{success}"

    #puts "****************** total changes: #{counts.map{|k,v| k + ' - ' + v.to_s}.join(', ')}"
    #puts "****************** time to process question csv: #{Time.now-start} seconds for #{n} rows"

    I18n.locale = orig_locale

    return msg, counts
  end

  # read in the csv and update the answer text as necessary
  def process_answers_by_type(file, type)
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
    indexes['can_exclude'] = nil

    # create counter to see how many items in each locale changed
    counts = Hash[locales.map{|x| [x,0]}]
    counts['overall'] = 0

    rows = []
    if type == :csv
      rows = CSV.parse(infile.force_encoding('utf-8'))
    elsif type == :xlsx
      workbook = RubyXL::Parser.parse_buffer(infile)
      rows = workbook[0]
    end
    

    rows.each do |row|
      startRow = Time.now
      # translation_changed = false
      n += 1
      cells = type == :csv ? row : row.cells.map{|x| x && x.value }

      if n == 1
        foundAllHeaders = false
        # look at headers and set indexes
        # - doing this in case the user re-arranged the columns
        # if header in csv is not known, throw error

        # code
        idx = cells.index(ANSWER_HEADERS[:code])
        indexes['code'] = idx if idx.present?
        # value
        idx = cells.index(ANSWER_HEADERS[:value])
        indexes['value'] = idx if idx.present?
        # sort_order
        idx = cells.index(ANSWER_HEADERS[:sort])
        indexes['sort_order'] = idx if idx.present?
        # can exclude
        idx = cells.index(ANSWER_HEADERS[:can_exclude])
        indexes['can_exclude'] = idx if idx.present?

        # text translations
        locales.each do |locale|
          idx = cells.index("#{ANSWER_HEADERS[:answer]} (#{locale})")
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

      else
        ########################
        # have to save the question and all of its answers
        # if try to just save an answer, mongoid uses incorrect index for question
        ########################

        # if the question is different, save the previous question before moving on to the new question
        if last_question_code != cells[indexes['code']]
          # get question for this cells
          question = self.questions.with_original_code(cells[indexes['code']])
          if question.nil?
            msg = I18n.t('mass_uploads_msgs.missing_code', n: n, code: cells[indexes['code']])
            return msg
          end
        end

        # get answer for this cells
        answer = question.answers.with_value(cells[indexes['value']])
        if answer.nil?
          msg = I18n.t('mass_uploads.answers.missing_answer', n: n, code: cells[indexes['code']], value: cells[indexes['value']])
          return msg
        end


        # if value exist for exclude, assume it means true
        answer.sort_order = cells[indexes['sort_order']]
        answer.can_exclude = cells[indexes['can_exclude']].present?

        # temp_text = answer.text_translations.dup
        locale_found = false
        locales.each do |locale|
          I18n.locale = locale.to_sym
          # if answer text is provided and not the same, update it
          if cells[indexes[locale]].present? && answer.text != cells[indexes[locale]].strip
            puts "- setting text for #{locale}"
            # question.text_will_change!
            answer.text = clean_string(cells[indexes[locale]].strip)
            counts[locale] += 1
            locale_found = true
          end
        end
        counts['overall'] += 1 if locale_found

        #puts "******** time to process row: #{Time.now-startRow} seconds"
        #puts "************************ total time so far : #{Time.now-start} seconds"
      end
    end

    #puts "=========== valid = #{self.valid?}; errors = #{self.errors.full_messages}"

    self.save

    #puts "****************** total changes: #{counts.map{|k,v| k + ' - ' + v.to_s}.join(', ')}"
    #puts "****************** time to process answer csv: #{Time.now-start} seconds for #{n} rows"

    I18n.locale = orig_locale

    return msg, counts
  end

end
