app.collections.Payments = Backbone.Collection.extend({
  model: app.models.Payment,
  url: app.server_api_prefix + '/payment_types'
});