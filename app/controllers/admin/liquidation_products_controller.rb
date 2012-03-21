class Admin::LiquidationProductsController < Admin::BaseController
  before_filter :load_liquidation

  def index
    @products = @liquidation.liquidation_products.group(:product_id)
  end

  def show
    @liquidation_product = LiquidationProduct.find(params[:id])
  end
  
  def create
    @liquidation_service = LiquidationService.new(@liquidation.id)
    @liquidation_service.add(
      params[:liquidation_products][:products_ids],
      params[:liquidation_products][:discount_percent]
    )
    verify_exception_products
    redirect_to admin_liquidation_products_path(@liquidation.id)
  end

  def edit
    @liquidation_product = LiquidationProduct.find(params[:id])
  end
  
  def update
    @liquidation_product = LiquidationProduct.find(params[:id])
    @liquidation_service = LiquidationService.new(@liquidation.id)
    @liquidation_service.update(@liquidation_product.product_id, params[:liquidation_product])
    verify_exception_products
    redirect_to admin_liquidation_products_path(@liquidation.id)
  end

  def destroy
    @liquidation_product = LiquidationProduct.find(params[:id])
    if LiquidationProduct.where(:product_id => @liquidation_product.product_id, :liquidation_id => @liquidation.id).delete_all
      LiquidationService.new(@liquidation).update_resume
      flash[:notice] = "Product removed from liquidation"
    else
      flash[:notice] = "There was an error removing the product"
    end
    redirect_to admin_liquidation_products_path(@liquidation.id)
  end

  private
  
  def verify_exception_products
    if @liquidation_service.denied_products_ids.empty? && @liquidation_service.nonexisting_products_ids.empty?
      flash[:notice] = "Products added"
    else
      flash[:warning] = "The was an error adding some products. <br/>
       Products that are going to be part of a collection during the liquidation period: #{@liquidation_service.denied_products_ids} <br/>
       Nonexisting products: #{@liquidation_service.nonexisting_products_ids} ".html_safe
    end
  end

  def load_liquidation
    @liquidation = Liquidation.find(params[:liquidation_id])
  end

end
