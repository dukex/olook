$(document).ready(function() {
  $("#facebook_invite_friends").click(function() {
    sendFacebookMessage();
  });

  $("#facebook_post_wall").click(function() {
    postToFacebookFeed();
  });

  $(document).bind('keydown', 'esc',function (evt) {
    $('#sign-in-dropdown').hide();
    $('body').removeClass('dialog-opened');
    return false; 
  });


  if($('.dialog').length == 1) {
    width = $(document).width();
    height = $(document).width();
    viewWidth = $(window).width();
    viewHeight = $(window).height();
    imageW = $('.dialog img').width();
    imageH = $('.dialog img').height();

    $('body').prepend("<div class='overlay'></div>");
    $(".overlay").width(width).height(height);
    
    $('body .dialog').css("left", (viewWidth - imageW) / 2);
    $('body .dialog').css("top", (viewHeight - imageH) / 2);

    $('.dialog img, .overlay').click(function(){
      $('.dialog, .overlay').remove();
    });
  }

});
