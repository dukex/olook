Factory.define :answer_from_casual_profile, :class => Answer do |f|
  f.title "Casual Answer Title"	
  f.association :profile, :factory => :casual_profile
end

Factory.define :answer_from_sporty_profile, :class => Answer do |f|
  f.title "Sporty Answer Title"	
  f.association :profile, :factory => :sporty_profile
end