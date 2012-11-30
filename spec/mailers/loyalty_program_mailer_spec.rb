# -*- encoding : utf-8 -*-
require "spec_helper"

describe LoyaltyProgramMailer do
  describe "loyalty program credits enabled e-mail" do
    let(:member) { FactoryGirl.create(:member) }
    let!(:loyalty_program_credit_type) { FactoryGirl.create(:loyalty_program_credit_type) }
    let!(:redeem_credit_type) { FactoryGirl.create(:redeem_credit_type) }
    let!(:invite_credit_type) {FactoryGirl.create(:invite_credit_type) }
    let(:user_credit) { FactoryGirl.create(:user_credit, :credit_type => loyalty_program_credit_type, :user => member) }
    let(:user_credit2) { FactoryGirl.create(:user_credit, :credit_type => redeem_credit_type, :user => member , :amount  => "20") }
    let(:user_credit3) { FactoryGirl.create(:user_credit, :credit_type => invite_credit_type, :user => member , :amount  => "20") }


    it "sets 'from' attribute to olook <avisos@olook.com.br>" do
      user_credit.add({amount: 20})
      Delorean.time_travel_to(user_credit.credits.last.activates_at)
      mail = LoyaltyProgramMailer.send_enabled_credits_notification(member)
      mail.from.should include("avisos@olook.com.br")
    end

    it "sets 'to' attribute to passed member's email" do

      mail = LoyaltyProgramMailer.send_enabled_credits_notification(member)

      mail.to.should include(member.email)

    end

    it "sets 'title' attribute" do
      user_credit.add({amount: 20})
      Delorean.time_travel_to(user_credit.credits.last.activates_at)

      mail = LoyaltyProgramMailer.send_enabled_credits_notification(member)

      mail.subject.should eq("#{member.first_name}, você tem R$ #{('%.2f' % member.user_credits_for(:loyalty_program).total).gsub('.',',')} em créditos disponíveis para uso.")

      Delorean.back_to_the_present
    end
  end

  describe "loyalty program credits to be expired e-mail" do
    let(:member) { FactoryGirl.create(:member) }
    let!(:loyalty_program_credit_type) { FactoryGirl.create(:loyalty_program_credit_type) }
    let(:user_credit) { FactoryGirl.create(:user_credit, :credit_type => loyalty_program_credit_type, :user => member) }


    it "sets 'from' attribute to olook <avisos@olook.com.br>" do
      user_credit.add({amount: 20})
      Delorean.time_travel_to(user_credit.credits.last.expires_at - 7.days)

      mail = LoyaltyProgramMailer.send_expiration_warning(member)
      mail.from.should include("avisos@olook.com.br")

      Delorean.back_to_the_present
    end

    it "sets 'to' attribute to passed member's email" do
      user_credit.add({amount: 20})
      Delorean.time_travel_to(user_credit.credits.last.expires_at - 7.days)

      mail = LoyaltyProgramMailer.send_expiration_warning(member)
      mail.to.should include(member.email)

      Delorean.back_to_the_present
    end

    it "sets 'title' attribute" do
      user_credit.add({amount: 20})
      Delorean.time_travel_to(user_credit.credits.last.expires_at - 7.days)

      mail = LoyaltyProgramMailer.send_expiration_warning(member)

      # user_credit = loyalty_program_credit_type
      @credit_amount = LoyaltyProgramCreditType.credit_amount_to_expire(user_credit)
      mail.subject.should == "#{member.first_name}, seus R$ #{('%.2f' % @credit_amount).gsub('.',',')} em créditos vão expirar!"

      Delorean.back_to_the_present
    end
  end

  describe "loyalty program credits to be expired tomorrow e-mail" do

    let(:member) { FactoryGirl.create(:member) }
    let!(:loyalty_program_credit_type) { FactoryGirl.create(:loyalty_program_credit_type) }
    let(:user_credit) { FactoryGirl.create(:user_credit, :credit_type => loyalty_program_credit_type, :user => member) }

    it "sets 'from' attribute to olook <avisos@olook.com.br>" do
      user_credit.add({amount: 20})
      Delorean.time_travel_to(user_credit.credits.last.expires_at - 1.days)
      mail = LoyaltyProgramMailer.send_expiration_warning(member, true)
      mail.from.should include("avisos@olook.com.br")
      Delorean.back_to_the_present
    end

    it "sets 'to' attribute to passed member's email" do
      user_credit.add({amount: 20})
      Delorean.time_travel_to(user_credit.credits.last.expires_at - 1.days)
      mail = LoyaltyProgramMailer.send_expiration_warning(member, true)
      mail.to.should include(member.email)
      Delorean.back_to_the_present
    end

    it "sets 'title' attribute" do

      user_credit.add({amount: 20})
      Delorean.time_travel_to(user_credit.credits.last.expires_at - 1.days)
      mail = LoyaltyProgramMailer.send_expiration_warning(member, true)

      # user_credit = loyalty_program_credit_type
      @credit_amount = LoyaltyProgramCreditType.credit_amount_to_expire(user_credit)
      mail.subject.should == "Corra #{member.first_name}, seus R$ #{('%.2f' % @credit_amount).gsub('.',',')} em créditos expiram amanhã!"
      Delorean.back_to_the_present
    end
  end

end
