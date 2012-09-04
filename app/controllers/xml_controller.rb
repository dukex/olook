class XmlController < ApplicationController
  respond_to :xml
  before_filter :load_products

  def criteo
    respond_with(@products)
  end

  def mt_performance
    respond_with(@products)
  end

  def click_a_porter
    respond_with(@products)
  end

  def topster
    respond_with(@products)
  end

  def netaffiliation
    respond_with(@products)
  end

  private

  def load_products
    @products = Product.valid_for_xml
  end

end
