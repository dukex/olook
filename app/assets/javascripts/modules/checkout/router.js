app.routers.CheckoutRouter = Backbone.Router.extend({
  initialize: function(opts) {
    this.session = opts['session'];
    this.session.on('sync', this.checkStep, this);
    this.cart = opts['cart'];
  },
  stepsTranslation: {
    login: "login",
    address: "endereco",
    payment: "pagamento",
    confirmation: "confirmacao",
  },
  routes: {
    "login": "loginStep",
    "endereco": "addressStep",
    "pagamento": "paymentStep",
    "confirmacao": "confirmationStep",
  },
  start: function() {
    this.session.fetch();
    Backbone.history.start();
  },
  translateStep: function(step) {
    return this.stepsTranslation[step] || "";
  },
  checkStep: function() {
    var userId = this.session.id;
    if (userId) {
      var currentRoute = this.routes[Backbone.history.fragment];
      if(!currentRoute) {
        this.navigate("endereco", {trigger: true});
      }
    } else {
      this.navigate("login", {trigger: true});
    }
  },
  loginStep: function() {
    this.hideSteps();
    this.cart.set("step", "login");
    if(!this.loginController){
      this.facebookAuth = new FacebookAuth();
      this.facebookAuth.config();
      this.loginController = new LoginController({cart: this.cart});
      this.loginController.config();
    }
  },
  addressStep: function() {
    this.hideSteps();
    this.cart.set("step", "address");
    this.initializeCartResume();
    if(!this.addressController){
      this.addressController = new AddressController({cart: this.cart});
      this.addressController.config();
    }
  },
  paymentStep: function() {
    this.hideSteps();
    this.cart.set("step", "payment");
    this.initializeCartResume();
  },
  confirmationStep: function() {
    this.hideSteps();
    this.cart.set("step", "confirmation");
    this.initializeCartResume();
  },
  hideSteps: function() {
    if(this.cartResume) {
      this.cartResumer.remove();
      delete this.cartResume;
    }
    if(this.loginController) {
      this.loginController.remove();
      delete this.loginController;
    }
    if(this.addressController) {
      this.addressController.remove();
      delete this.addressController;
    }
  },
  initializeCartResume: function() {
    if(this.cartResume) return;
    this.cartResume = new CartResumeController({cart: this.cart});
    this.cartResume.config();
  },
});
