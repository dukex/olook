# -*- encoding : utf-8 -*-
require 'spec_helper'

describe OrderStatusMailer do
  let(:user) { FactoryGirl.create(:user) }
  let(:order) { FactoryGirl.create(:order, :user => user) }
  let!(:loyalty_program_credit_type) { FactoryGirl.create(:loyalty_program_credit_type) }
  let!(:invite_credit_type) { FactoryGirl.create(:invite_credit_type) }

  describe "#order_requested" do

    before do
      order.state = "waiting_payment"
      order.save!
    end

    let!(:mail) { OrderStatusMailer.order_requested(order) }

    it "sets 'from' attribute to olook <avisos@olook.com.br>" do
      mail.from.should include("avisos@olook.com.br")
    end

    it "sets 'to' attribute to passed member's email" do
      mail.to.should include(user.email)
    end

    context " for CreditCard " do

      let(:credit_card) {FactoryGirl.create(:clean_order_credit_card, :user => user)}
      let(:mail_for_billet) { OrderStatusMailer.order_requested(credit_card) }

      it "sets 'subject' attribute telling the user that we received her order" do
        mail_for_billet.subject.should == "User First Name, recebemos seu pedido."
      end
    end

    context " for Billet " do

      expiration_date =  BilletExpirationDate.expiration_for_two_business_day.strftime("%d/%m/%Y")

      it "sets 'subject' attribute telling the expiration date" do

        mail.subject.should == "Lembrete: seu boleto expira em: #{expiration_date}. Garanta seu pedido!"
      end
    end


  end

  describe "#payment_confirmed" do

    before do
      order.state = "authorized"
      order.save!
    end

    let!(:mail) { OrderStatusMailer.order_requested(order) }

    it "sets 'from' attribute to olook <avisos@olook.com.br>" do
      mail.from.should include("avisos@olook.com.br")
    end

    it "sets 'to' attribute to passed member's email" do
      mail.to.should include(user.email)
    end

    it "sets 'subject' attribute telling the user that the payment was confirmed" do
      mail.subject.should == "Seu pedido n#{order.number} foi confirmado!"
    end

  end

  describe "#payment_refused" do

    let!(:order) { FactoryGirl.create(:clean_order_credit_card, :user => user)}

    before do
      order.state = "canceled"
      order.save!
    end

    let!(:mail) { OrderStatusMailer.payment_refused(order) }

    it "sets 'from' attribute to olook <avisos@olook.com.br>" do
      mail.from.should include("avisos@olook.com.br")
    end

    it "sets 'to' attribute to passed member's email" do
      mail.to.should include(user.email)
    end

    context "and order is canceled" do
      it "sets 'subject' attribute telling the user that the payment was confirmed" do
        OrderStatusMailer.payment_refused(order).subject.should == "Seu pedido n#{order.number} foi cancelado."
      end
    end

    context "and order is reversed" do
      before do
        order.state = "reversed"
        order.save!
      end
      it "sets 'subject' attribute telling the user that the payment was confirmed" do
        OrderStatusMailer.payment_refused(order).subject.should == "Seu pedido n#{order.number} foi cancelado."
      end
    end

  end

end
