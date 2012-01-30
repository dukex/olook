$(document).ready(function() {
  ShowroomInit.slideProductAnchor();

  $("#showroom div.products_list a.more").live("click", function() {
    el = $(this).attr('rel');
    box = $(this).parents('.type_list').find("."+el);
    if(box.is(":visible") == false) {
      box.slideDown();
      container_position = $(box).position().top;
      ShowroomInit.slideToProductsContainer(container_position);
    } else {
      box.slideUp();
      topBox = $(this).parent(".products_list");
      container_position = $(topBox).position().top;
      ShowroomInit.slideToProductsContainer(container_position);
    }
  });

  $("div#mask_carousel_showroom ul").carouFredSel({
    height: 186,
    auto : {
      pauseDuration : 15000
    },
    prev : {
      button : ".carousel-prev",
      key : "left"
    },
    next : {
      button : ".carousel-next",
      key : "right"
    }
  });
});

ShowroomInit = {
  slideProductAnchor : function() {
    anchor = window.location.hash;
    container = $(anchor+"_container");
    if($(container).length > 0) {
      container_position = $(container).position().top;
      position = container_position - 40;
      $("html, body").animate({
        scrollTop: position
      }, 'slow');
    }
  },

  slideToProductsContainer : function(container_position) {
    position = container_position - 100;
    $("html, body").animate({
      scrollTop: position
    }, 'fast');
  }
};
