# -*- encoding : utf-8 -*-
class Gift::RecipientsController < Gift::BaseController
  layout 'gift'

  before_filter :load_recipient

  def edit
    profile_id = params[:gift_recipient][:profile_id] if params.include?(:gift_recipient)
    @profiles = @gift_recipient.ranked_profiles(profile_id)
    @main_profile = profile_id ? @profiles.first : (@gift_recipient.try(:profile) || @profiles.first)
    product_finder_service = ProductFinderService.new(@gift_recipient)
    @products = product_finder_service.showroom_products(:description => @gift_recipient.shoe_size, :not_allow_sold_out_products => true)
  end

  def update
    if @gift_recipient.update_shoe_size_and_profile_info(params[:gift_recipient])
      redirect_to gift_recipient_suggestions_path(@gift_recipient)
    else
      flash[:notice] = "Por favor, escolha o número de sapato da sua presenteada."
      redirect_to edit_gift_recipient_path(@gift_recipient)
    end
  end

  private

  def load_recipient
    @gift_recipient = GiftRecipient.find(params[:id])
  end

  def profile_and_shoe
    params[:gift_recipient].slice(:shoe_size, :profile_id) if params.include?(:gift_recipient)
  end

end
