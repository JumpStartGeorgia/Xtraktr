class Report < CustomTranslation
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip
  include LocalizedFiles

  #############################
  has_mongoid_attached_file :file, url: "/system/datasets/:dataset_id/reports/:id/:filename", use_timestamp: false, localize: true


  field :title, type: String, localize: true
  field :released_at, type: Date

  embedded_in :dataset


  #############################
  attr_accessible :file, :title, :released_at, :file_translations, :title_translations

  #############################
  # Validations
  validates_attachment :file, 
      :content_type => { :content_type => ["text/plain", "application/pdf", "application/vnd.oasis.opendocument.text", "application/vnd.openxmlformats-officedocument.wordprocessingml.document", "application/msword"] }
  validates_attachment_file_name :file, :matches => [/txt\Z/i, /pdf\Z/i, /odt\Z/i, /doc?x\Z/i]
  validate :validate_translations

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
  def title
    get_translation(self.title_translations)
  end
  def file
    get_translation(self.file_translations)
  end


end