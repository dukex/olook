//= require modules/login/views/form
//= require modules/login/models/user

var LoginController = (function() {
  function LoginController() {
    this.loginForm = new app.views.loginForm();
  };

  LoginController.prototype.config = function () {
    this.loginForm.render();
  };

  return LoginController;
})();

olookApp.subscribe('app:init', function() {
  new LoginController().config();
});
