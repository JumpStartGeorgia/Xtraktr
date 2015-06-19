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
  field :admin_codebook, type: String, localize: true
  field :admin_csv, type: String, localize: true
  field :admin_spss, type: String, localize: true
  field :admin_stata, type: String, localize: true
  field :admin_r, type: String, localize: true

  #############################

  attr_accessible :shape_file, :codebook, :csv, :spss, :stata, :r, 
                  :codebook_translations, :csv_translations, :spss_translations, :stata_translations, :r_translations,
                  :admin_codebook, :admin_csv, :admin_spss, :admin_stata, :admin_r, 
                  :admin_codebook_translations, :admin_csv_translations, :admin_spss_translations, :admin_stata_translations, :admin_r_translations

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

  def admin_codebook
    get_translation(self.admin_codebook_translations, self.dataset.current_locale, self.dataset.default_language)
  end
  def admin_csv
    get_translation(self.admin_csv_translations, self.dataset.current_locale, self.dataset.default_language)
  end
  def admin_spss
    get_translation(self.admin_spss_translations, self.dataset.current_locale, self.dataset.default_language)
  end
  def admin_stata
    get_translation(self.admin_stata_translations, self.dataset.current_locale, self.dataset.default_language)
  end
  def admin_r
    get_translation(self.admin_r_translations, self.dataset.current_locale, self.dataset.default_language)
  end
  

end