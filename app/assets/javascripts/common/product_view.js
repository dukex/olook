$(function() {
  var stringDesc = $("div#infos div.description p.description").text();
  initQuickView.sliceDesc(stringDesc);
  initQuickView.productZoom();
  initQuickView.twitProduct();
  initQuickView.pinProduct();
  initQuickView.shareProductOnFacebook();

  /** MODAL GUIA DE MEDIDAS **/
  $(".size_guide a").click(function(e){
    initBase.newModal($("#modal_guide"));
    e.preventDefault();
    
  })

  $("div#infos div.description p[class!='price'] a.more").live("click", function() {
    el = $(this).parent();
    el.text(stringDesc);
    el.append("<a href='javascript:void(0);' class='less'>Esconder</a>");
  });

  $("div#infos div.description p[class!='price'] a.less").live("click", function() {
    initQuickView.sliceDesc(stringDesc);
  });

  $("div#pics_suggestions ul#thumbs li a").live("click", function() {
    rel = $(this).attr('rel');
    $("div#pics_suggestions div#full_pic ul li").hide();
    $("div#pics_suggestions div#full_pic ul li."+rel).show();
    return false;
  });

  $("div#box_tabs ul.tabs li a").live("click", function() {
    rel = $(this).attr("rel");
    $(this).parents("ul").find("li a").removeClass("selected");
    contents = $(this).parents("div#box_tabs").find("ul.tabs_content li");
    contents.removeClass("selected");
    $(this).addClass("selected");
    contents.each(function(){
      if($(this).hasClass(rel) == true) {
        $(this).addClass("selected");
      }
    });
    return false;
  });

  $("div#infos div.size ol li").live('click', function() {
    if($(this).hasClass("unavailable") == false) {
      lists = $(this).parents("ol").find("li");
      lists.find("input[type='radio']").attr('checked', false);
      lists.removeClass("selected");
      $(this).find("input[type='radio']").attr('checked', true);
      $(this).addClass('selected');
      inventory = $(this).find("input[type='hidden']").val();
      badge = $("div#pics_suggestions div#full_pic p.warn.quantity");
      remaining = $("div#infos p.remaining");
      if(inventory < 2) {
        $(remaining).html("Resta apenas <strong><span>0</span> unidade</strong> para o seu tamanho");
      } else {
        $(remaining).html("Restam apenas <strong><span>0</span> unidades</strong> para o seu tamanho");
      }
      $(remaining).hide();
      $(badge).hide();
      if(inventory <= 3) {
        $(remaining).find("span").text(inventory);
        $(badge).find("span").text(inventory);
        $(remaining).show();
        $(badge).show();
      }
      return false;
    }
  });

  $("#add_item").live('submit', function(event) {
    if(initQuickView.inQuickView) {
      $("#close_quick_view").trigger('click');
    }

    initBase.openDialog();
    $('body .dialog').show();
    $('body .dialog').css("left", ((viewWidth  - '930') / 2) + $('body').scrollLeft() );
    $('body .dialog').css("top", ((viewHeight  - '515') / 2) + $('body').scrollTop() );
    $('body .dialog #login_modal').fadeIn('slow');
    initBase.closeDialog();
  });
});

initQuickView = {
  inQuickView : false,
  sliceDesc : function(string) {
    if(string.length > 190) {
      el = $("div#infos div.description p.description");
      descSliced = el.text(string.slice(0,190)+"...");
      el.append("<a href='javascript:void(0);' class='more'>Ler tudo</a>");
    }
  },

  productZoom : function() {
    $("div#pics_suggestions div#full_pic ul li a.image_zoom").jqzoom({
      zoomType: 'innerzoom',
      zoomWidth: 415,
      zoomHeight: 500,
      imageOpacity: 0.4,
      title: false,
      preloadImages: false,
      fadeoutSpeed: 'fast'
    });
  },

  twitProduct : function() {
    $("ul.social li.twitter a").live("click", function(e) {
      var width  = 575,
          height = 400,
          left   = ($(window).width()  - width)  / 2,
          top    = ($(window).height() - height) / 2,
          url    = this.href,
          opts   = 'status=1' +
                   ',width='  + width  +
                   ',height=' + height +
                   ',top='    + top    +
                   ',left='   + left;

      window.open(url, 'twitter', opts);
      e.preventDefault();
    });
  },

  pinProduct : function() {
    $("ul.social li.pinterest a").live("click", function(e) {
      var width  = 710,
          height = 545,
          left   = ($(window).width()  - width)  / 2,
          top    = ($(window).height() - height) / 2,
          url    = this.href,
          opts   = 'status=1' +
                   ',width='  + width  +
                   ',height=' + height +
                   ',top='    + top    +
                   ',left='   + left;

      window.open(url, 'pinterest', opts);
      e.preventDefault();
    });
  },

  shareProductOnFacebook : function() {
    $("ul.social li.facebook a").live("click", function() {
      postProductToFacebookFeed();
      return false;
    })
  }
};
