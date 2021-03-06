var ProductAvailableNoticeEmailSubmitter  = (function(){
  function ProductAvailableNoticeEmailSubmitter() {};

  var alreadyClicked = false;

  var isAlreadyClicked = function(){
    var response = alreadyClicked;
    alreadyClicked = true;
    return response;
  };

  ProductAvailableNoticeEmailSubmitter.prototype.config = function(){
    olookApp.subscribe('product_available_notice:submit_email', this.facade, {}, this);
    $(".js-product_available_notice_submit").click(function(){
      if(isAlreadyClicked()){
        return false;
      }
      var data = $(this).data();
      olookApp.publish('product_available_notice:submit_email', data);
    });

    $(".js-product_available_notice_form").submit(function(){
      if(isAlreadyClicked()){
        return false;
      }
      var data = $(".js-product_available_notice_submit").data();
      olookApp.publish('product_available_notice:submit_email', data);
      return false;
    });
  };

  ProductAvailableNoticeEmailSubmitter.prototype.facade = function(data){
    var email = $(".js-product_available_notice_email").val();
    var productId = data.productId;
    var productColor = data.productColor;
    var productSubcategory = data.productSubcategory;

    $.ajax({
      url: '/api/v1/product_interest',
      type: 'post',
      data: {
        "email": email,
        "product_id": productId,
        "product_color": productColor,
        "product_subcategory": productSubcategory
      },
      headers: {
        'Authorization': 'Token token=' + AUTH.token
      },
      dataType: 'json'

    }).done(function() {
        olookApp.publish('product_available_notice:display_success_message');
      }).fail(function(){
        olookApp.publish('product_available_notice:display_error_message');
      });
  };

  return ProductAvailableNoticeEmailSubmitter;
})();
