jQuery(function() {
  $("div#carousel_container ul").carouFredSel({
    width: 480,
    items: 1,
    auto : {
      pauseDuration : 15000
    },
    prev : {
      button : ".prev",
      key : "left",
      items : 1
    },
    next : {
      button : ".next",
      key : "right",
      items : 1
    }
  });

  $('#liquidation_order_filter').change(function() {
    $("#liquidation_filter").submit();
  });

  $('#liquidation_filter').submit(function() {
    $('#sort_filter').val($("#order_filter").find("option:selected").val());
    $("#products").fadeOut("slow", function() {
      $(".loading").show();
      $(this).fadeIn("slow");
      $(this).html("");
    });
  });

  $('#liquidation_filter').find("input[type='checkbox']").click(function() {
    $('#liquidation_filter').find("input[type='checkbox']").attr("disabled", "true");
    $(this).parent().submit();
  });

  if ($('.pagination').length) {
    $(window).scroll(function() {
      var url;
      url = $('.pagination .next_page').attr('href');
      var bottomHeight = 750
      if (url && $(window).scrollTop() > $(document).height() - $(window).height() - bottomHeight) {
        $('.loading').show();
        return $.getScript(url).done(function() {
          $(".loading").hide();
        });
      }
    });
    return $(window).scroll();
  }
});

