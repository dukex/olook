require 'spec_helper'

describe Gift::OccasionsController do

  describe "GET 'new'" do
    it "returns http success" do
      get 'new'
      response.should be_success
    end
  end

end
