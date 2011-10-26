class QuestionParser
  attr_reader :questions

  def initialize(questions)
    @questions = questions
  end

  def build_questions_answers
    parsed_questions = parse
    selected_questions = Question.find(get_questions_ids)
    selected_answers = Answer.find(get_answers_ids)
    questions_answers = []
    parsed_questions.each do |item|
      q = selected_questions.select{|q| q.id == item.keys[0].to_i}.first
      a = selected_answers.select{|a| a.id == item.values[0].to_i}.first
      questions_answers << {:question => q, :answer => a}
    end
    questions_answers
  end

  def parse
    parsed_questions = []
    questions.each do |question, answer|
      question = question.to_s.scan(/[0-9]+/).first
      parsed_questions << {question => answer}
    end
    parsed_questions
  end

  def get_questions_ids
    questions_ids = []
    questions.each do |question, answer|
      question = question.to_s.scan(/[0-9]+/).first
      questions_ids << question
    end
    questions_ids
  end

  def get_answers_ids
    answers_ids = []
    questions.each do |question, answer|
      answers_ids << answer
    end
    answers_ids
  end
end
