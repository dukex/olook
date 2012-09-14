# -*- encoding : utf-8 -*-
namespace :db do
  task :populate => :environment  do
    create_contact_subjects
  end

  task :update_friend_questions => :environment  do
    update_friend_questions
  end

  desc "Deletes all liquidations and creates a fake liquidations for testing puporses"
  task :load_fake_liquidation => :environment do
    LiquidationProduct.delete_all
    Liquidation.delete_all

    resume =  {:products_ids=>[100, 10], :categories=>{1=>{"sandalia"=>"Sandália", "rasteira"=>"Rasteira"}, 2=>{"tate" => "Tate", "bau" => "Baú"}, 3 => {"joia" => "Jóia", "brinco" => "Brinco"}}, :heels=>{"baixo"=>"Baixo", "medio" => "Médio", "6.5" => "6.5"}, :shoe_sizes=>{"33"=>33, "34"=>34, "35"=>35, "36"=>36, "37"=>37, "38"=>38, "39"=>39, "40"=>40}}

    liquidation = Liquidation.create(:name => "OlookLet", :teaser => "Excepteur sint", :description => "Lorem ipsum dolor sit amet, consectetur magna aliqua. Ut enim ad minim veniam", :resume => resume, :starts_at => Date.yesterday, :ends_at => Date.today + 1.year)

    Product.shoes[0..40].each do |product|
      LiquidationProduct.create(:liquidation_id => liquidation.id,
                                :product_id => product.id,
                                :subcategory_name => ["rasteira", "sandalia"].shuffle.first,
                                :original_price => [99.90, 85.90, 129.90].shuffle.first,
                                :retail_price => [49.90, 55.90, 89.90].shuffle.first,
                                :shoe_size => [33, 34, 35, 36, 37, 38, 39, 40].shuffle.first,
                                :heel => ["baixo", "medio"].shuffle.first,
                                :category_id => Category::SHOE,
                                :inventory => 10)
    end

    Product.bags[0..40].each do |product|
      LiquidationProduct.create(:liquidation_id => liquidation.id,
                                :product_id => product.id,
                                :subcategory_name => ["bau", "tate"].shuffle.first,
                                :original_price => [78.90, 65.90, 89.90].shuffle.first,
                                :retail_price => [32.90, 34.90, 45.90].shuffle.first,
                                :category_id => Category::BAG,
                                :inventory => 10)

    end

    Product.accessories[0..40].each do |product|
      LiquidationProduct.create(:liquidation_id => liquidation.id,
                                :product_id => product.id,
                                :subcategory_name => ["joia", "brinco"].shuffle.first,
                                :original_price => [68.90, 55.90, 79.90].shuffle.first,
                                :retail_price => [32.90, 34.90, 45.90].shuffle.first,
                                :category_id => Category::ACCESSORY,
                                :inventory => 10)

    end
  end

  desc "Creates some gift occasions"
  task :load_gift_occasion_types => :environment do
    ['aniversário','dia dos namorados','aniversário de casamento'].each do |name|
      GiftOccasionType.create :name => name
    end
  end

  desc "Creates some gift recipients relations"
  task :load_gift_recipient_relations => :environment do
    ['avó','tia','irmã','namorada'].each do |name|
      GiftRecipientRelation.create :name => name
    end
  end
  
  desc "Bootstrap the database with demo data"
  task :boostrap => %w(db:setup) do
    20.times do
      product = Product.new :name => Faker::Lorem.words(1).first, :description => Faker::Lorem.paragraph(10), :category => (1..3).to_a.sample, :model_number => rand(36**8).to_s(36)
      if product.save!
        puts "."
      end
    end
  end
  
  desc "generate basic moments"
	task :generate, [:file] => :environment do |task, args|   
		
		Moment.new( { :name => "Ocasiões",
									:article => "para todas as",
									:slug => "todas",
									:position => 5 } ).save!

		Moment.new( { :name => "Passeio", 
									:article => "Para um", 
									:slug => "passeio",
									:position => 4 } ).save!

		Moment.new( { :name => "Noite", 
									:article => "Para a", 
									:slug => "noite",
									:position => 3 } ).save!

		Moment.new( { :name => "Executivo", 
									:article => "Para o dia-a-dia", 
									:slug => "executivo",
									:position => 2 } ).save!

		Moment.new( { :name => "Casual", 
									:article => "Para o dia-a-dia", 
									:slug => "casual",
									:position => 1 } ).save!
		
	end
end

def create_contact_subjects
  ContactInformation.create!(:title => "Sugestão", :email => "falecom@olook.com.br")
  ContactInformation.create!(:title => "Reclamação", :email => "falecom@olook.com.br")
  ContactInformation.create!(:title => "Pedido de dicas de moda", :email => "falecom@olook.com.br")
  ContactInformation.create!(:title => "Dúvida", :email => "falecom@olook.com.br")
  ContactInformation.create!(:title => "Imprensa", :email => "falecom@olook.com.br")
  ContactInformation.create!(:title => "Parcerias blogueiras", :email => "falecom@olook.com.br")
  ContactInformation.create!(:title => "Parcerias empresas", :email => "falecom@olook.com.br")
end

def update_friend_questions
  friend_questions = ["Com qual dessas celebridades brasileiras __USER_NAME__ se identifica mais?",
   "Com qual dessas celebridades internacionais __USER_NAME__ se identifica mais?",
   "De qual desses ícones de estilo __USER_NAME__ gostaria de herdar o guarda-roupa?",
   "Qual dessas peças não pode faltar no dia a dia de __USER_NAME__?",
   "Qual desses estilos de cabelo mais agradaria __USER_NAME__?",
   "Se pudesse voltar no tempo, que época da moda __USER_NAME__ escolheria?",
   "Qual desses roteiros de viagem mais agradaria __USER_NAME__?",
   "Se __USER_NAME__ fosse escolher um estilo de dança para aprender, qual seria?",
   "Qual dessas revistas femininas __USER_NAME__ tem o hábito de ler?",
   "Com qual desses trajes __USER_NAME__ costuma dormir?",
   "Qual desses modelos de óculos escuros mais combina com __USER_NAME__?",
   "Escolha o look que mais agradaria __USER_NAME__ para o dia a dia.",
   "Escolha o look que mais agradaria __USER_NAME__ para noite.",
   "Quais acessórios __USER_NAME__ usaria para trabalhar?",
   "Quais acessórios __USER_NAME__ usaria para um domingo à tarde?",
   "Quais acessórios __USER_NAME__ usaria em uma festa?",
   "Quais acessórios __USER_NAME__ escolheria para um pretinho básico?",
   "Maquiagem para você __USER_NAME__ é...",
   "Como __USER_NAME__ costuma combinar as cores?",
   "Como __USER_NAME__ gosta do caimento das suas roupas?"]
   Question.all.each_with_index do |question, index|
     question.update_attributes(:friend_title => friend_questions[index])
   end
end
