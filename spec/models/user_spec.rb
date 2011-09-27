# -*- encoding : utf-8 -*-
require 'spec_helper'

describe User do

  let(:user) { Factory(:user) }
  let(:profile) { mock_model('Profile') }

  it { should validate_uniqueness_of(:email) }
  it { should allow_value("a@b.com").for(:email) }
  it { should_not allow_value("@b.com").for(:email) }
  it { should_not allow_value("a@b.").for(:email) }

  it { should allow_value("José").for(:first_name) }
  it { should allow_value("José Bar").for(:first_name) }

  it { should_not allow_value("José_Bar").for(:first_name) }
  it { should_not allow_value("123").for(:first_name) }

  it "should counts and write points" do
    hash = {profile.id => 2}
    user.counts_and_write_points(hash)
    Point.should have(1).record
  end

end
