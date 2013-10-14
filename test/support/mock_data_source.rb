class MockDataSource
  
  def students
    yield id: 456, name: "Harry Potter"
    yield id: 457, name: "Ron Weasley"
    yield id: 458, name: "Hermione Granger"
  end
  
  def parents
    yield id: 88, name: "James Potter", student_id: 456
    yield id: 89, name: "Lily Potter", student_id: 456
  end
  
  def locations
    yield id: 5, slug: "godric's-hollow" # <-- invalid
    yield id: 6, slug: "azkaban"
  end
  
  def subjects
    yield id: 49, name: "Care of Magical Creatures", student_ids: [456]
    yield id: 50, name: "Advanced Potions", student_ids: [456, 457]
    yield id: 51, name: "History of Magic", student_ids: [457]
    yield id: 52, name: "Arithmancy", student_ids: [458]
    yield id: 53, name: "Study of Ancient Runes", student_ids: [458]
  end
  
  def grades
    yield id: 500, subject_id: 50, student_id: 457, value: "Acceptable"
    yield id: 501, subject_id: 51, student_id: 457, value: "Troll"
  end
  
end
