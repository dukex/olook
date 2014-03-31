class BrandsController < ApplicationController
  layout "lite_application"
  def index
  end

  def show
    search_params = SeoUrl.parse(request.fullpath)
    Rails.logger.debug("New params: #{params.inspect}")

    @search = SearchEngine.new(search_params).for_page(params[:page]).with_limit(32)
    @search.for_admin if current_admin

    params.merge!(search_params)

    @brand = Brand.where(name:  params[:brand].to_s.split("-").map{|brand| ActiveSupport::Inflector.transliterate(brand).downcase.titleize})
    @antibounce_box = AntibounceBox.new(params) if @brand.any? && AntibounceBox.need_antibounce_box?(@search, @brand.map{|b| b.name.downcase}, params)
    @chaordic_user = ChaordicInfo.user(current_user,cookies[:ceid])
    @url_builder = SeoUrl.new(search_params, "brand", @search)
  end
  private
    def title_text
      Seo::SeoManager.new(request.path, model: @brand.try(:first), search: @search).select_meta_tag
    end

    def canonical_link
      brand = Array(@brand).first
      if brand
        "http://#{request.host_with_port}/#{brand.name.downcase}"
      end
    end

    def meta_description
      Seo::DescriptionManager.new(description_key: @brand.try(:first).try(:name)).choose
    end
end
