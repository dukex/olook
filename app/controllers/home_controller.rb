# -*- encoding : utf-8 -*-
class HomeController < ApplicationController

  layout "lite_application"
  def index
    @google_path_pixel_information = "Home"
    @chaordic_user = ChaordicInfo.user(current_user,cookies[:ceid])

    prepare_for_home
  end

end
