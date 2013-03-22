class ConsolidatedSell < ActiveRecord::Base

  def self.get_consolidated_record category, subcategory, day
    consolidated = where("category = ? and subcategory = ? and day = ?", category, subcategory, day).first
    if consolidated.nil? 
      create(category: category, subcategory: subcategory, day: day, amount: 0, total: 0, total_retail: 0)
    else
      consolidated
    end
  end

  def self.summarized_report_for day
    where(day: day).order(:category, :subcategory)
  end

  def self.summarize variant, amount
    product = variant.product

    day = Date.today
    category = product.category
    subcategory = product.subcategory

    consolidated = get_consolidated_record category, subcategory, day
    consolidated.amount += amount
    consolidated.total += amount * product.price
    consolidated.total_retail += amount * product.price
    consolidated.save!
  end

end
