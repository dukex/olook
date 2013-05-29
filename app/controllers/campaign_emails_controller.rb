class CampaignEmailsController < ApplicationController
  layout "campaign_emails"

  def new
    @campaign_text = @cart.coupon.try(:modal) || 1
    @campaign_email = CampaignEmail.new
  end

  def create
    if @user = User.find_by_email(params[:campaign_email][:email])
      redirect_to login_campaign_email_path @user
    else
      if @campaign_email = CampaignEmail.find_by_email(params[:campaign_email][:email])
        redirect_path =  remembered_campaign_email_path(@campaign_email)
      elsif @campaign_email = CampaignEmail.create!(email: params[:campaign_email][:email])
        @campaign_email.set_utm_info session[:tracking_params]
        redirect_path = campaign_email_path(@campaign_email)
      end
      cookies['newsletterUser'] = { value: '1', path: '/', expires: 30.years.from_now }
      cookies['ceid'] = { value: "#{@campaign_email.id}", path: '/', expires: 30.years.from_now }
      redirect_to redirect_path
    end
  end

  def login
      @user = User.find(params[:id])
  end

  def show
    @campaign_email = CampaignEmail.find(params[:id])
  end

  def remembered
    @campaign_email = CampaignEmail.find(params[:id])
  end

end
