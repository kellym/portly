(function($, undefined) {

    $.fn.dropdown = function() {

        var widget = $(this);
        var label = widget.find('.valueOfButton');
        var container = widget.find('.dropdown');
        var list = widget.children('.dropdown');
        var button = widget.find('.button');
        var selected;
        var highlighted;

        var select = function(i) {
            label.html($(i).html());
        };

        var highlight = function(i) {

            highlighted = $(i);

            highlighted
            .addClass('selected')
            .siblings('.selected')
            .removeClass('selected');
        };

        var scroll = function(event) {

            list.scrollTo('.selected');

        };

        var hover = function(event) {

            highlight(this);

        };

        var rebind = function(event) {

            bind();

        };

        var bind = function() {
            list.on('mouseover', 'li', hover);
            widget.off('mousemove', rebind);

        };

        var unbind = function() {
            list.off('mouseover', 'li', hover);
            widget.on('mousemove', rebind);

        };

        list.on('click', 'a', function(event) {
            $(event.currentTarget).parents('div').find('.dropdown').hide();
            select(this);
        });

        widget.keydown(function(event) {

            unbind();

            switch(event.keyCode) {

                case 38:
                    highlight((highlighted && highlighted.prev().length > 0) ? highlighted.prev() : list.children().last());

                    scroll();
                    break;

                case 40:
                    highlight((highlighted && highlighted.next().length > 0) ? highlighted.next() : list.children().first());

                    scroll();
                    break;

                case 13:
                    if(highlighted) {

                        select(highlighted);

                    }
                    break;

            }

        });

        bind();
        container.hide();
        button.on('click', function(e) {
          e.preventDefault();
          $(e.currentTarget).parent().find('.dropdown').toggle();
         // container.toggle();
        });

    };

    $.fn.scrollTo = function(target, options, callback) {

        if(typeof options === 'function' && arguments.length === 2) {

            callback = options;
            options = target;
        }

        var settings = $.extend({
            scrollTarget  : target,
            offsetTop     : 185,
            duration      : 0,
            easing        : 'linear'
        }, options);

        return this.each(function(i) {

            var scrollPane = $(this);
            var scrollTarget = (typeof settings.scrollTarget === 'number') ? settings.scrollTarget : $(settings.scrollTarget);
            var scrollY = (typeof scrollTarget === 'number') ? scrollTarget : scrollTarget.offset().top + scrollPane.scrollTop() - parseInt(settings.offsetTop, 10);

            scrollPane.animate({scrollTop: scrollY}, parseInt(settings.duration, 10), settings.easing, function() {

                if (typeof callback === 'function') {

                    callback.call(this);
                }

            });

        });

    };

})(jQuery);
