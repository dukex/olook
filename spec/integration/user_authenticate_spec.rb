# -*- encoding : utf-8 -*-
require 'spec_helper'
require 'integration/helpers'

feature "User Authenticate", %q{
  In order to give a full access
  As a user
  I want to authenticate using my Facebook account or a normal register
} do

  def showroom_message
    "Sua stylist está criando sua vitrine personalizada, e ela ficará pronta nas próximas 24 horas"
  end

  def update_user_to_old_user(login)
    user = User.find_by_email(login)
    user.created_at = Time.now - 1.day
    user.save!
  end

  use_vcr_cassette('yahoo', :match_requests_on => [:host, :path])

  before :each do
    @user = Factory(:user)
    User.any_instance.stub(:counts_and_write_points)
    Resque.stub(:enqueue)
  end

  scenario "User can fill the cpf when invited" do
    visit accept_invitation_path(:invite_token => @user.invite_token)
    answer_survey
    page.should have_content("CPF")
  end

  scenario "User cant't fill the cpf when not invited" do
    answer_survey
    visit new_user_registration_path
    page.should_not have_content("CPF")
  end

  scenario "User Log in with facebook" do
    answer_survey
    visit "/users/auth/facebook"
    page.should have_content(I18n.t "devise.omniauth_callbacks.success", :kind => "Facebook")
  end

 scenario "User Sign up" do
   answer_survey
   visit new_user_registration_path
   within("#user_new") do
     fill_in "user_first_name", :with => "First Name"
     fill_in "user_last_name", :with => "Last Name"
     fill_in "user_email", :with => "fake@mail.com"
     fill_in "user_password", :with => "123456"
     fill_in "user_password_confirmation", :with => "123456"
     click_button "register"
   end
   within("#welcome") do
     page.should have_content(showroom_message)
   end
 end

  scenario "User update without password" do
    do_login!(@user)
    visit edit_user_registration_path
    within("#user_edit") do
      fill_in "user_first_name", :with => "New First Name"
      fill_in "user_last_name", :with => "New Last Name"
      fill_in "user_email", :with => "fake@mail.com"
      click_button "update_user"
    end
    within('#info_user') do
     page.should have_content("New First Name")
    end
  end

  scenario "User update with password" do
    do_login!(@user)
    visit edit_user_registration_path
    within("#user_edit") do
      fill_in "user_first_name", :with => "New First Name"
      fill_in "user_last_name", :with => "New Last Name"
      fill_in "user_email", :with => "fake@mail.com"
      fill_in "user_password", :with => "123456"
      fill_in "user_cpf", :with => "19762003601"
      fill_in "user_password_confirmation", :with => "123456"
      click_button "update_user"
    end
    within('#info_user') do
     page.should have_content("New First Name")
    end
  end

  scenario "User Log in" do
    visit new_user_session_path
    fill_in "user_email", :with => @user.email
    fill_in "user_password", :with => @user.password
    click_button "login"
    page.should have_content(I18n.t "devise.sessions.signed_in")
  end

 scenario "Whole sign up, sign out and sign in process" do
   login = "john@doe.com"
   pass = "123abc"

   answer_survey
   visit new_user_registration_path
   within("#user_new") do
     fill_in "user_first_name", :with => "First Name"
     fill_in "user_last_name", :with => "Last Name"
     fill_in "user_email", :with => login
     fill_in "user_password", :with => pass
     fill_in "user_password_confirmation", :with => pass
     click_on "register"
   end
   page.should have_content(showroom_message)
   click_on "Sair"
   page.should have_content(I18n.t "devise.sessions.signed_out")

   update_user_to_old_user(login)

   visit new_user_session_path
   fill_in "user_email", :with => login
   fill_in "user_password", :with => pass
   click_button "login"
   within(".notice") do
     page.should have_content(I18n.t "devise.sessions.signed_in")
   end
 end
end
