isJQueryLoaded = function() {
  return (typeof window.$ == 'function');
}

loadCepCheck = function() {
  olook.cep('.zip_code', {
    estado: '#checkout_address_state',
    cidade: '#checkout_address_city',
    rua: '#checkout_address_street',
    bairro: '#checkout_address_neighborhood',
    afterFail: loadStateAndCityCombobox
  });
  $(".zip_code").focus();
}

loadStateAndCityCombobox = function() {
  if(!states_and_cities) var states_and_cities = {};

  states_and_cities.load_state_cities = function(){
    return new dgCidadesEstados({
      cidade: document.getElementById('checkout_address_city'),
      estado: document.getElementById('checkout_address_state')
    });
  }

  function changeTag(field){
    var txt = field.find(":selected").text();
    field.prev('p').text(" ").delay(100).text(txt);
  }


  $("#checkout_address_state").change(function(){
    changeTag($(this));
    combo_service.run();
    changeTag($("#checkout_address_city"));
  });

  $("#checkout_address_city").change(function(){
    changeTag($(this));
  });


  if(!combo_service) var combo_service = states_and_cities.load_state_cities();
}

if (isJQueryLoaded()) {
  loadStateAndCityCombobox();
  loadCepCheck();
} else {
  window.onload=function(){
    loadStateAndCityCombobox();
    loadCepCheck();
  }
}
;
