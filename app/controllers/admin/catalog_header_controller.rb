# encoding: utf-8
class Admin::CatalogHeaderController < Admin::BaseController
  load_and_authorize_resource
  respond_to :html, :text

  def index
    @catalog_headers = CatalogHeader::CatalogHeader.all
  end

  def show
    @catalog_header = CatalogHeader::CatalogHeader.find(params[:id])
  end

  def new
    @catalog_header = CatalogHeader::CatalogHeader.new
  end

  def edit
    @catalog_header = CatalogHeader::CatalogHeader.find(params[:id])
  end

  def create
    @catalog_header = CatalogHeader::CatalogHeader.new(params[:catalog_header])
    if @catalog_header.save
      redirect_to [:admin, @catalog_header], notice: ""
    else
      render action: "new"
    end

  end

  def update
    @catalog_header = CatalogHeader::CatalogHeader.find(params[:id])
    if @catalog_header.update_attributes(params[:catalog_header])
      redirect_to [:admin, @catalog_header], notice: ''
    else
      render action: "edit"
    end

  end

  def destroy
    @catalog_header = CatalogHeader::CatalogHeader.find(params[:id])
    @catalog_header.destroy
    redirect_to admin_catalog_headers_url
  end
end
