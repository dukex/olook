# -*- encoding : utf-8 -*-
require 'spec_helper'

describe Admin::IndexController do

  before :each do
    request.env['devise.mapping'] = Devise.mappings[:admin]
    @admin = Factory :admin_superadministrator
    sign_in @admin
  end

  describe "GET 'index'" do
    it "should be successful" do
      get 'dashboard'
      response.should be_success
    end
  end

end
