//= require plugins/slider
//= require plugins/spy
//= require plugins/toggle_class_slide_next
//= require plugins/custom_select
//= require plugins/change_picture_onhover
//= require plugins/jquery.meio.mask

var filter = {};
filter.init = function(){
  if(typeof start_position == 'undefined') start_position = 0;
  if(typeof final_position == 'undefined') final_position = 600;
  olook.slider('#slider-range', start_position, final_position);
  olook.spy('p.spy');
  olook.changePictureOnhover('.async');
  olook.customSelect(".custom_select");
  olook.toggleClassSlideNext(".title-category");

  $("a.mercado_pago_button").click(function(e){
      content = $("div.mercado_pago");
      olook.newModal(content, 640, 800);
  });

  $("form.js-size-select").submit(function(e){
      e.preventDefault();
      window.location = $( "#tamanho" ).val();
  });

  $('.hot_products li.product').find('p.spy,a.product_link').click(function(){
    log_event('click', 'hot_products', {'productId': $(this).attr('rel')});
  });
}

$(filter.init);


loadThumbnails = function() {
  new ImageLoader().load("async");
}

window.addEventListener('load', loadThumbnails);
