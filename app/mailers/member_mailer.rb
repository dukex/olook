# -*- encoding : utf-8 -*-
class MemberMailer < ActionMailer::Base
  default :from => "olook <avisos@my.olookmail.com.br>"

  def self.smtp_settings
    {
      :user_name => "olook",
      :password => "olook123abc",
      :domain => "my.olookmail.com.br",
      :address => "smtp.sendgrid.net",
      :port => 587,
      :authentication => :plain,
      tls: true,
      enable_starttls_auto: true

    }
  end

  def welcome_email(member)
    @member = member
    mail( :to => member.email,
          :from => "olook <bemvinda@my.olookmail.com.br>",
          :subject => "#{member.name}, seja bem vinda! Seu cadastro foi feito com sucesso!"
          )
    headers["X-SMTPAPI"] = { 'category' => 'welcome_email' }.to_json
  end

  def showroom_ready_email(member)
    @member = member
    mail( :to => member.email,
          :subject => "#{member.name}, sua vitrine personalizada já está pronta!")
    headers["X-SMTPAPI"] = { 'category' => 'showroom_ready_email' }.to_json
  end
end
