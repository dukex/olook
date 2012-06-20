# -*- encoding : utf-8 -*-
class MemberMailer < ActionMailer::Base
  default :from => "olook <bemvinda@olook1.com.br>"

  def self.smtp_settings
    {
      :user_name => "olook2",
      :password => "olook123abc",
      :domain => "my.olookmail.com",
      :address => "smtp.sendgrid.net",
      :port => 587,
      :authentication => :plain,
      :enable_starttls_auto => true
    }
  end

  def welcome_email(member)
    @member = member
    default_welcome_email
  end

  alias :welcome_gift_half_male_user_email :welcome_email
  alias :welcome_thin_half_male_user_email :welcome_email
  alias :welcome_gift_half_female_user_email :welcome_email
  alias :welcome_thin_half_female_user_email :welcome_email

  private

  def default_welcome_email
    mail(:to => @member.email, :subject => subject_by_gender)
    headers["X-SMTPAPI"] = { 'category' => 'welcome_email' }.to_json
  end

  def subject_by_gender
    "#{@member.name}, seja bem vind#{@member.male? ? 'o' : 'a'}! Seu cadastro foi feito com sucesso!"
  end
end
