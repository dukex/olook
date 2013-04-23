# -*- encoding : utf-8 -*-
class FacebookDataService
  def self.facebook_users
    User.where("facebook_token IS NOT NULL AND facebook_permissions LIKE '%birthday%'")
  end

  def generate_csv_lines(month, middle_of_the_month)
      csv_lines = ["email,first_name,auth_token,friend_data"]
      FacebookDataService.facebook_users.each do |user|
        user_hash = format_user_data(user, month, middle_of_the_month) 
        csv_lines << user_hash unless user_hash.blank?
      end
      csv_lines    
  end

  private  

  def format_user_data(user, month, middle_of_the_month)
    adapter = FacebookAdapter.new(user.facebook_token)
    friends = adapter.facebook_friends_with_birthday(month)
    user_hash = {}
    user_hash["email"] = user.email
    user_hash["first_name"] = user.first_name
    user_hash["auth_token"] = user.authentication_token
    friend_data = friends.map{|friend| format_fb_friend_data(friend, middle_of_the_month) }.compact
    user_hash["friend_data"] = friend_data.empty? ? "" : friend_data.join("#")
    friend_data.empty? ? nil : "#{user_hash['email']},#{user_hash['first_name']},#{user_hash['auth_token']},#{user_hash['friend_data']}" 
  end

  def format_fb_friend_data(friend, middle_of_the_month)
    birthday_arr = friend.birthday.split("/")
    friend.birthday = "#{birthday_arr[1]}/#{birthday_arr[0]}"
    friend_hash = JSON.parse(friend.to_json)["table"]
    friend_hash["picture"] = "https://graph.facebook.com/#{friend_hash['uid']}/picture"
    if (middle_of_the_month && birthday_arr[1].to_i > 15) || (!middle_of_the_month && birthday_arr[1].to_i <= 15)
      "#{friend_hash['first_name']}|#{friend_hash['picture']}|#{friend_hash['birthday']}"
    else
      nil
    end    
  end
end
