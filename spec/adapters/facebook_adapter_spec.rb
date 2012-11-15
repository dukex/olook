# -*- encoding : utf-8 -*-
require 'spec_helper'

describe FacebookAdapter do
  subject { FacebookAdapter.new(:fake_access_token) }
  let(:friend_list) { [{"id" => "1", "name" => "User name 1", "gender" => "male"}, {"id" => "2", "name" => "User name 2", "gender" => "female"}] }
  let(:formated_friend_list) { [OpenStruct.new(:uid => "2", :name => "User name 2")] }
  let(:fields) { "name, gender, birthday, first_name" }

  context "cached friend list" do
    it "should not get the friend list from cache when invalid" do
      pending "Not working on CI"
      Rails.cache.clear
      subject.adapter.should_receive(:get_connections).with("me", "friends", :fields => fields).and_return(friend_list)
      subject.facebook_friends
    end

    it "should get the friend list from cache when valid" do
      pending "Not working on CI"
      subject.adapter.should_not_receive(:get_connections).with("me", "friends", :fields => fields).and_return(friend_list)
      subject.facebook_friends
    end
  end

  it "should get the friends ids list" do
    subject.stub(:facebook_friends).and_return(formated_friend_list)
    subject.facebook_friends_ids.should == ["2"]
  end

  it "should get the facebook friends registered at olook" do
    subject.stub(:facebook_friends_ids).and_return(friends_ids = ["2"])
    User.should_receive(:find_all_by_uid).with(friends_ids)
    subject.facebook_friends_registered_at_olook
  end

  it "should get the facebook friends not registered at olook" do
    subject.stub(:facebook_friends_registered_at_olook).and_return([OpenStruct.new(:uid => "1", :name => "User name 1")])
    subject.stub(:facebook_friends).and_return(formated_friend_list)
    subject.facebook_friends_not_registered_at_olook.should == [formated_friend_list.last]
  end

  it "should post a message in the wall" do
    message, attachment, target, options = :message, {}, "me", {}
    subject.adapter.should_receive(:put_wall_post).with(message, attachment, target, options)
    subject.post_wall_message(message, :attachment => attachment, :friend => target, :options => options)
  end
end


