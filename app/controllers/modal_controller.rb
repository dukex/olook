class ModalController < ApplicationController
  before_filter :manager_cookies
  layout false
  def show
    if ModalExhibitionPolicy.apply?(path: params["path"], cookie: cookies[:sm], user: current_user, mobile: mobile?)
      partial_name = cookies[:sm] == 0 ? 'show1.html.erb' : 'show2.html.erb'
      render json: {html: render_to_string(partial: partial_name), width: "493",height: "764", color: "#fff" }
    else
      render text: "",status: 401
    end
  end

  private

  def manager_cookies
    increment if cookies[:sm]
    set if cookies[:sm].blank?
  end

  def set
    cookies[:sm] = {
       :value => 0,
       :expires => 1.day.from_now
     }
  end

  def increment
    number = cookies[:sm].to_i
    cookies[:sm] = {
       :value => number += 1
     }
  end
end
