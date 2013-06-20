# -*- encoding : utf-8 -*-
class CatalogsController < SearchController
  layout "lite_application"
  respond_to :html, :js

  def show
    category = params[:category].parameterize.singularize if params[:category]
    params.merge!(SeoUrl.parse(params[:params])) if params[:params]
    subcategory = params[:subcategory] if params[:subcategory]
    color = params[:color] if params[:color]
    heel = params[:heel] if params[:heel]
    care = params[:care] if params[:care]
    brand = params[:brand] if params[:brand]
    @filters = SearchEngine.new(category: category).filters
    @filters.grouped_products('subcategory').delete_if{|c| Product::CARE_PRODUCTS.include?(c) }
    @search = SearchEngine.new(category: category, subcategory: subcategory, color: color, heel: heel, care: care, brand: brand).for_page(params[:page]).with_limit(100)
    @catalog_products = @search.products

    # TODO => Mover para outro lugar
    whitelist = ["salto", "category", "color", "categoria"]
    @querystring = params.select{|k,v| whitelist.include?(k) }.to_query
  end

end
