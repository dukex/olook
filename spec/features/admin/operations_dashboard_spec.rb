  # -*- encoding : utf-8 -*-
require 'spec_helper'
require 'features/helpers'

feature "Operations dashboard", %q{
  As any admin user
  I can view orders by their planned delivery statuses
  So I can better manage late deliveries
} do

  let(:admin) { FactoryGirl.create(:admin_superadministrator) }

  background do
    ApplicationController.any_instance.stub(:load_promotion)
    FactoryGirl.create(:order, created_at: Time.now, state: "authorized")
    do_admin_login!(admin)
    visit '/admin'
  end

	scenario "Listing the orders by their dates and statuses" do
    expect(page).to have_content("Dashboard")
    expect(page).to have_content("Operações")

    expect(page).to have_content("Prazo para despacho")
    expect(page).to have_content("Pago")
    expect(page).to have_content("Aguardando Separação")
    expect(page).to have_content("Despachado")
    expect(page).to have_content("Entregue")
    expect(page).to have_content("Hoje")
    expect(page).to have_content("Ontem")
    expect(page).to have_content("2 dias atrás")
    expect(page).to have_content("3 dias atrás")
    expect(page).to have_content("4 dias atrás")
    expect(page).to have_content("5 dias atrás")
    expect(page).to have_content("6 ou mais dias atrás")
    expect(page).to have_content("TOTAL")

    expect(page.find('tr#0_dias td#total', text: '1'))

    expect(page).to have_css('#total_authorized', text: '1')
  end

  scenario "Viewing details for a list of orders" do

    page.find('tr#0_dias td#authorized a').click

    expect(page).to have_content("Cadastro")
    expect(page).to have_content("Pagamento")
    expect(page).to have_content("Despacho Entrega")
    expect(page).to have_content("Data prometida de Entrega")
    expect(page).to have_content("Transportador")
    expect(page).to have_content("Gateway de pagamento")
    expect(page).to have_content("Cliente nome")
    expect(page).to have_content("Cliente email")
    expect(page).to have_content("Cidade")
    expect(page).to have_content("Estado")
    expect(page).to have_content("CEP")
    expect(page).to have_content("Quantidade de itens")

    expect(page).to have_content("Wednesday, 23 January 2013")
    expect(page).to have_content("Wednesday, 23 January 2013")
    #TODO: Despacho Entrega
    #TODO: Data prometida de Entrega
    expect(page).to have_content("TEX")
    #TODO: Gateway de pagamento
    expect(page).to have_content("José Ernesto")
    expect(page).to have_content("jose.ernesto@dominio.com")
    expect(page).to have_content("Rio de Janeiro")
    expect(page).to have_content("RJ")
    expect(page).to have_content("87656-908")
    expect(page).to have_content("100.0")
    expect(page).to have_content("0")
  end

end
