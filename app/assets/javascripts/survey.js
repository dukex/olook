$(document).ready(function() {
  init.carousel();
  init.bindActions();
  init.dialog();
  init.index = 1;
  init.tracker();

  $('#survey').bind('keydown', 'tab',function (evt) {
    return false;
  });

  $('.about ul li').live('click', function() {
    $(this).parent('ul').find('li').removeClass('selected');
    $(this).addClass('selected');
  });

  $(".about").live("change", function(){
    var limitOfCheckedAnswers = 2;
    if ($('.about').find(":radio:checked").length == limitOfCheckedAnswers &&
      $(".about select[name='day']").val()  != 'Dia' &&
      $(".about select[name='month']").val()  != 'Mês' &&
      $(".about select[name='year']").val()  != 'Ano'){

      $(".about .buttons li").removeClass("grey-button");
      $(".about .buttons li input").removeAttr("disabled");
    }else{
      $(".about .buttons li").addClass("grey-button");
    }
  });

  $('.colors .stars label').hover(function() {
    var elementID = $(this).parents('ol').attr('id');

    if ($('.colors .stars label').parents('#' + elementID).find('li').hasClass('click_star')) {
      $('.colors .stars label').parents('#' + elementID).find('li').removeClass('starred');
    }
    $(this).parent().addClass('starred').prevAll().addClass('starred');

  }, function() {
    var elementID = $(this).parents('ol').attr('id');

    if ($('.colors .stars label').parents('#' + elementID).find(':radio:checked').length == 1) {
        $('.colors .stars label').parents('#' + elementID).find('li').removeClass('starred');
        $('.colors .stars label').parents('#' + elementID).find('li.click_star').addClass('starred').prevAll().addClass('starred');
    }else{
      $('.colors .stars label').parents('#' + elementID).find('li').removeClass('starred');
    }
  });

  $('.colors div label').click(function() {
    var elementID = $(this).parents('ol').attr('id');

    $(this).parents('#' + elementID).find('li').removeClass('click_star')
    $(this).parent('li').addClass('click_star')
    $(this).parent().addClass('starred').prevAll().addClass('starred')


    if($('li.colors').find(':radio:checked').length == 4){
      $('#next_link').click();
    }
  });

  if (!$.browser.opera) {
    $('select.custom_select').each(function(){
      var title = $(this).attr('title');
      if( $('option:selected', this).val() != ''  ) title = $('option:selected',this).text();
      $(this).css({'z-index':10,'opacity':0,'-khtml-appearance':'none'}).after('<span class="select">' + title + '</span>').change(function(){
        val = $('option:selected',this).text();
        $(this).next().text(val);
      })
    });
  };
});

init = {
  carousel : function() {
               $('.questions').jcarousel({
                 initCallback: init.mycarousel_initCallback,
                 itemFirstInCallback : {
                    onAfterAnimation : init.showArrow
                 },
                 buttonPrevHTML : null,
                 scroll: 1
               });
             },

  showArrow : function(instance, item, index, state) {
                $('#asynch-load').click();

                var tracker_index = Math.round(index / 2);
                $("#tracker > li").removeClass('selected');
                $("#tracker").find('li#' + tracker_index).addClass('selected');

                if(index == '1') {
                  $('.jcarousel-prev').css('display', 'none');
                }else{
                  $('.jcarousel-prev').css('display', 'block');
                }
  },

  mycarousel_initCallback : function(carousel) {
                              $('.jcarousel-prev').css('display', 'block');
                              $('#next_link').bind('click', function() {
                                var analytics_step = '/quiz/' + (init.index + 1);
                                _gaq.push(['_trackPageview', analytics_step]);

                                carousel.next();
                                init.index++;

                                return false;
                              });

                              $('.jcarousel-prev').bind('click', function() {
                                init.clearOptions( init.getCurrentPage(carousel) );

                                carousel.prev();
                                init.index--;

                                init.clearOptions( init.getCurrentPage(carousel) );

                                return false;
                              });
                            },

  getCurrentPage : function(carousel) {
    var page_selector = carousel.get(init.index).selector;
    return $(page_selector.replace('>',''));
  },

  clearOptions : function(page) {
    page.find('li.selected').removeClass('selected');
    page.find('li.click_star').removeClass();
    page.find('li.starred').removeClass();
    page.find(':radio, :checkbox').attr('checked', false);
  },

  bindActions : function() {
                  $('.images .options > li').live('click', function(){

                    $(this).find('input').attr('checked', true);
                    $(this).addClass('selected');

                    $("#next_link").click();
                  });
  },

  dialog : function(){
             $('a.trigger').live('click', function(e){
              el = $(this).attr('href');

              $(this).parents('#session').find('.' + el).toggle('open');
              $(this).parents('body').addClass('dialog-opened')

              e.preventDefault();

              $('.sign-in-dropdown').live('click',function(e) {
                if($('body').hasClass('dialog-opened')) {
                  e.stopPropagation();
                }
              })

              $('body.dialog-opened').live('click', function(e){
                if($('.sign-in-dropdown').is(':visible')){
                  $('.sign-in-dropdown').toggle();
                  $(this).removeClass('dialog-opened');
                  e.stopPropagation();
                }
              });
            });
           },

  tracker : function() {
              var info = '<p>Fotos: Reprodução<br />O uso de imagens de celebridades nesta pesquisa serve o propósito único de identificar o perfil de moda dos respondentes. As celebridades retratadas não estão associadas ou recomendam a Olook.</p>'
              var pages = $('.questions > li').length / 2;

              $('#survey').after("<ul id='tracker'>");

              for (var i = 1; i <= pages; i++)
                $("#tracker").append('<li id=' + i + '>' + i + '</li>');

              $('#tracker').after(info);
            }
};

