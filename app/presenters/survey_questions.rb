# -*- encoding : utf-8 -*-
class SurveyQuestions
  attr_reader :questions

  def initialize(questions)
    @questions = questions
  end

  def common_questions
    questions[0..14]
  end

  def questions_for_my_friends_quiz
    # 0 - 11 are the questions we need for "amigas" page (and we have pictures for all the answers)
    questions[0..11]
  end

  def heel_height_question
    questions[15]
  end

  def word_question
    questions[16]
  end

  def color_questions
    items = questions[17..20]
    colors = {
    items[0] => ['aths-special', 'straw', 'driftwood', 'nevada', 'ship-gray'],
    items[1] => ['vis-vis-to-tree-poppy', 'colonial-white-to-koromiko', 'alto-to-silver-chalice', 'dusty-gray-to-boulder', 'mercury-to-silver'],
    items[2] => ['pink-flare', 'peach-yellow', 'chalky', 'light-orchid', 'vanilla-ice'],
    items[3] => ['golden-bell', 'cardinal-pink', 'windsor', 'observatory', 'black']
    }
    colors
  end

  def first_color_question
    questions[17]
  end

  def shoe_size_question
    questions[21]
  end

  def dress_size_question
    questions[22]
  end

  def id_first_question
    questions.first.id if questions.size > 0
  end

  def title_color_question
    "17. Dê uma nota para cada uma das cartelas de cores abaixo."
  end

  def title_about_question
    "18. Conte-nos um pouco sobre você:"
  end
end
