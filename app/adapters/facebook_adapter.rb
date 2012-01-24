# -*- encoding : utf-8 -*-
class FacebookAdapter
  attr_accessor :access_token, :adapter

  def initialize(access_token, adapter = Koala::Facebook::API)
    @access_token, @adapter = access_token, adapter.new(access_token)
  end

  def friends
    @adapter.get_connections("me", "friends").to_a
  end

  def post_wall_message(message, *args)
    options = args.extract_options!
    @adapter.put_wall_post(message, options[:attachment] || {}, options[:target] || "me", options[:options] || {})
  end
end
