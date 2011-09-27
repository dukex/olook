require 'spec_helper'

feature "User Authenticate", %q{
  In order to see give a full access
  As a user
  I want to authenticate using my Facebook account or a normal register
} do

  before :each do
    @user = Factory(:user)
    User.any_instance.stub(:counts_and_write_points)
    @casual = Factory(:casual_profile)
  end

  scenario "User Log in" do
    visit new_user_session_path
    fill_in "user_email", :with => @user.email
    fill_in "user_password", :with => @user.password
    click_button "Sign in"
    page.should have_content(I18n.t "devise.sessions.signed_in")
  end

  scenario "User Log in with facebook" do
    visit "/users/auth/facebook"
    page.should have_content(I18n.t "devise.omniauth_callbacks.success", :kind => "Facebook")
  end

  scenario "User Sign up with facebook" do
    User.delete_all
    visit "/users/auth/facebook"
    page.should have_content(I18n.t "devise.omniauth_callbacks.success", :kind => "Facebook")
  end
end
