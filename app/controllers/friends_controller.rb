class FriendsController < ApplicationController
  before_filter :authenticate_user!
end
