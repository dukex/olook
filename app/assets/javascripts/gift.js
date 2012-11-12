$(function () {
  $("section#profiles ul li a").live("click", function(e) {

    var profile = e.target.id;

    $("section#profile_products").hide();

    $("section#profiles ul li a").removeClass().addClass("off");
    $(this).removeClass("off").addClass('selected');
    
    $("section#profile_products." + profile).slideDown();
    var container_position = $("section#profile_products." + profile).offset().top - 40;
    InitGift.slideTo(container_position);
    e.preventDefault();
  });

  $("section#suggestions div.content ul li a").live("click", function(e) {
    var index = $(this).parent().index();
    $("section#suggestions div.content ul li").removeClass();
    $(this).parent().addClass("selected");
    console.log(index);
    if(index != 0) {
      var parent = $("section#suggestions div.content ul li")[index - 1];
      $(parent).addClass("no_border");
    } else {
      $("section#suggestions div.content ul li").removeClass("no_border");
    }
    $("section#suggestions_products").slideDown();
    var container_position = $("section#suggestions_products").offset().top - 40;
    InitGift.slideTo(container_position);
    e.preventDefault();
  });

  $("div.box.shoes ul li label").on("click", function(e) {

    // mark the checkbox next to this label, as checked
    $(this).next().attr("checked",true);

    $("div.box.shoes ul li").removeClass();
    $(this).parent().addClass("selected");
    e.preventDefault();
  });

  $("div#help p+a").on("click", function(e) {
    var container_position = $("section#quiz").offset().top;
    InitGift.slideTo(container_position);
    e.preventDefault();
  });

  $("div#help a.close").on("click", function(e) {
    $(this).parent().fadeOut();
    e.preventDefault();
  });

  $("div#calendar ul#months li a").live("click", function(event) {
    $("div#calendar ul#months li a").removeClass("selected");
    $(this).addClass("selected");
    InitGift.friendsPreloader();
    event.preventDefault();
  });

  $("section#profile form ul.shoes li").live("click", function() {
    $("section#profile form ul.shoes li").removeClass("selected");
    $("section#profile form ul.shoes li label input[type='radio']").removeAttr("checked");
    $(this).find("label").find("input[type='radio']").attr("checked", "checked");
    if($(this).find("label").find("input[type='radio']").is(":checked")) {
      $(this).addClass("selected");
    }
  });

  $("section#profile a.select_profile").live("click", function(event) {
    $("section#profile div.profiles").slideDown('normal', function() {
      container_position = $(this).position().top;
      position = container_position - 40;
      $('html, body').animate({
        scrollTop: position
      }, 'slow');
    });
    event.preventDefault();
  });

  $("form.edit_profile ul li").click(function() {
    $(this).find("label").find("input[type='radio']").attr("checked", "checked");
    if($(this).find("label").find("input[type='radio']").is(":checked")) {
      $("form.edit_profile").submit();
    }
  });
});

InitGift = {
  friendsPreloader : function() {
    $("div#birthdays_list ul.friends_list").remove();
    $("div#birthdays_list").html("<div class='preloader'></div>");
  },

  slideTo : function(container_position) {
    position = container_position -40;
    $("html, body").animate({
      scrollTop: position
    }, 'normal');
  }
}
