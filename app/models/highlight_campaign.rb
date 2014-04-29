# -*- encoding : utf-8 -*-
class HighlightCampaign < ActiveRecord::Base
  attr_accessible :label, :product_ids
  validates :label, presence: true

  scope :newest, -> {order('created_at DESC')}

  def self.find_campaign campaign_name
    Rails.logger.info "Looking for campaign_name #{campaign_name}"

    sanitized_campaign_name = campaign_name ? campaign_name.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '') : ""

    campaign = find_by_label(sanitized_campaign_name) || dummy_campaign
    Rails.logger.info "found campaign=#{campaign.inspect}"
    campaign
  end

  def has_products?
    products.any?
  end

  def cache_key
    get_search_engine.cache_key
  end

  def products 
    get_search_engine.products
  end

  private
    def self.dummy_campaign
      OpenStruct.new({products: [], cache_key: nil, product_ids: ""})
    end

    def get_search_engine
      @search ||= SearchEngine.new(product_id: product_ids).with_limit(1000)
      @search
    end
end
