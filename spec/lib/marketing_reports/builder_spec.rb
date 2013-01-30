# -*- encoding : utf-8 -*-

require 'spec_helper'

describe MarketingReports::Builder do
  before :all do
    User.delete_all
  end
  let(:user_a) { FactoryGirl.create :user }
  let(:user_b) { FactoryGirl.create :user }
  let(:user_c) { FactoryGirl.create :user }
  let(:response) { double(:response, :parsed_response => [ {"reason"=>"Unknown", "email"=>"teste@teste.com"} ]) }
  let(:services) do
    {
      :spam_reports   => double(:s_response, :parsed_response => [ {"reason"=>"Any", "email"=> "a@b.com"} ]),
      :unsubscribes   => double(:u_response, :parsed_response => [ {"reason"=>"Unknown", "email"=>"g@h.com"} ]),
      :blocks         => double(:b_response, :parsed_response => [ {"reason"=>"Unknown", "email"=>"e@f.com"} ]),
      :invalid_emails => double(:i_response, :parsed_response => [ {"reason"=>"500", "email"=>"c@d.com"} ]),
    }
  end

  let(:bounce_response) do
   double(:bounce_response, :parsed_response => [ {"reason"=>"500", "email"=>"c@d.com"} ])
  end

  describe "#initialize" do
    context "when no type is passed" do
      it "sets csv to empty string" do
        subject.csv.should == ""
      end
    end
  end

  describe "#upload" do
    let(:csv) { "a,b,c" }
    let(:filename) { "filename.csv" }

    let(:info_ftp) { "exact_target.xml" }
    let(:uploader) { double(:uploder) }

    before do
      subject.csv = csv
    end

    it "calls FileUploader passing the csv" do
      Rails.env.stub(:production) { true }
      MarketingReports::FileUploader.should_receive(:new).with(filename, csv).and_return(mock.as_null_object)
      MarketingReports::FileUploader.should_receive(:copy_file) {nil}
      subject.save_file(filename, info_ftp)
    end

    it "calls save_local_file on the file uploader with the passed filename" do
      Rails.env.stub(:production) { true }
      MarketingReports::FileUploader.should_receive(:new).with(filename, csv).and_return(uploader)
      uploader.should_receive(:save_local_file)
      MarketingReports::FileUploader.should_receive(:copy_file) {nil}
      subject.save_file(filename)
    end

    it "calls save_local_file on the file uploader with the passed filename and info for ftp" do
      Rails.env.stub(:production) { true }
      MarketingReports::FileUploader.stub(:new).and_return(uploader)
      uploader.should_receive(:save_local_file)
      MarketingReports::FileUploader.should_receive(:copy_file) {nil}
      subject.save_file(filename, info_ftp)
    end

  end

  describe "#generate_userbase_with_auth_token" do
    let(:csv_header) do
      "id,email,created_at,sign_in_count,current_sign_in_at,last_sign_in_at,invite_token,first_name,last_name,facebook_token,birthday,has_purchases,auth_token\n"
    end

    let!(:loyalty_program_credit_type) { FactoryGirl.create(:loyalty_program_credit_type, :code => :loyalty_program) }
    let!(:invite_credit_type) { FactoryGirl.create(:invite_credit_type, :code => :invite) }
    let!(:redeem_credit_type) { FactoryGirl.create(:loyalty_program_credit_type, :code => :redeem) }

    before(:each) do
      services.each do |service, response|
        MarketingReports::SendgridClient.stub(:new).with(service, :username => "olook").and_return(response)
        MarketingReports::SendgridClient.stub(:new).with(service, :username => "olook2").and_return(response)
      end
      MarketingReports::SendgridClient.stub(:new).with(:bounces, :type => "hard", :username => "olook2").and_return(bounce_response)
    end

    it "builds a csv file containing all user data" do

      csv_body = [user_a].inject("") do |data, user|
        data += "#{user.id},#{user.email.chomp},#{user.created_at},#{user.sign_in_count},#{user.current_sign_in_at},#{user.last_sign_in_at},"
        data += "#{user.invite_token},#{user.first_name},#{user.last_name},#{user.facebook_token},#{user.birthday},#{user.has_purchases?},#{user.authentication_token}\n"
        data
      end

      subject.generate_userbase_with_auth_token
      subject.csv.should match /^#{csv_header}#{csv_body}/
    end

    it "does not include a user which email was included in any bounced list (spam reports, unsubscribers, blocks or invalid)" do

      services = {
        :spam_reports   => double(:s_response, :parsed_response => [ {"reason" => "Any", "email" => user_a.email } ]),
        :unsubscribes   => double(:u_response, :parsed_response => [ {"reason" => "Unknown", "email" => user_b.email } ]),
        :blocks         => double(:b_response, :parsed_response => [ {"reason" => "Unknown", "email" => user_c.email } ]),
        :invalid_emails => double(:i_response, :parsed_response => [ {"reason" => "500", "email" => user_c.email } ])
      }

      services.each do |service, response|
        MarketingReports::SendgridClient.stub(:new).with(service, :username => "olook").and_return(response)
        MarketingReports::SendgridClient.stub(:new).with(service, :username => "olook2").and_return(response)
      end

      subject.generate_userbase_with_auth_token
      subject.csv.should_not match user_a.email
      subject.csv.should_not match user_b.email
      subject.csv.should_not match user_c.email
    end

    it "includes return path seed email" do
      services.each do |service, response|
        MarketingReports::SendgridClient.stub(:new).with(service, :username => "olook").and_return(response)
        MarketingReports::SendgridClient.stub(:new).with(service, :username => "olook2").and_return(response)
      end
      subject.generate_userbase_with_auth_token
      subject.csv.should match ",0000ref000.olook@000.monitor1.returnpath.net,,,,,,seed list,,,,,\n"
    end

    it "includes delivery whatch seed email" do
      services.each do |service, response|
        MarketingReports::SendgridClient.stub(:new).with(service, :username => "olook").and_return(response)
        MarketingReports::SendgridClient.stub(:new).with(service, :username => "olook2").and_return(response)
      end
      subject.generate_userbase_with_auth_token
      subject.csv.should match ",dwatch20@hotmail.com,,,,,,seed list,,,,,\n"
    end
  end

  describe "#generate_userbase_with_auth_token_and_credits" do
    let(:csv_header) do
      "id,email,created_at,sign_in_count,current_sign_in_at,last_sign_in_at,invite_token,first_name,last_name,facebook_token,birthday,has_purchases,auth_token,credit_balance\n"
    end

    let!(:loyalty_program_credit_type) { FactoryGirl.create(:loyalty_program_credit_type, :code => :loyalty_program) }
    let!(:invite_credit_type) { FactoryGirl.create(:invite_credit_type, :code => :invite) }
    let!(:redeem_credit_type) { FactoryGirl.create(:loyalty_program_credit_type, :code => :redeem) }

    before(:each) do
      services.each do |service, response|
        MarketingReports::SendgridClient.stub(:new).with(service, :username => "olook").and_return(response)
        MarketingReports::SendgridClient.stub(:new).with(service, :username => "olook2").and_return(response)
      end
      MarketingReports::SendgridClient.stub(:new).with(:bounces, :type => "hard", :username => "olook2").and_return(bounce_response)
    end

    it "builds a csv file containing all user data" do

      csv_body = [user_a].inject("") do |data, user|
        data += "#{user.id},#{user.email.chomp},#{user.created_at.strftime("%d-%m-%Y")},#{user.sign_in_count},#{user.current_sign_in_at},#{user.last_sign_in_at},"
        data += "#{user.invite_token},#{user.first_name},#{user.last_name},#{user.facebook_token},#{user.birthday},#{user.has_purchases?},#{user.authentication_token},0.0\n"
        data
      end

      subject.generate_userbase_with_auth_token_and_credits
      subject.csv.should match /^#{csv_header}#{csv_body}/
    end
  end

   describe "#generate_userbase_with_credits" do
    let(:csv_header) do
      "id,email,created_at,sign_in_count,current_sign_in_at,last_sign_in_at,invite_token,first_name,last_name,facebook_token,birthday,has_purchases,credit_balance\n"
    end

    let!(:loyalty_program_credit_type) { FactoryGirl.create(:loyalty_program_credit_type, :code => :loyalty_program) }
    let!(:invite_credit_type) { FactoryGirl.create(:invite_credit_type, :code => :invite) }
    let!(:redeem_credit_type) { FactoryGirl.create(:loyalty_program_credit_type, :code => :redeem) }

    before(:each) do
      services.each do |service, response|
        MarketingReports::SendgridClient.stub(:new).with(service, :username => "olook").and_return(response)
        MarketingReports::SendgridClient.stub(:new).with(service, :username => "olook2").and_return(response)
      end
      MarketingReports::SendgridClient.stub(:new).with(:bounces, :type => "hard", :username => "olook2").and_return(bounce_response)
    end

    it "builds a csv file containing all user data" do

      csv_body = [user_a].inject("") do |data, user|
        data += "#{user.id},#{user.email.chomp},#{user.created_at},#{user.sign_in_count},#{user.current_sign_in_at},#{user.last_sign_in_at},"
        data += "#{user.invite_token},#{user.first_name},#{user.last_name},#{user.facebook_token},#{user.birthday},#{user.has_purchases?},0.0\n"
        data
      end

      subject.generate_userbase_with_credits
      subject.csv.should match /^#{csv_header}#{csv_body}/
    end
  end

  describe "#generate_campaign_emails" do
    let(:csv_header) { "email,created_at\n" }
    let(:campaign_email) { FactoryGirl.create(:campaign_email) }

    before(:each) do
      services.each do |service, response|
        MarketingReports::SendgridClient.stub(:new).with(service, :username => "olook").and_return(response)
        MarketingReports::SendgridClient.stub(:new).with(service, :username => "olook2").and_return(response)
      end
      MarketingReports::SendgridClient.stub(:new).with(:bounces, :type => "hard", :username => "olook2").and_return(bounce_response)
    end

    it "builds a csv file containing all email data from campaign_emails table" do
      csv_body = [campaign_email].inject("") do |data, campaign_email|
        data += "#{campaign_email.email.chomp},#{campaign_email.created_at}\n"
      end 
      subject.generate_campaign_emails
      subject.csv.should match /^#{csv_header}#{csv_body}/
    end

    it "doesn't include bounced emails" do
      csv_body = [campaign_email].inject("") do |data, campaign_email|
        data += "#{campaign_email.email.chomp}\n"
        data
      end 
      subject.stub(:bounced_list).and_return([campaign_email.email])
      subject.generate_campaign_emails
      subject.csv.should_not match /^#{csv_header}#{csv_body}/
      subject.csv.should match /^#{csv_header}/
    end

  end


end
