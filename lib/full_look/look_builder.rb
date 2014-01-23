module FullLook
  class LookBuilder
    attr_accessor :category_weight
    @queue = 'look'

    PRODUCTS_MINIMUN_QTY = 2
    MINIMUM_INVENTORY = 1
    ALLOWED_BRANDS_REGEX = /^olook/i

    def self.perform
      self.new.perform
    end

    def initialize
      set_category_weight_factor
    end

    def perform
      delete_previous_looks

      look_structure.each do |master_product_id, struc|
        master_product = struc[:master_product]
        look = {}
        look[:product_id] = master_product_id
        master_product.full_look_picture.image.recreate_versions!
        master_product.full_look_picture.save
        look[:full_look_picture] = master_product.full_look_picture.try(:look_showroom_image_url)
        master_product.front_picture.image.recreate_versions!
        master_product.full_look_picture.save
        look[:front_picture] = master_product.front_picture.try(:look_showroom_image_url)
        look[:launched_at] = master_product.launch_date
        look[:profile_id] = LookProfileCalculator.calculate(struc[:products], category_weight: category_weight)
        Look.build_and_create(look)
      end
    end

    def delete_previous_looks
      Look.delete_all
    end

    private

    def look_structure
      looks = normalize_products(related_products)
      filter_looks(looks)
    end

    def filter_looks(looks)
      looks.select do |master_product_id, look|
        look[:products].size >= PRODUCTS_MINIMUN_QTY &&
        look[:brands].all? { |b| ALLOWED_BRANDS_REGEX =~ b } &&
        look[:inventories].all? { |i| i >= MINIMUM_INVENTORY } &&
        look[:is_visibles].all? &&
        !look[:master_product].full_look_picture.nil? &&
        !look[:master_product].front_picture.nil?
      end
    end

    def related_products
      cloth_products = Product.cloths.pluck(:id)
      RelatedProduct.with_products(cloth_products).all
    end

    def normalize_products(products)
      products.inject({}) do |h, rp|
        h[rp.product_a_id] ||= {
          master_product: rp.product_a,
          products: [rp.product_a],
          brands: [rp.product_a.brand],
          inventories: [rp.product_a.inventory],
          is_visibles: [rp.product_a.is_visible]
        }
        key = h[rp.product_a_id]

        key[:products].push(rp.product_b)
        key[:brands].push(rp.product_b.brand)
        key[:inventories].push(rp.product_b.inventory)
        key[:is_visibles].push(rp.product_b.is_visible)

        h
      end
    end

    def set_category_weight_factor
      @category_weight = Hash.new(1)
      @category_weight[ Category::CLOTH ] = Setting.look_cloth_category_weight
      @category_weight[ Category::ACCESSORY ] = Setting.look_accessory_category_weight
      @category_weight[ Category::SHOE ] = Setting.look_shoe_category_weight
      @category_weight[ Category::BAG ] = Setting.look_bag_category_weight
    end
  end
end
