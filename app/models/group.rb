class Group < CustomTranslation
  include Mongoid::Document


  field :title, type: String, localize: true
  field :description, type: String, localize: true
  # if true, the description text will appear in the chart titles
  field :include_in_charts, type: Boolean, default: false
  # id of group that this group belongs to
  field :parent_id, type: Moped::BSON::ObjectId
  # number indicating the sort order
  field :sort_order, type: Integer, default: 0
  
  #############################
  embedded_in :dataset

  #############################
  attr_accessible :title, :description, :title_translations, :description_translations, :include_in_charts, :parent_id, :sort_order
  attr_accessor :questions, :sub_groups

  #############################
  # Validations

  # validate the translation fields
  # text field needs to be validated for presence
  def validate_translations
#    logger.debug "***** validates question translations"
    if self.dataset.default_language.present?
#      logger.debug "***** - default is present; title = #{self.title_translations[self.dataset.default_language]}"
      if self.title_translations[self.dataset.default_language].blank?
#        logger.debug "***** -- title not present!"
        errors.add(:base, I18n.t('errors.messages.translation_default_lang', 
            field_name: self.class.human_attribute_name('title'),
            language: Language.get_name(self.dataset.default_language),
            msg: I18n.t('errors.messages.blank')) )
      end

      if self.include_in_charts? && self.description_translations[self.dataset.default_language].blank?
#        logger.debug "***** -- description not present!"
        errors.add(:base, I18n.t('errors.messages.translation_default_lang', 
            field_name: self.class.human_attribute_name('description'),
            language: Language.get_name(self.dataset.default_language),
            msg: I18n.t('errors.messages.blank')) )
      end
    end
  end 

  #############################
  # Callbacks

  after_destroy :update_questions

  # update all questions assigned to this group
  # - set question group id = parent id
  # - if this is a main group and it has sub groups, delete the sub-groups too
  def update_questions
    Rails.logger.debug ">>>>> updating questions after destroying group"

    questions_to_update = self.dataset.questions.assigned_to_group_meta_only(self.id).map{|x| x.id}
    Rails.logger.debug ">>>>> - need to update #{questions_to_update.length} questions in this group"

    # if this is not a sub-group, get questions from subgroups too that need to be updated
    if self.parent_id.nil?
      self.sub_groups.each do |sub_group|
        questions_to_update += self.dataset.questions.assigned_to_group_meta_only(sub_group.id).map{|x| x.id}
      end
    end
    Rails.logger.debug ">>>>> - need to update #{questions_to_update.length} questions in this group and all of its subgroups"

    if questions_to_update.length > 0
      self.dataset.questions.assign_group(questions_to_update, self.parent_id.present? ? self.parent_id : nil)
      self.dataset.save
    end

    # if this is not a sub-group, delete all of its sub-groups too
    if self.parent_id.nil?
      Rails.logger.debug ">>>>> - deleting all subgroups"
      self.sub_groups.delete_all
    end

  end


  #############################
  ## override get methods for fields that are localized
  def title
    get_translation(self.title_translations, self.dataset.current_locale, self.dataset.default_language)
  end
  def description
    get_translation(self.description_translations, self.dataset.current_locale, self.dataset.default_language)
  end

  #############################

  # get questions for a specific type and save to questions
  def get_questions_by_type(type='all')
    if !self.questions.present?
      self.questions = self.dataset.questions.assigned_to_group(self.id, type)
    end

    return self.questions
  end

  # # get questions that are in this group
  # def questions
  #   self.dataset.questions.assigned_to_group(self.id)
  # end

  # # get questions that are in this group for analysis
  # def for_download
  #   self.dataset.questions.assigned_to_group_for_download(self.id)
  # end

  # # get questions that are in this group for analysis
  # def questions_for_anlysis
  #   self.dataset.questions.assigned_to_group_for_analysis(self.id)
  # end

  # # get questions that are in this group for analysis
  # def questions_for_anlysis_with_exclude_questions
  #   self.dataset.questions.assigned_to_group_for_analysis_with_exclude_questions(self.id)
  # end

  # get count of questions that are in this group
  def question_count
    #self.dataset.questions.count_assigned_to_group(self.id)
    get_questions_by_type.count
  end

  # get the parent group of this group
  def parent
    self.dataset.groups.find(self.parent_id) if self.parent_id.present?
  end

  # get the sub-groups and save to sub_groups
  def get_sub_groups
    if !self.sub_groups.present?
      self.sub_groups = self.dataset.groups.sub_groups(self.id)
    end

    return self.sub_groups
  end
end