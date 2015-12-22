class HelpCategoryMapper
  include Mongoid::Document
  include Mongoid::Timestamps

  #############################
  belongs_to :help_category
  attr_accessible :help_category_id
  index(help_category_id: 1)
  validates_presence_of :help_category_id

  #############################
  belongs_to :help_article
  attr_accessible :help_article_id
  index(help_article_id: 1)
  validates_presence_of :help_article_id

  # No two help category mappers should have the same
  # article id and the same category id
  validates_uniqueness_of :help_article_id, scope: [:help_category_id]

end
