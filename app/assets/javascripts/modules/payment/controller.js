//= require modules/payment/models/payment
//= require modules/payment/collections/payments
//= require modules/payment/views/payment
//= require modules/payment/views/payments
var PaymentController = (function(){
  function PaymentController(){
    this.payments = new app.collections.Payments();
    this.paymentsView = new app.views.Payments({collection: this.payments});
  };

  PaymentController.prototype.config = function(){
    this.paymentsView.$el.appendTo(app.content);
    this.paymentsView.render();
    this.payments.fetch();    
  };
  return PaymentController;
})();

olookApp.subscribe('app:init', function(){
  new PaymentController().config();
});

olookApp.subscribe('payment:selected', function(model) {
  alert(
    "Você selecionou o Pagamento " +
    model.attributes.name);
});
