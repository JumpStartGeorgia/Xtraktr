class UserMember < CustomTranslation
  include Mongoid::Document
  include Mongoid::Timestamps

  #############################

  belongs_to :group, class_name: 'User', inverse_of: :members
  belongs_to :member, class_name: 'User', inverse_of: :groups

  #############################

  attr_accessible :group_id, :member_id

  #############################

  # indexes
  index ({ :group_id => 1})
  index ({ :member_id => 1})

  #############################
  # Validations
  validates :group_id, :member_id, presence: true

end
