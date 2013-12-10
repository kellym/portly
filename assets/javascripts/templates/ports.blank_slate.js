(function() {
  var template = Handlebars.template, templates = Handlebars.templates = Handlebars.templates || {};
templates['ports.blank_slate'] = template(function (Handlebars,depth0,helpers,partials,data) {
  this.compilerInfo = [4,'>= 1.0.0'];
helpers = this.merge(helpers, Handlebars.helpers); data = data || {};
  


  return "<div class='row'>\n  <div class='large-12 columns'>\n    <h3 class='text-center margin-top-30 margin-bottom-20'>Add a Port to this Computer</h3>\n    <p class='text-center'>\n      You can add one here, or via the app you have installed on your computer.\n      <br />\n      <a class=\"button large margin-top-30\" data-action=\"new\" href=\"#\" ><span>Add a port</span></a>\n      <br />\n      <a href=\"/download\" ><span>Download the app</span></a>\n      or\n      <a data-action=\"remove-computer\" href=\"#\" ><span>Remove this computer from my account</span></a>\n    </p>\n  </div>\n</div>\n";
  });
})();
