class Student < ActiveRecord::Base
  has_and_belongs_to_many :subjects
  has_many :grades
  has_many :parents
  
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
  has_many :athletes
  has_many :teams
end

class Athlete < ActiveRecord::Base
  has_many :teams
end

class Team < ActiveRecord::Base
  self.inheritance_column = "type"
  belongs_to :athlete, polymorphic: true
end

class FootballTeam < Team
end

class RugbyTeam < Team
end
