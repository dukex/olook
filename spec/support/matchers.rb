def with_a_logged_user(&block)
  include Devise::TestHelpers

  context "with a logged user" do
    let(:user) { FactoryGirl.create :user }

    before :each do
      sign_in user
    end

    instance_eval &block
  end
end


def with_a_logged_admin
  before :each do
    request.env['devise.mapping'] = Devise.mappings[:admin]
    @admin = Factory :admin
    sign_in @admin
  end
  yield if block_given?
end
