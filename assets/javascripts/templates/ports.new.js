(function() {
  var template = Handlebars.template, templates = Handlebars.templates = Handlebars.templates || {};
templates['ports.new'] = template(function (Handlebars,depth0,helpers,partials,data) {
  this.compilerInfo = [4,'>= 1.0.0'];
helpers = this.merge(helpers, Handlebars.helpers); data = data || {};
  var buffer = "", stack1, functionType="function", escapeExpression=this.escapeExpression, self=this;

function program1(depth0,data) {
  
  var buffer = "", stack1;
  buffer += "\n    <div class='row'>\n      <div class='large-4 columns'>\n        <label class='inline'>Static Mirroring</label>\n      </div>\n      <div class='large-8 columns'>\n        <label>\n          <select name='mirror'>\n            <option value='false' ";
  if (stack1 = helpers.not_mirror) { stack1 = stack1.call(depth0, {hash:{},data:data}); }
  else { stack1 = (depth0 && depth0.not_mirror); stack1 = typeof stack1 === functionType ? stack1.call(depth0, {hash:{},data:data}) : stack1; }
  buffer += escapeExpression(stack1)
    + ">Show a placeholder page when offline</option>\n            <option value='true' ";
  if (stack1 = helpers.mirror) { stack1 = stack1.call(depth0, {hash:{},data:data}); }
  else { stack1 = (depth0 && depth0.mirror); stack1 = typeof stack1 === functionType ? stack1.call(depth0, {hash:{},data:data}) : stack1; }
  buffer += escapeExpression(stack1)
    + "> Show a copy of the site when offline</option>\n          </select>\n        </label>\n      </div>\n    </div>\n    ";
  return buffer;
  }

  buffer += "<div class='add-modal modal'>\n  <h3>\n    Add a Port\n    <a href='#cancel' rel='modal:close'>Cancel</a>\n  </h3>\n  <form data-action='create'>\n    <div class='row'>\n      <div class='large-4 columns'>\n        <label class='inline connection-label'>Local URL</label>\n      </div>\n      <div class='large-8 columns'>\n        <input class='input connection-string' name='local_path' placeholder='http://localhost:8888' type='text' value='";
  if (stack1 = helpers.local_path) { stack1 = stack1.call(depth0, {hash:{},data:data}); }
  else { stack1 = (depth0 && depth0.local_path); stack1 = typeof stack1 === functionType ? stack1.call(depth0, {hash:{},data:data}) : stack1; }
  buffer += escapeExpression(stack1)
    + "'>\n      </div>\n    </div>\n    <div class='row'>\n      <div class='large-4 columns'>\n        <label class='inline'>Subdomain</label>\n      </div>\n      <div class='large-8 columns'>\n        <div class='inline-input'>\n          <input class='input subdomain' name='subdomain' placeholder='' type='text' value='";
  if (stack1 = helpers.subdomain) { stack1 = stack1.call(depth0, {hash:{},data:data}); }
  else { stack1 = (depth0 && depth0.subdomain); stack1 = typeof stack1 === functionType ? stack1.call(depth0, {hash:{},data:data}) : stack1; }
  buffer += escapeExpression(stack1)
    + "'>\n            ";
  if (stack1 = helpers.domain_ending) { stack1 = stack1.call(depth0, {hash:{},data:data}); }
  else { stack1 = (depth0 && depth0.domain_ending); stack1 = typeof stack1 === functionType ? stack1.call(depth0, {hash:{},data:data}) : stack1; }
  buffer += escapeExpression(stack1)
    + "\n          </input>\n        </div>\n        <div class='margin-bottom-10 smaller mute'>Use an asterisk (<strong>*";
  if (stack1 = helpers.domain_ending) { stack1 = stack1.call(depth0, {hash:{},data:data}); }
  else { stack1 = (depth0 && depth0.domain_ending); stack1 = typeof stack1 === functionType ? stack1.call(depth0, {hash:{},data:data}) : stack1; }
  buffer += escapeExpression(stack1)
    + "</strong>) to create a catch-all tunnel</div>\n      </div>\n    </div>\n    <div class='row'>\n      <div class='large-4 columns'>\n        <label class='inline'>Personal Domain</label>\n      </div>\n      <div class='large-8 columns'>\n        <input class='input margin-bottom-0 cname' name='cname' placeholder='' type='text' value='";
  if (stack1 = helpers.cname) { stack1 = stack1.call(depth0, {hash:{},data:data}); }
  else { stack1 = (depth0 && depth0.cname); stack1 = typeof stack1 === functionType ? stack1.call(depth0, {hash:{},data:data}) : stack1; }
  buffer += escapeExpression(stack1)
    + "'>\n        <div class='smaller margin-bottom-10 mute'>Point your CNAME record to tunnel.portly.co</div>\n      </div>\n    </div>\n    ";
  stack1 = helpers['if'].call(depth0, (depth0 && depth0.pro_user), {hash:{},inverse:self.noop,fn:self.program(1, program1, data),data:data});
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "\n    <div class='row'>\n      <div class='large-12 columns margin-top-20'>\n        <button class='margin-bottom-0' type='submit'>Save</button>\n      </div>\n    </div>\n  </form>\n</div>\n";
  return buffer;
  });
})();
