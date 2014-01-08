// shim layer with setTimeout fallback
window.requestAnimFrame = (function(){
  return  window.requestAnimationFrame       ||
          window.webkitRequestAnimationFrame ||
          window.mozRequestAnimationFrame    ||
          window.oRequestAnimationFrame      ||
          window.msRequestAnimationFrame     ||
          function( callback ){
            window.setTimeout(callback, 1000 / 60);
          };
})();

$(function() {
(function(win, d) {

  var $ = d.querySelector.bind(d);

  var bg = $('.background');
  var demo = $('.demo img');
  var canvas = $('#main-canvas');
  var demo_canvas = $('#demo-canvas');
  var context = canvas.getContext('2d');
  var demo_context = canvas.getContext('2d');
  var demo_top = jQuery('.demo-top').offset().top;

  var splash = jQuery('#splash');
  var stripe = $('aside');
  var ticking = false;
  var lastScrollY = 0;
  var width;
  var height;

  function onResize () {

    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
    splash.height(window.innerHeight > 330 ? window.innerHeight : 330);
    demo_top = jQuery('.demo-top').offset().top;

    updateElements(win.scrollY);
  }

  function onScroll (evt) {
    if(!ticking) {
      ticking = true;
      requestAnimFrame(performScroll);
      lastScrollY = win.scrollY;
    }
  }

  function updateElements () {
    context.fillStyle = "#ffffff";
    context.fillRect(0, 0, canvas.width, canvas.height);
    width = canvas.width;
    height = width * bg.height / bg.width;
    if (height < canvas.height) {
      height = canvas.height;
      width = height * bg.width / bg.height;
    }
    performScroll();
  }

  function performScroll() {
    if (lastScrollY > demo_top) {
      canvas.height = 0;
      ticking = false;
    } else {
      canvas.height = window.innerHeight;
      var relativeY = lastScrollY * 0.000333;
      context.drawImage(bg, 0, pos(0, -800, relativeY, 0), width, height);
      ticking = false;
    }
  }

  function pos(base, range, relY, offset) {
    return base + limit(0, 1, relY - offset) * range;
  }

  function prefix(obj, prop, value) {
    var prefs = ['webkit', 'Moz', 'o', 'ms'];
    for (var pref in prefs) {
      obj[prefs[pref] + prop] = value;
    }
  }

  function limit(min, max, value) {
    return Math.max(min, Math.min(max, value));
  }

  win.addEventListener('load', onResize, false);
  win.addEventListener('resize', onResize, false);
  win.addEventListener('scroll', onScroll, false);

})(window, document);});

