ActiveRecord::Schema.define(:version => 1) do
  
  create_table "accounts", :force => true do |t|
  end
  
  create_table "students", :force => true do |t|
    t.integer  "account_id"
    t.integer  "legacy_id"
    t.string   "name"
    t.string   "house"
  end
  
  create_table "parents", :force => true do |t|
    t.integer  "account_id"
    t.integer  "student_id"
    t.integer  "legacy_id"
    t.string   "name"
  end
  
  create_table "locations", :force => true do |t|
    t.integer  "account_id"
    t.integer  "legacy_id"
    t.string   "slug"
  end
  
  create_table "students_subjects", :force => true do |t|
    t.integer  "student_id"
    t.integer  "subject_id"
  end
  
  create_table "subjects", :force => true do |t|
    t.integer  "account_id"
    t.integer  "legacy_id"
    t.string   "name"
  end

  create_table "grades", :force => true do |t|
    t.integer  "account_id"
    t.integer  "subject_id"
    t.integer  "student_id"
    t.integer  "legacy_id"
    t.string   "value"
  end

  create_table "football_teams", :force => true do |t|
    t.integer  "account_id"
    t.integer  "legacy_id"
  end

  create_table "rugby_teams", :force => true do |t|
    t.integer  "account_id"
    t.integer  "legacy_id"
  end

  create_table "athletes", :force => true do |t|
    t.integer  "account_id"
    t.integer  "legacy_id"
    t.string   "name"
    t.integer  "team_id"
    t.string   "team_type"
  end

end
