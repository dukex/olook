//= require state_cities

if(!states_and_cities) var states_and_cities = {};

states_and_cities.load_state_cities = function(){
  new dgCidadesEstados({
    cidade: document.getElementById('address_city'),
    estado: document.getElementById('address_state')
  });
}

$(function() {
  states_and_cities.load_state_cities();
});