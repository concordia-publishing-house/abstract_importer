class Student < ActiveRecord::Base
  has_and_belongs_to_many :subjects
  has_many :grades
  has_many :parents
  belongs_to :pet, polymorphic: true

  def report_card
    subjects.map do |subject|
      grade = grades.find_by_subject_id(subject.id)
      "#{subject.name}: #{grade.value if grade}"
    end
  end
end

class Parent < ActiveRecord::Base
  belongs_to :student
end

class Location < ActiveRecord::Base
  validates :slug, format: {with: /\A[a-z0-9\-]+\z/}
end

class Subject < ActiveRecord::Base
  has_and_belongs_to_many :students
end

class Grade < ActiveRecord::Base
  belongs_to :student
  belongs_to :subject
end

class Account < ActiveRecord::Base
  has_many :parents
  has_many :students
  has_many :subjects
  has_many :grades
  has_many :locations
  has_many :cats
  has_many :owls
end

class Cat < ActiveRecord::Base
  has_one :student, as: :pet
  has_many :abilities, as: :pet, inverse_of: :pet
end

class Owl < ActiveRecord::Base
  has_one :student, as: :pet
  has_many :abilities, as: :pet, inverse_of: :pet
end

class Ability < ActiveRecord::Base
  belongs_to :pet, inverse_of: :abilities, polymorphic: true
end
