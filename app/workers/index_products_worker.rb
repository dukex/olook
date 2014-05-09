# -*- encoding : utf-8 -*-
class IndexProductsWorker
  @queue = 'low'
  
  def self.perform
    d0 = Time.now.to_i
    indexer = ProductIndexer.new(Product.pluck(:id), ProductProductDocumentAdapter.new)
    indexer.index
    d1 = Time.now.to_i

    puts "Total time = #{d1-d0}"

    mail = DevAlertMailer.notify_about_products_index(d1-d0, indexer.adapter.log.join("\n"))
    mail.deliver
  end

end
