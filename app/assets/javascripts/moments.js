var filter = {}, h = 0;


filter.init = function(){
  /**
  * visualization_mode can be "wearing" or "product"
  */
  filter.visualization_mode = "product";
  filter.endlessScroll(window, document);
  filter.seeAll();
  filter.selectedFilter();
  filter.showAllImages(filter.visualization_mode);
  filter.bindObjects();
  filter.changeVisualization();
  filter.displayCleanCategories();
}

filter.spyOverChangeImage = function(){
   $(".spy").on({
      mouseover: function() {
         var backside_image = $(this).parents(".hover_suggestive").next().find("img").attr('data-backside');
         $(this).parents(".hover_suggestive").next().find("img").attr('src', backside_image);
       },
       mouseout: function() {
         var field_name = 'data-' + filter.visualization_mode;    
         var showroom_image = $(this).parents(".hover_suggestive").next().find("img").attr(field_name);
         $(this).parents(".hover_suggestive").next().find("img").attr('src', showroom_image);
       }
   });
}
filter.setMouseOverOnImages = function() {
     $('img.async').mouseover(function () {
       var backside_image = $(this).attr('data-backside');
       $(this).attr('src', backside_image);
     }).mouseout(function () {
       var field_name = 'data-' + filter.visualization_mode;    
       var showroom_image = $(this).attr(field_name);
       $(this).attr('src', showroom_image);
     });
}
filter.showAllImages = function() {
  var field_name = 'data-' + filter.visualization_mode;

  $('img.async').each(function(){
    var image = $(this).attr(field_name);
    $(this).attr('src', image);
  });
  
  filter.setMouseOverOnImages();
  filter.spyOverChangeImage();
}
filter.endlessScroll = function(window, document){
   var url;
   if ($('.pagination').length) {
      $(window).scroll(function() {
         url = $('.pagination .next_page').attr('href');
         var canPaginate =  url && ($(window).scrollTop() > ($(document).height() - 1250)) && !$('.loading').is(':visible');
         if (canPaginate) {
            $('.loading').show();
            $('.pagination .next_page').remove();
            $('form#filter').find("input[type='checkbox']").attr("disabled", "true");
            return $.getScript(url);
         }
      });
   }
}
filter.submitAndScrollUp = function(){
  $("form#filter").submit(function() {
    $('.loading').show();
    var selected_sort = $("select#filter_option").val() ;
    $('#sort_filter').val(selected_sort);    
    // $('#sort_filter').val($("#filter").find("input:checked").val());
    $("#products").fadeOut("slow", function() {
      $(this).fadeIn("slow").html("");
    });    
  });

	$("html, body").delay(300).animate({scrollTop: $(".filters").length ? h : 0}, 'slow');

} 
filter.seeAll = function(){
   $("#filter input[type='checkbox'].select_all").each(function(i){
      $(this).bind("click",function(){
         $(this).parents(".filter").find("input[type='checkbox']").not(".select_all").attr("checked", this.checked);
        
         $(this).parent().submit();
         filter.submitAndScrollUp();
      })
      
   });
}
filter.selectedFilter = function(){
   $("#filter input[type='checkbox']").not(".select_all").bind("click", function() {
      if(!$(this).is(":checked")) {
         $(this).parent().siblings("li").find("input[type='checkbox'].select_all").attr("checked", false);
         if($(this).parent().parent().find("li input[type='checkbox']:checked").length == 0){
          $(this).parent().parent().parent().find("button.clear_filter").hide();   
         }
      } else if($(this).parent().parent().find("li input[type='checkbox']:checked").length > 0){
        $(this).parent().parent().parent().find("button.clear_filter").show();
      }
      filter.tags($(this).attr('id'),$(this).next().text() ,$(this).is(":checked"));
      filter.submitAndScrollUp();
      $(this).parent().submit();      
      $('form#filter').find("input[type='checkbox']").attr("disabled", "true");
   });
}
filter.tags = function(name, desc, flag){
   var classname = name.replace(' ','').toLowerCase(), list = $("#tags ul");
   
   if(flag == true) {
      $("section.filters").fadeIn();
      list.hide().prepend('<li class="'+classname+' header_filter">'+desc+'<button type="button" class=" delete del-'+classname+'">( x )</button></li>').delay(100).fadeIn();
      window.setTimeout('filter.deleteTag("'+classname+'")', 300);
      filter.cleanFilter();   
   }   
   else {
      list.hide();
      list.find("li."+classname).fadeOut().delay(300).remove();
      list.fadeIn();
   }   
   if($("#tags ul").children().size() < 2){
      $("section.filters").delay(300).fadeOut();
   }
}
filter.deleteTag = function(classname){
   $("button.del-"+classname).bind("click", function(){
      classname = classname.toLowerCase(), filterId = $(".filter input#"+classname);
      $(filterId).attr("checked", false);
      flag = filterId.is(":checked");      
      filter.tags(classname,null,flag);
      filterId.parent().submit();
      filter.submitAndScrollUp();
   }).hover(
      function(){
         $(this).next().fadeIn();
      },
      function(){
         $(this).next().fadeOut();
      }
   )
}
filter.cleanCategory = function(event){
   event.preventDefault();
   event.stopPropagation();
   canSubmit = false;

   $(event.target).parent().find("li").each(function(){
      checked = $(this).find("input[type='checkbox']:checked");
      if(checked.attr("checked")){
        canSubmit = true;
        checked.attr("checked", false);
        $("div#tags li."+$(this).find("input").attr('id')).remove();
      }
   });

   if(canSubmit){
     $(event.target).parent().submit();
     $(event.target).hide();
   }
   
   if($("#tags ul li").length < 2){
      $("section.filters").fadeOut();
   }

}

