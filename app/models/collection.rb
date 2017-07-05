class Collection < ApplicationRecord
  include Antispam
  include TopicsConcern
  include ElasticsearchConcern
  include ModeratableConcern

  acts_as_voteable

  belongs_to :user
  has_many :links, -> { order :id },
    class_name: CollectionLink.name,
    dependent: :destroy

  validates :name, :user, :kind, presence: true
  validates :locale, presence: true

  enumerize :kind, in: Types::Collection::Kind.values, predicates: true
  enumerize :state, in: Types::Collection::State.values, predicates: true
  enumerize :locale, in: Types::Locale.values, predicates: { prefix: true }

  scope :unpublished, -> { where state: :unpublished }
  scope :published, -> { where state: :published }

  def to_param
    "#{id}-#{name.permalinked}"
  end

  def topic_user
    user
  end

  # для совместимости с DbEntry
  def description_ru
    text
  end

  # для совместимости с DbEntry
  def description_en
    text
  end
end
