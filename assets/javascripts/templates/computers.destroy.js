(function() {
  var template = Handlebars.template, templates = Handlebars.templates = Handlebars.templates || {};
templates['computers.destroy'] = template(function (Handlebars,depth0,helpers,partials,data) {
  this.compilerInfo = [4,'>= 1.0.0'];
helpers = this.merge(helpers, Handlebars.helpers); data = data || {};
  


  return "<div class='destroy-modal modal'>\n  <h3>\n    Remove Computer\n    <a href='#cancel' rel='modal:close'>Cancel</a>\n  </h3>\n  <form data-action='destroy-computer'>\n    <div class='row'>\n      <div class='large-12 columns'>\n        Are you sure you want to remove this computer from your account?\n      </div>\n    </div>\n    <div class='row'>\n      <div class='large-12 columns margin-top-20'>\n        <button class='margin-bottom-0' type='submit'>Confirm removal</button>\n      </div>\n    </div>\n  </form>\n</div>\n";
  });
})();
