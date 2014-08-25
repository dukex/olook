# -*- encoding : utf-8 -*-
class ResellerController < ApplicationController
  layout "lite_application"
  def new
    @reseller = Reseller.new
    @reseller.addresses.build
  end

  def create
    @reseller = Reseller.new(params[:reseller])
    if @reseller.save
      sign_in(:user, @reseller)
      SACAlertMailer.reseller_notification(@reseller, "luciana.cremonezi@olook.com.br,financeiro@olook.com.br,caroline.passos@olook.com.br").deliver
      redirect_to reseller_show_path
    else
      custom_error_messages @reseller
      render "new"
    end
  end

  def show
  end

  private
   def custom_error_messages reseller
     reseller.errors.set(:cnpj, ["O CNPJ não está batendo. Pode conferir?"]) if (reseller.errors.messages[:cnpj] && reseller.errors.messages[:cnpj][0]) =~ /número inválido/
     reseller.errors.set(:'addresses.state', ["Precisamos da sigla do estado (UF)"]) if reseller.errors.messages[:'addresses.state'].to_s[0]
     reseller.errors.set(:'addresses.street', ["Qual o nome da Rua, Avenida etc?"]) if reseller.errors.messages[:'addresses.state'].to_s[0]
     reseller.errors.set(:'addresses.zip_code', ["Precisamos do seu CEP"]) if (reseller.errors.messages[:'addresses.zip_code'] && reseller.errors.messages[:'addresses.zip_code'][0] =~ /estranho/ )
   end

   def meta_description
     "Revenda na Olook as principais tendências da moda. Vantagens especiais e descontos progressivos. Seja uma de nossas afiliadas e ganhe com a gente."
   end

end
