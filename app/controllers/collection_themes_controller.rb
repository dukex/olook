# -*- encoding : utf-8 -*-
class CollectionThemesController < ApplicationController
  respond_to :html, :js
  before_filter :load_products_of_user_size, only: [:show, :filter]
  before_filter :filter_products_by_category
  before_filter :load_catalog_products

  # Toda a lógica dessa página deve ser refeita para dinamizar os dados dela
  def index
    @featured_products = retrieve_featured_products
  end

  def show
    return redirect_to collection_themes_url if !current_admin && !@collection_theme.active
    @chaordic_user = ChaordicInfo.user current_user
    respond_with @catalog_products
  end

  def filter
    return redirect_to collection_themes_url if !current_admin && !@collection_theme.active
    @chaordic_user = ChaordicInfo.user current_user
    respond_to :js
  end

  private

    def load_products_of_user_size
      # To show just the shoes of the user size at the
      # first time that the liquidations page is rendered
      params[:shoe_sizes] = [current_user.shoes_size.to_s] if params[:shoe_sizes].blank? && current_user && current_user.shoes_size
    end

    def filter_products_by_category
      if params[:category_id].blank?
        @category_id = nil
        params.delete(:category_id)
      else
        @category_id = params[:category_id].to_i
      end


      #TODO: Isto está aqui por causa de um problema na CatalogSearchService em
      #filtrar por shoe_size mesmo fora da categoria shoe. E isso faz com que
      #outras categorias voltem vazias
      params.delete(:shoe_sizes) if @category_id != Category::SHOE
    end

    def load_catalog_products

      @collection_theme_groups = CollectionThemeGroup.order(:position).all
      @collection_themes = CollectionTheme.active.order(:position).all
      @collection_theme = params[:slug] ? CollectionTheme.find_by_slug_or_id(params[:slug]) : @collection_themes.last
      if @collection_theme
        # Não podemos apagar o shoe_sizes do params pois na partial dos filtros checa por eles.
        # Esse comportamento é necessário para não filtrar pelo número do usuário quando ele
        # desselecionou no form. E não selecionar no partial.
        # @collection_theme.catalog.id
        params[:brands] = [@collection_theme.name.upcase] if brand_query?
        catalog_search_service_params = params.merge({id: brand_query? ? 1 : @collection_theme.catalog.id, admin: !current_admin.nil?})
        catalog_search_service_params.delete(:shoe_sizes) if params[:shoe_sizes].to_a.all? { |ss| ss.blank? }
        @catalog_search_service = CatalogSearchService.new(catalog_search_service_params)
        if @catalog_search_service.categories_available_for_options(ignore_category: true).size == 2
          params[:category_id] = @catalog_search_service.categories_available_for_options(ignore_category: true).last.last
        end
        @catalog_products = @catalog_search_service.search_products
        @products_id = @catalog_products.first(3).map{|item| item.product_id }.compact
        # params[:id] is into array for pixel iterator
        @categories_id = params[:id] ? [params[:id]] : @collection_themes.map(&:id).compact.uniq
      else
        redirect_to root_path
        flash[:notice] = "No momento não existe nenhuma coleção cadastrada."
      end
    end

    # TODO: Lógica duplicada no model payment onde usa o Product#featured_products
    def retrieve_featured_products
      products = Setting.collection_section_featured_products.split('#')
      products_models = Product.where(id: products.map { |p| p.split('|').last.to_i}).all
      products.map! do |pair|
        values = pair.split('|')
        product = products_models.find { |p| p.id == values[1].to_i }
        if product
          {
            label: values[0],
            product: product
          }
        else
          nil
        end
      end
      products.compact!
      products.select {|h| h[:product].inventory_without_hiting_the_database > 0}
    end

    def brand_query?
      @collection_theme.collection_theme_group.name == "MARCAS"
    end

end
