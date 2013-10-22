class MockDataSource
  
  
  def students
    Enumerator.new do |e|
      e.yield id: 456, name: "Harry Potter"
      e.yield id: 457, name: "Ron Weasley"
      e.yield id: 458, name: "Hermione Granger"
    end
  end
  
  def parents
    Enumerator.new do |e|
      e.yield id: 88, name: "James Potter", student_id: 456
      e.yield id: 89, name: "Lily Potter", student_id: 456
    end
  end
  
  def locations
    Enumerator.new do |e|
      e.yield id: 5, slug: "godric's-hollow" # <-- invalid
      e.yield id: 6, slug: "azkaban"
    end
  end
  
  def subjects
    Enumerator.new do |e|
      e.yield id: 49, name: "Care of Magical Creatures", student_ids: [456]
      e.yield id: 50, name: "Advanced Potions", student_ids: [456, 457]
      e.yield id: 51, name: "History of Magic", student_ids: [457]
      e.yield id: 52, name: "Arithmancy", student_ids: [458]
      e.yield id: 53, name: "Study of Ancient Runes", student_ids: [458]
    end
  end
  
  def grades
    Enumerator.new do |e|
      e.yield id: 500, subject_id: 50, student_id: 457, value: "Acceptable"
      e.yield id: 501, subject_id: 51, student_id: 457, value: "Troll"
    end
  end
  
  
end