filter.displayCleanCategories = function(){
  //TODO: display clean categories if the checkboxes are already checked on reload
}

filter.toggleFilter = function(event){

   style = $(event.target).attr('class');
   style = (style.indexOf("opened") >= 0) ? style.replace("opened", "") : style+" opened";
    
   $(event.target).attr('class', style);
   opened = (style.indexOf("opened") >= 0);

   if(opened){
      $(event.target).parent().find("ol").show();
      if($(event.target).next().next().find("input[type='checkbox']:checked").length > 0){
         $(event.target).parent().find("button.clear_filter").show();
      }   
   } else {
      $(event.target).parent().find("ol").hide();
      $(event.target).parent().find("button.clear_filter").hide();
   }

}
filter.bindObjects = function(){
   $('.clear_filter').bind('click', function(event){
      event.preventDefault();
      event.stopPropagation();
      filter.cleanCategory(event);
   });

   $(".filter_type").bind('click', function(event){
      event.preventDefault();
      event.stopPropagation();
      filter.toggleFilter(event);
   });   

}
filter.changeVisualization = function(){
   $(".exhibition-mode p span").bind('click', function(){
      if($(this).hasClass("product")){
         filter.visualization_mode = "product";
         filter.showAllImages(filter.visualization_mode);
         $(this).addClass("selected").next().next().removeClass("selected");
      }
      else{
         filter.visualization_mode = "wearing";
         filter.showAllImages(filter.visualization_mode);
         $(this).addClass("selected").prev().prev().removeClass("selected");
      }
   })
}
filter.cleanFilter = function(){
   $(".cleanFilter").bind('click', function(){
      $("#tags ul li.header_filter").each(function(){ 
        $(this).remove();
      });
      $("section.filters").fadeOut();
      $(".filter input:checked").attr("checked", false).delay(150).parent().submit();
      $('.clear_filter').fadeOut();
      $("html, body").delay(300).animate({scrollTop: 0}, 'slow');
   })
}

$(function(){
  if($(".exhibition-mode").position()){
    h = $(".exhibition-mode").position().top;
    h += 105;
  }
  filter.init();

  $('#filter_option').change(function() {
    //TODO: the following lines are duplicated
    $('.loading').show();
    var selected_sort = $(this).val() ;
    $('#sort_filter').val(selected_sort);
    $("#products").fadeOut("slow", function() {
      $(this).fadeIn("slow").html("");
    });

    $('form#filter').submit();
  });

})
