# -*- encoding : utf-8 -*-
class SACAlertMailer < ActionMailer::Base
  default_url_options[:host] = "www.olook.com.br"
  default :from => "sac notifications <sac.notifications@olook.com.br>"

  def billet_notification(order, to)
    @order = order
    mail(:to => to, :subject => "Pedido: #{order.number} | Boleto")
  end
  
  def fraud_analysis_notification(order, to)
    @order = order
    mail(:to => to, :subject => "Pedido: #{order.number} | Análise de Fraude")
  end

  def wholesale_notification(wholesale, to)
    @wholesale = wholesale
    mail(to: to, subject: "Novo Atacado")
  end
end
