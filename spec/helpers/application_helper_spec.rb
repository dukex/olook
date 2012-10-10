# -*- encoding : utf-8 -*-
require 'spec_helper'

describe ApplicationHelper do
  describe "#cart_total" do
    it "returns markup for order total" do
     expected = "<span>(<div id=\"cart_items\">0</div>)</span>"
     helper.cart_total(FactoryGirl.create(:clean_cart)).should eq(expected)
    end
  end

  describe "#stylesheet_application" do
    it "returns link to application.css" do
      expected = "<link href=\"/assets/application.css\" media=\"screen\" rel=\"stylesheet\" type=\"text/css\" />"
      helper.stylesheet_application.should eq(expected)
    end
  end

  describe "#track_event" do
    it "returns a track event string with category, action and item" do
      helper.track_event('category','action','item').should == "_gaq.push(['_trackEvent', 'category', 'action', 'item']);"
    end

    context "when no item is passed" do
      it "returns a track event with category and action only" do
        helper.track_event('category','action').should == "_gaq.push(['_trackEvent', 'category', 'action', '']);"
      end
    end
  end

  describe "#user_avatar" do
    it "return the suer avatar given a type" do
      user = stub(:uid => 123)
      type = "large"
      expected = "https://graph.facebook.com/#{user.uid}/picture?type=#{type}"
      helper.user_avatar(user, type).should == expected
    end
  end

  describe "#member_type" do
    it "checks if user is signed in" do
      helper.should_receive(:'user_signed_in?')
      helper.member_type
    end
    context "when user is not logged in" do
      it "returns visitor" do
        helper.stub(:'user_signed_in?').and_return(false)
        helper.member_type.should == "visitor"
      end
    end

    context "when user is logged in" do
      it "returns member" do
        helper.stub(:'user_signed_in?').and_return(true)
        helper.member_type.should == "member"
      end
    end
  end

end
