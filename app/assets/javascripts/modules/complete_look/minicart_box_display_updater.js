MinicartBoxDisplayUpdater = function(){

  var showEmptyCartBox = function(){
    $('.cart_related').removeClass('product_added');
    $('.minicart_price').html("");
    $('.empty_minicart').fadeIn("fast");
  };

  var disableSubmitButton = function(){
    $(".js-addToCartButton").attr("disabled", "disabled").addClass("disabled");
  };

  var enableSubmitButton = function(){
    $(".js-addToCartButton").removeAttr("disabled").removeClass("disabled");
  };

  var isCartEmpty = function(){
    return ($( ".js-minicartItem").length == 0);
  };

  return{
    facade: function(){
      if(isCartEmpty()) {
        showEmptyCartBox();
        disableSubmitButton();
      } else {
        enableSubmitButton();
      }
    }
  };

}();

$(function(){
  olookApp.subscribe("minicart:update:box_display", MinicartBoxDisplayUpdater.facade);
});