# -*- encoding : utf-8 -*-
class FacebookDataService
  include Celluloid

  DESTINATION_FOLDER = "/tmp/fb_csv/"

  def initialize
  end

  # def generate_facebook_friends_birthdays_csv_list(user)
  #   #fb_tokens = facebook_tokens
  #   # users.find_each do |user|
  #   birthdays = friends_birthdays(user)
  #   format_to_csv(birthdays) unless birthdays.empty?
  #   # end
  # end
  # Retrieves all facebook tokens present in the database
  def self.facebook_users
    User.where("facebook_token IS NOT NULL")
  end

  # Retrieves all facebook friends' birthdays of the given users
  def friends_birthdays users
    birthdays = []
    users.each do |user|
      # puts "processing #{user.name}"
      adapter = FacebookAdapter.new(user.facebook_token)
      friends = adapter.facebook_friends_with_birthday(DateTime.now.month)
      friends.each do |friend|
        birthday_arr = friend.birthday.split("/")
        friend.birthday = "#{birthday_arr[1]}/#{birthday_arr[0]}"
        friend_hash = JSON.parse(friend.to_json)["table"]
        friend_hash["friend_email"] = user.email
        birthdays << friend_hash
      end
      puts "(#{user.id}) #{user.name} => success! #{friends.size} friends!"
    end

    puts "Saving file - #{users.first.id}-#{users.last.id}.csv"
    save_file(format_to_csv(birthdays), "#{users.first.id}-#{users.last.id}.csv") unless birthdays.empty?
  end

  def format_to_csv hashes
    fields = hashes.first.keys

    # mounts header
    csv_header = fields.join(',')

    csv_body = hashes.map do |entry|
      arr = []
      fields.each{|field| arr << entry[field]}
      arr.join(',')
    end

    csv_header+"\n"+(csv_body.join("\n"))
  end

  def save_file(csv, name)
    File.open("#{DESTINATION_FOLDER}#{name}.csv", 'w') do |file|
      file.puts csv
    end
  end

  def self.clean_destination_folder
    FileUtils.rm_rf(DESTINATION_FOLDER)
    FileUtils.mkdir_p(DESTINATION_FOLDER)
  end

end
