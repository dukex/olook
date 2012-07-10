class LiquidationProductService
  SUBCATEGORY_TOKEN, HEEL_TOKEN = "Categoria", "Salto/Tamanho"
    
  def self.retail_price product
    price = product.price
    if product.liquidation?
      liquidation_product = LiquidationService.active.liquidation_products.where(:product_id => product.id).first
      price = liquidation_product.retail_price if liquidation_product
    end
    price
  end

  def self.discount_percent product
    if product.liquidation?
      liquidation_product = LiquidationService.active.liquidation_products.where(:product_id => product.id).first
      liquidation_product.discount_percent.to_i if liquidation_product
    end
  end

  def self.liquidation_product product
    LiquidationService.active.liquidation_products.where(:product_id => product.id).first
  end

  def initialize liquidation, product, discount_percent=nil, collections=[]
    @liquidation = liquidation
    @product = product
    @discount_percent = discount_percent
    @collections = collections
  end

  def save
    return false if conflicts_collections?
    if shoe? and not shoe_sizes.empty?
      save_shoe_by_size
    else
      create_or_update_product
    end
  end
  
  def conflicts_collections?
    @collections.map{|c| c.id }.include? @product.collection_id
  end
  
  def retail_price
    (@product.price * (100 - @discount_percent.to_f)) / 100
  end
  
  def liquidation_name
    @liquidation.name if included?
  end  
  
  def subcategory_name
    detail_by_token SUBCATEGORY_TOKEN
  end

  def heel
    detail_by_token HEEL_TOKEN
  end

  
  private
  
  def save_shoe_by_size
    shoe_sizes.each do |variant|
      create_or_update_product(:shoe_size => variant[:shoe_size],
                               :heel => heel.try(:parameterize),
                               :heel_label => heel,
                               :inventory => variant[:inventory],
                               :variant_id => variant[:id]
                               )
    end
  end
  
  def default_params
    {
      :liquidation_id => @liquidation.id,
      :product_id => @product.id,
      :category_id => @product.category,
      :subcategory_name => subcategory_name.try(:parameterize),
      :subcategory_name_label => subcategory_name,
      :original_price => @product.price,
      :retail_price => retail_price,
      :discount_percent => @discount_percent,
      :variant_id => (last_variant.id if last_variant),
      :inventory => (last_variant.inventory if last_variant)
    }
  end
  
  def existing_product options=nil
    params = {
      :liquidation_id => @liquidation.id,
      :product_id => @product.id
    }
    if options
      options.delete(:inventory)
      params.merge! options
    end
    LiquidationProduct.where(params).first
  end

  def create_or_update_product options=nil
    params = default_params
    params.merge!(options) if options
    if existing_product(options)
      massive_update!(params)
    else
      LiquidationProduct.create(params)
    end
  end
  
  def massive_update! params
    LiquidationProduct.where(:product_id => @product.id).update_all(:discount_percent => @discount_percent,
    :retail_price => retail_price)
  end

  def included?
    @liquidation.resume[:products_ids].include? @product.id if @liquidation && @liquidation.resume
  end

  def last_variant
    @product.variants.last
  end

  def detail_by_token token
    detail = @product.details.where(:translation_token => token).last
    detail.description if detail
  end

  def shoe_sizes
    @product.variants.map{|v| {:shoe_size => v.description.to_i, :inventory => v.inventory, :id => v.id } } if shoe?
  end

  def shoe?
    @product.category == Category::SHOE
  end
end
