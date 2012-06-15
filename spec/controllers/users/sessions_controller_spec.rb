# -*- encoding : utf-8 -*-
require 'spec_helper'

describe Users::SessionsController do
  render_views
  context "User login" do
    before :each do
      request.env['devise.mapping'] = Devise.mappings[:user]
    end
    let(:user) { FactoryGirl.create(:user) }

    describe "Post 'create'" do
      it "should redirect to the showroom user page" do
        post :create, :user => { :email => user.email, :password => user.password }
        response.should redirect_to(member_showroom_path)
      end

      it "should try to create a sign event for the user" do
        subject.should_receive(:create_sign_in_event)
        post :create, :user => { :email => user.email, :password => user.password }
      end
    end
  end

  context "Admin login" do
    before :each do
      request.env['devise.mapping'] = Devise.mappings[:admin]
    end
    let(:admin) { FactoryGirl.create(:admin) }

    describe "Post 'create'" do
      it "should redirect to admin page" do
        post :create, :admin => { :email => admin.email, :password => admin.password }
        response.should redirect_to(admin_path)
      end
    end
  end

  describe "events" do
    context 'for users' do
      let(:user) { mock_model(User) }

      before :each do
        subject.stub(:current_user).and_return( user )
      end

      it "should create a new sign in event" do
        user.should_receive(:add_event).with( EventType::SIGNIN )
        subject.send(:create_sign_in_event)
      end

      it "should create a new sign out event" do
        user.should_receive(:add_event).with( EventType::SIGNOUT )
        subject.send(:create_sign_out_event)
      end
    end

    context 'for admins' do
      let(:admin) { mock_model(Admin) }

      before :each do
        subject.stub(:current_user).and_return( admin )
      end

      it "should not create a new sign in event" do
        admin.should_not_receive(:add_event)
        subject.send(:create_sign_in_event)
      end

      it "should not create a new sign out event" do
        admin.should_not_receive(:add_event)
        subject.send(:create_sign_out_event)
      end
    end
  end

end
