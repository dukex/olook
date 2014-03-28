class SearchController < ApplicationController
  layout "lite_application"

  def show
    search_params = SeoUrl.parse(request.fullpath)
    Rails.logger.debug("New params: #{params.inspect}")
    @q = params[:q] || ""

    @singular_word = @q.singularize
    if catalogs_pages.include?(@singular_word)
      redirect_to catalog_path(category: @singular_word)
    else
      @search = SearchEngine.new(term: @q, brand: search_params[:brand], 
        subcategory: search_params[:subcategory], 
        color: search_params[:color], 
        heel: search_params[:heel])
          .for_page(params[:page])
          .with_limit(32)
      @url_builder = SeoUrl.new(search_params, nil, @search)
    end

    @recommendation = RecommendationService.new(profiles: current_user.try(:profiles_with_fallback) || [Profile.default])
  end

  def product_suggestions
    render json: ProductSearch.terms_for(params[:term].downcase)
  end

  private
    def catalogs_pages
      %w[roupa acessorio sapato bolsa]
    end

    def canonical_link
      "http://#{request.host_with_port}/busca"
    end
end
