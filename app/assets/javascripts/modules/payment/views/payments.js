app.views.Payments = Backbone.View.extend({
  template: _.template($('#tpl-payment-list').html()||""),
  className: 'payments',
  initialize: function(opts) {
    this.paymentDetails = $('<div class="payment-details"></div>');
    this.cart = opts['cart'];
    this.collection.on('add', this.addOne, this);
    this.collection.on('reset', this.addAll, this);
  },
  addOne: function(payment){
    var paymentView = new app.views.Payment({model: payment});
    this.$el.append(paymentView.render().el);
    
    var paymentMethod = this.cart.get('payment_method');
    if(paymentMethod == payment.attributes.type){ 
      this.$el.find("."+paymentMethod+" input").attr("checked", "checked");
    }    
  },
  addAll: function(){
    this.collection.forEach(this.addOne, this);
  },
  remove: function() {
    Backbone.View.prototype.remove.apply(this, arguments); //super()
    this.paymentDetails.remove();
  },
  render: function(){
    this.$el.html(this.template({}));
    this.addAll();
    this.$el.after(this.paymentDetails); 
  },
});