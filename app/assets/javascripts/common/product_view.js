$(document).ready(function() {
  var stringDesc = $("div#infos div.description p.description").text();
  initProduct.sliceDesc(stringDesc);
  initProduct.productZoom();

  $("div#infos div.description p[class!='price'] a.more").live("click", function() {
    el = $(this).parent();
    el.text(stringDesc);
    el.append("<a href='javascript:void(0);' class='less'>Esconder</a>");
  });

  $("div#infos div.description p[class!='price'] a.less").live("click", function() {
    initProduct.sliceDesc(stringDesc);
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
    if(initProduct.inQuickView) {
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

initProduct = {
  inQuickView : false,
  sliceDesc : function(string) {
    if(string.length > 120) {
      el = $("div#infos div.description p.description");
      descSliced = el.text(string.slice(0,120)+"...");
      el.append("<a href='javascript:void(0);' class='more'>Ler tudo</a>");
    }
  },

  productZoom : function() {
    $("div#pics_suggestions div#full_pic ul li a.image_zoom").jqzoom({
      zoomType: 'standard',
      zoomWidth: 415,
      zoomHeight: 500,
      imageOpacity: 0.4,
      title: false,
      preloadImages: false,
      fadeoutSpeed: 'fast'
    });
  }
};
