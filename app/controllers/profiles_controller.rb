class ProfilesController < ApplicationController
  layout 'lite_application'
  before_filter :authenticate_user!
  def show

    if @first_time = (params[:f] == '1')
      @recommended = RecommendationService.new(profiles: current_user.profiles)

      admin = current_admin.present?
      # This is needed becase when we turn the month collection we never have cloth
      @cloth = Product.where("id in (?)", Setting.cloth_showroom_casual.split(","))
      @cloth += @recommended.products( category: Category::CLOTH, collection: @collection, limit: 10, admin: admin)
      @cloth = @cloth.first(10)


      @shoes = @recommended.products( category: Category::SHOE, collection: @collection, admin: admin)
      @bags = @recommended.products( category: Category::BAG, collection: @collection, admin: admin)
      @accessories = @recommended.products( category: Category::ACCESSORY, collection: @collection, admin: admin)

      @partner = cookies[:partner]
    end

    @profile = current_user.main_profile
    @zanpid = request.referer[/.*=([^=]*)/,1] if request.referer =~ /zanpid/
  end
end
