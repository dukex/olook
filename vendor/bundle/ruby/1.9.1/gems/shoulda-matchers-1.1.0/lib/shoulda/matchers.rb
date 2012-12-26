require 'shoulda/matchers/version'
require 'shoulda/matchers/assertion_error'

if defined?(RSpec)
  require 'shoulda/matchers/integrations/rspec'
else
  require 'shoulda/matchers/integrations/test_unit'
end
