# -*- encoding : utf-8 -*-

class ShowroomReadyNotificationWorker
  @queue = :showroom_ready_mailer

  def self.perform(user_id)
    user = User.find(user_id)
    mail = MemberMailer.showroom_ready_email(user)
    mail.deliver
  end

end