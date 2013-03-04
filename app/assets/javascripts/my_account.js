$(document).ready(function() {
  $("#my_account ul.shoes_size li label, .clone ul.shoes_size li label").live("click", function() {
    $(this).parents("ul.shoes_size").find("li").removeClass("selected");
    $(this).parent().addClass("selected");
  });

  $("div#my_account.my_gifts table tbody tr td.edit a").on("click", function(e) {
    var clone = $('.dialog.gifted').clone().addClass('clone');
    var content = clone[0].outerHTML;
    initBase.newModal(content);
    e.preventDefault();
  });
});
