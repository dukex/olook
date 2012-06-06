# -*- encoding : utf-8 -*-
require 'spec_helper'

describe SurveyController do

  include Devise::TestHelpers

  describe "GET 'new'" do
    it "should be successful" do
      get 'new'
      response.should be_success
    end

    it "should also show the Survey if the user is logged in" do
      user = FactoryGirl.create(:user)
      sign_in user
      get 'new'
      response.should be_success
    end

    it "gets all questions and answers from registration survey and assigns to question" do
      questions = [1,2,3]
      Question.should_receive(:from_registration_survey).and_return(questions)
      get 'new'
      assigns(:questions).should eq questions
    end

    it "should instantiate @presenter" do
      question = FactoryGirl.create(:question)
      SurveyQuestions.should_receive(:new).with([question])
      get 'new'
    end

    it "should show the Survey if the user is not logged in" do
      get 'new'
      response.should_not redirect_to root_path
    end
  end

  describe "POST 'create'" do
    context "answering quiz" do
      it "should assign profile_points in the session" do
        ProfileBuilder.stub(:profiles_given_questions).and_return("foo")
        profile_points = ProfileBuilder.stub(:build_profiles_points).and_return("bar").call
        post 'create', :questions => {:foo => :bar}, :year => '2012', :month => '12', :day => '12'
        session[:profile_points].should == profile_points
      end

      it "should redirect to survey_path if params[:questions] is nil" do
        post 'create'
        response.should redirect_to new_survey_path
      end
    end
    context "retaking quiz" do
      
      it "should assign profile_points in the session" do
        user = FactoryGirl.create(:user)
        sign_in user
        ProfileBuilder.stub(:profiles_given_questions).and_return("foo")
        ProfileBuilder.any_instance.stub(:create_user_points).and_return(true)
        profile_points = ProfileBuilder.stub(:build_profiles_points).and_return("bar").call
        post 'create', :questions => {:foo => :bar}, :year => '2012', :month => '12', :day => '12'
        session[:profile_points].should == profile_points
      end

      it "should redirect to survey_path if params[:questions] is nil" do
        post 'create'
        response.should redirect_to new_survey_path
      end
    end
  end
end
