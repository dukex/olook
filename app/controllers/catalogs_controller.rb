# -*- encoding : utf-8 -*-
require 'new_relic/agent/method_tracer'

class CatalogsController < ApplicationController
  include ::NewRelic::Agent::MethodTracer

  layout "lite_application"
  prepend_before_filter :verify_if_is_catalog
  helper_method :header
  DEFAULT_PAGE_SIZE = 48

  def add_campaign(params)
    HighlightCampaign.find_campaign(params[:cmp])  
  end

  def add_search_result(search_params, params)
    page_size = params[:page_size] || DEFAULT_PAGE_SIZE
    search = SearchEngineWithDynamicFilters.new(search_params, true)
      .for_page(params[:page])
      .with_limit(page_size)

    search.for_admin if current_admin
    search
  end

  def index
    search_params = SeoUrl.parse(path: request.fullpath, path_positions: '/:category:/:subcategory:-:brand:/:care:_:color:_:size:_:heel:')
    Rails.logger.debug("New params: #{params.inspect}")

    @campaign = add_campaign(params)
    @search = add_search_result(search_params, params)
    @url_builder = SeoUrl.new(path: request.fullpath, path_positions: '/:category:/:subcategory:-:brand:/:care:_:color:_:size:_:heel:', search: @search)
    @chaordic_user = ChaordicInfo.user(current_user,cookies[:ceid])
    @pixel_information = @category = params[:category]
    @cache_key = "catalogs#{request.path}|#{@search.cache_key}#{@campaign.cache_key}"
    @category = @search.expressions[:category].to_a.first.downcase
    @subcategory = @search.expressions[:subcategory].to_a.first
    params[:category] = @search.expressions[:category].to_a.first

    @url_builder.set_link_builder do |_param|
      _param.slice!("#{@category}-")
      catalog_path(@category, _param)
    end
    expire_fragment(@cache_key) if params[:force_cache].to_i == 1
  end

  add_method_tracer :parse_parameters_from, 'Custom/CatalogsController/parse_parameters_from'
  add_method_tracer :add_campaign, 'Custom/CatalogsController/add_campaign'
  add_method_tracer :add_search_result, 'Custom/CatalogsController/add_search_result'

  private
    
    def header
      @header ||= Header.for_url(request.path).first
    end

    def title_text
      if header && header.title_text.present?
        Seo::SeoManager.new(request.path, model: header).select_meta_tag
      else
        Seo::SeoManager.new(request.path, search: @search).select_meta_tag
      end
    end

    def canonical_link
      host =  "http://#{request.host_with_port}/"
      if @subcategory
        "#{host}#{@category}/#{@subcategory.downcase}"
      else
        "#{host}#{@category}"
      end
    end

    def meta_description
      Seo::DescriptionManager.new(description_key: @subcategory.blank? ? @category : @subcategory).choose
    end

    def verify_if_is_catalog
      #TODO Please remove me when update Rails version
      #We can use constraints but this version (3.2.13) has a bug

      if (/^(sapato|bolsa|acessorio|roupa|curves)/ =~ params[:category]).nil?
        render :template => "/errors/404.html.erb", :layout => 'error', :status => 404, :layout => "lite_application"
      end
    end  
end
