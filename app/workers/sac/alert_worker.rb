# -*- encoding : utf-8 -*-
module SAC
  class AlertWorker
    @queue = :SAC_notifications

    def self.perform(kind, id)
      case kind.to_s
      when "order"
        AlertForBillet.perform(id)
        AlertForFraud.perform(id)
      end
    end
  end
end