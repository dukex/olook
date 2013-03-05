$(document).ready(function() {
  $("div#modal div.video_description a").live("click", function(e) {
    $("div#modal").dialog("close");
    e.preventDefault();
  })

  if($("div#carousel_lookbooks").size() > 0) {
    $("div#carousel_lookbooks ul").carouFredSel({
      auto: false,
      width: 970,
      items: 3,
      prev : {
        button : ".prev-lookbook",
        items : 1
      },
      next : {
        button : ".next-lookbook",
        items : 1
      },
      pagination: {
        container : "div#carousel_lookbooks .pagination",
        items : 1
      }
    });
  }

  if($("div#carousel_lookbooks_product").size() > 0) {
    $("div#carousel_lookbooks_product ul").carouFredSel({
      auto: false,
      prev : {
        button : ".prev-pic",
        key : "left"
      },
      next : {
        button : ".next-pic",
        key : "right"
      },
      pagination : {
        container : "div#carousel_lookbooks_product .pagination",
        items : 1
      }
    });
  }

});
