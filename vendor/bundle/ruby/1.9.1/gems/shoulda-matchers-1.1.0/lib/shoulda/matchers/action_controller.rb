require 'shoulda/matchers/action_controller/assign_to_matcher'
require 'shoulda/matchers/action_controller/filter_param_matcher'
require 'shoulda/matchers/action_controller/set_the_flash_matcher'
require 'shoulda/matchers/action_controller/render_with_layout_matcher'
require 'shoulda/matchers/action_controller/respond_with_matcher'
require 'shoulda/matchers/action_controller/respond_with_content_type_matcher'
require 'shoulda/matchers/action_controller/set_session_matcher'
require 'shoulda/matchers/action_controller/route_matcher'
require 'shoulda/matchers/action_controller/redirect_to_matcher'
require 'shoulda/matchers/action_controller/render_template_matcher'

module Shoulda
  module Matchers
    # By using the matchers you can quickly and easily create concise and
    # easy to read test suites.
    #
    # This code segment:
    #
    #   describe UsersController, "on GET to show with a valid id" do
    #     before(:each) do
    #       get :show, :id => User.first.to_param
    #     end
    #
    #     it { should assign_to(:user) }
    #     it { should respond_with(:success) }
    #     it { should render_template(:show) }
    #     it { should not_set_the_flash) }
    #
    #     it "should do something else really cool" do
    #       assigns[:user].id.should == 1
    #     end
    #   end
    #
    # Would produce 5 tests for the show action
    module ActionController
    end
  end
end
