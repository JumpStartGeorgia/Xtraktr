class DatasetFiles < CustomTranslation
  include Mongoid::Document
  include Mongoid::Timestamps
  #############################

  embedded_in :dataset

  #############################
  # each field contains the path to the file so it can be used in a link to download

  field :shape_file, type: String # does not need to be localized
  field :codebook, type: String, localize: true
  field :csv, type: String, localize: true
  field :spss, type: String, localize: true
  field :stata, type: String, localize: true
  field :r, type: String, localize: true

  #############################

  attr_accessible :shape_file, :codebook, :csv, :spss, :stata, :r, 
                  :codebook_translations, :csv_translations, :spss_translations, :stata_translations, :r_translations

  #############################
  ## override get methods for fields that are localized
  def codebook
    get_translation(self.codebook_translations, self.dataset.current_locale, self.dataset.default_language)
  end
  def csv
    get_translation(self.csv_translations, self.dataset.current_locale, self.dataset.default_language)
  end
  def spss
    get_translation(self.spss_translations, self.dataset.current_locale, self.dataset.default_language)
  end
  def stata
    get_translation(self.stata_translations, self.dataset.current_locale, self.dataset.default_language)
  end
  def r
    get_translation(self.r_translations, self.dataset.current_locale, self.dataset.default_language)
  end
  


  before_save :t2
  before_create :t1
  def t1
    puts "$$$$$$$$$$$$4 dataset files before create"
    puts "$$$$$$$$$$$$4 changed? #{self.changed?}; codebook chagned = #{self.codebook.changed?} codebook trans change = #{self.codebook_translations.changed?}"
  end
  def t2
    puts "$$$$$$$$$$$$4 dataset files before save!"
    puts "$$$$$$$$$$$$4 changed? #{self.changed?}; codebook chagned = #{self.codebook.changed?} codebook trans change = #{self.codebook_translations.changed?}"
  end

end