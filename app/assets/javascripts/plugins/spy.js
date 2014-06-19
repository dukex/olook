if(!olook) var olook = {};
olook.getCss = function(url, callback){
  $.get(url, function(){
    $('<link>', {rel:'stylesheet', type:'text/css', 'href':url}).appendTo('head');
    if (typeof callback=='function') callback();
  });
}
olook.getCachedScript = function(url) {
  $.ajax({
    dataType: "script",
    cache: true,
    url: url
  });
}
olook.loadSpyContent = function(dataHtml) {
  var width = $(document).width(), height = $(document).height();
  $('#overlay-campaign').width(width).height(height).fadeIn();

  initQuickView.inQuickView = true;
  $('#ajax-loader').hide();
  if($("div#quick_view").size() == 0) {
    $("body").prepend("<div id='quick_view'></div>");
  }
  $('#quick_view')
  .html(dataHtml)
  .css("top", $(window).scrollTop()  + 35)
  .fadeIn(100);

  $('#quick_view ol.colors li a').attr('data-remote', true);
  $("ul.social li.email").hide();

  $('#close_quick_view, #overlay-campaign').off('click').on("click", function() {
    olook.closeSpy();
  });

  accordion();
  delivery();
  guaranteedDelivery();

  load_first_image();
  load_all_other_images();

  if (typeof initSuggestion != 'undefined') {
    initSuggestion.checkIfProductIsAlreadySelected();
  }
  initQuickView.productZoom();

  try{
    FB.XFBML.parse();
  }catch(ex){}
}
olook.closeSpy = function() {
  $('#quick_view, #overlay-campaign').fadeOut(300, function(){
    $('#quick_view').remove();
  });
}
olook.spy = function(selector){
  $(selector).click(function(e){
    e.preventDefault();
    var url = $(this).data('url');
    if(_gaq){
      var source = url.match(/from=(\w+)/);
      if(source){
        source = source[1];
      } else {
        source = 'Product';
      }
      _gaq.push(['_trackEvent', source, 'clickOnSpyProduct', url.replace(/\D/g, '')]);
    }
    $.ajax({
      url: url,
      cache: 'true',
      dataType: 'html',
      beforeSend: function() {
        var width = $(document).width(), height = $(document).height();
        $('#overlay-campaign').width(width).height(height).fadeIn();
        $('#ajax-loader').fadeIn();
      },
      success: function(dataHtml) {
        var script = $(dataHtml).filter('script:first').attr('src');

        if(typeof initProduct !== 'undefined') {
          initProduct.loadAddToCartForm();
        } else {
          olook.getCachedScript(script);
        }

        var style = $(dataHtml).filter('link[rel="stylesheet"]:first').remove();

        if($('head link[href="' + style.attr('href') + '"]').length == 0) {
          olook.getCss(style.attr('href'), function(){
            olook.loadSpyContent(dataHtml);
          });
          $('head').append(style);
        } else {
          olook.loadSpyContent(dataHtml);
        }

      },
      error: function() {
        window.location = url;
      }
    });
  }).mouseover(function() {
    var img = $(this).parent(".product").find("img");
    img.attr('src', img.data('backside-picture'));
  }).mouseout(function() {
    var img = $(this).parent(".product").find("img");
    img.attr('src', img.data('product'));
  });
};
