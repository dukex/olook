require 'shared_admin'

class Admin < ActiveRecord::Base
  include Shim
  include SharedAdmin
end
