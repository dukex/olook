if($(".box-remember.success").length > 0){
	w = 520, h = 175, ml = -(w/2), mt = -(h/2);
	parent.top.$("#modal-campaign").css({
		"width"  	  : w +"px",
		"height" 	  : h +"px",
		"margin-top"  : mt+"px",
		"margin-left" : ml+"px"
	}).delay(250).fadeIn();
}else if($(".box-cadastro").length > 0){
	w = 910, h = 405, ml = -(w/2), mt = -(h/2);
	parent.top.$("#modal-campaign").css({
		"width"  	  : w +"px",
		"height" 	  : h +"px",
		"margin-top"  : mt+"px",
		"margin-left" : ml+"px"
	}).delay(250).fadeIn();
}else if($(".box-continue").length > 0){
	w = 595, h = 185, ml = -(w/2), mt = -(h/2);
	parent.top.$("#modal-campaign").css({
		"width"  	  : w +"px",
		"height" 	  : h +"px",
		"margin-top"  : mt+"px",
		"margin-left" : ml+"px"
	}).delay(200).fadeIn();
}else{
	w = 530, h = 385, ml = -(w/2), mt = -(h/2);
	parent.top.$("#modal-campaign").css({
		"width"  	  : w +"px",
		"height" 	  : h +"px",
		"margin-top"  : mt+"px",
		"margin-left" : ml+"px"
	}).delay(200).fadeIn();
}
var flag;
function checkEmail(e) {
	var email = $('#campaign_email_email').val();
	var filter = /^([a-zA-Z0-9_\.\-])+\@(([a-zA-Z0-9\-])+\.)+([a-zA-Z0-9]{2,4})+$/;
	if (!filter.test(email) || email === 'seunome@email.com.br'){
		e.preventDefault();
		$('.error').fadeIn();
		email.focus;
		return flag=false;
	}else{
		$('.error').fadeOut('fast');
		$("#campaign_email").submit();
		return flag=true;
	}
}

$(function(){
	$('#campaign_email_email').focus(function(){
		if($(this).val() == 'seunome@email.com.br')
			$(this).val('');
	}).focusout(function(){
		if($(this).val() == '')
			$(this).val('seunome@email.com.br')
	});
	
	$('.bt-enviar').bind("click", function(e){
			checkEmail(e);
	})
	
	$(".close, .btn-continue").bind("click", function(){
		parent.top.$("#modal-campaign,#overlay-campaign").fadeOut();
	})
	
	$("input[type=submit]").click(function(){
		if(flag==true)
			parent.top.$("#modal-campaign").fadeOut();
	})
});
