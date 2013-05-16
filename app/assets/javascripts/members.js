$(document).ready(function() {
  $('.import-dropdown').hide();
  $("#import-contacts .gmail").click(function(event){
    event.preventDefault();
    $(".import-dropdown > span").removeClass();
    $("#import-contacts .import-dropdown").show();
    var email_provider = $(this).attr('class');
    $("#email_provider").val(email_provider);
    $(".import-dropdown > span").addClass(email_provider);
  });

  $('.import-dropdown a').live('click', function(event){
    event.preventDefault();
    $(this).parent().hide();
  });

  $(document).bind('keydown', 'esc',function () {
    $('.import-dropdown').hide();
    return false;
  });

  $('#invite_list input#select_all').click(function() {
    $(this).parents('form').find('#list :checkbox').attr('checked', this.checked);
  });

  $('nav.invite ul li a').live('click', function () {
    cl = $(this).attr('class');
    $('#'+cl).slideto({ highlight: false });
  });

  $("section#post-to-wall a").live("click", function() {
    $("html, body").animate({
      scrollTop: 0
    }, 'slow');
  });

});


  $("#share-mail a.copy_link").zclip({
    path: "/assets/ZeroClipboard.swf",
    copy: function() { return $("section#share-mail input#link").val(); },
    afterCopy: function(){
      $("section#share-mail div.box_copy").fadeIn().delay(2000).fadeOut();
    }
  });