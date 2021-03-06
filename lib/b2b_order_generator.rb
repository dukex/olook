class B2bOrderGenerator
  include Abacos::Helpers

  def validate_parameters(opts, file_path)
    blanks = [:document, :customer, :name, :email].select{|key| opts[key].blank?}
    
    if (blanks.any? || file_path.nil?)
      {error: 'Todos os parâmetros são obrigatórios'}
    else
      {}
    end
  end


  def run(opts={}, file_path=nil)

    errors = validate_parameters(opts, file_path)
    return errors if errors.any?


    cart = create_cart
    
    variants = load_csv(file_path)
    variants.each do |values|
      add_items(cart, values)
    end

    cs = CartService.new(cart: cart)
    cs.prefered_shipping_services =  '1'

    begin
      order = cs.generate_order!(1)

      payment = B2bPayment.create({
        receipt: Payment::RECEIPT, 
        total_paid: order.subtotal, 
        order: order, 
        user_id: cart.user.id, 
        cart_id: cart.id})

      pedido = Abacos::Pedido.new order

      # altera os valores do pedido
      pedido.instance_variable_set "@codigo_cliente", opts[:customer]
      pedido.instance_variable_set "@cpf", parse_cnpj(opts[:document])
      pedido.instance_variable_set "@nome", opts[:name]
      pedido.instance_variable_set "@email", opts[:email]

      # necessario
      Abacos::OrderAPI.insert_order pedido
      {order: order.number}
    rescue => e
      Rails.logger.error(e)
      msg = e.message.match(/Msg = (.*)\n/).captures.first
      {order: order.number, error: msg}
    end
  end


  def load_csv filename=nil
    values = []
    CSV.foreach(filename, {col_sep: ';', headers: :first_row, skip_blanks: true} ) do |row|
      values << [row[1], row[2], row[3]]
    end
    values
  end  

  def create_cart
    cart = Cart.new
    user = User.find_by_email "rafael.manoel@olook.com.br"
    cart.user = user
    cart.address = user.addresses.first
    cart.save
    cart
  end

  def add_items cart, values

    not_found = []

    variant_number = values[0]
    amount = values[1].to_i

    return if amount == 0

    price = values[2].gsub(",",".").to_d

    v = Variant.find_by_number(variant_number)

    if v.nil?
      not_found << variant_number
    else
      item = cart.items.select { |item| item.variant.number == v.number }.first
      amount = item.nil? ? amount : item.quantity + amount

      Cart.skip_callback(:validation, :after, :update_coupon)
      CartItem.skip_callback(:create, :after, :notify)
      CartItem.skip_callback(:update, :after, :notify)
      CartItem.skip_callback(:destroy, :after, :notify)

      current_item =  CartItem.create(:cart_id => cart.id,
                                   :variant_id => v.id,
                                   :quantity => amount)

      current_item.cart_item_adjustment.update_attribute(:value, amount * (v.retail_price - price))
      
      cart.items << current_item



      CartItem.set_callback(:update, :after, :notify)
      CartItem.set_callback(:destroy, :after, :notify)    
      CartItem.set_callback(:create, :after, :notify)
      Cart.set_callback(:validation, :after, :update_coupon)
    end

    Cart.skip_callback(:update, :after, :notify_listener)
    cart.save
    Cart.set_callback(:update, :after, :notify_listener)

  end

end