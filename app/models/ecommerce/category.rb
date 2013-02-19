# -*- encoding : utf-8 -*-
class Category < EnumerateIt::Base
  associate_values(
    :shoe       => 1,
    :bag        => 2,
    :accessory  => 3,
    :cloth      => 4
  )

  def self.list_of_all_categories
    [Category::SHOE,Category::BAG,Category::ACCESSORY,Category::CLOTH]
  end
end
