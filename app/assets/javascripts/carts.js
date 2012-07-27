$("table#coupon a#show_coupon_field").live("click", function(e) {
  $(this).hide();
  $(this).siblings("form").show();
  e.preventDefault();
});

$('section#cart a.continue.login').live('click', function(e) {
  clone = $('.dialog.product_login').clone().addClass("clone");
  content = clone[0].outerHTML;
  initBase.modal(content);
  e.preventDefault();
});

function change_value(wrap) {
  wrap_value = $("form#gift_wrap .inputs li p").text().match(/[0-9,]+/);
  wrap_value = parseFloat(wrap_value[0].replace( ",", "." ));

  actual_value = $('#cart .last .value').text().match(/[0-9,]+/);
  actual_value = parseFloat(actual_value[0].replace( ",", "." ));

  new_value = actual_value + ((wrap) ? wrap_value : - wrap_value);
  $('#cart .last .value').text("R$ " + new_value.toFixed(2).toString().replace( ".", "," ));
}


$( "#gift_gift_wrap" ).change(function() {
  $( "#gift_wrap" ).submit();
  if ( $(this).attr('checked') == 'checked' ) {
    change_value (true);
  }
  else {
    change_value (false);
  }
});


