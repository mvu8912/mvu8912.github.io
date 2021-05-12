$(document).ready(function () {
    $('td').each(function () {
        if ($(this).text() != 'Bugs Associated With User Stories'
         && $(this).text() != 'Bugs'
         && $(this).text() != 'Tasks') {
            return;
        }

        $('tr[valign=top] a',
            $(this).parents('.section_content')).each(handle_yac);
    });

    function handle_yac() {
        var $yac = $(this);
        var link = $yac.attr('href');
        if (!link.match(/view-(task|bug)s/)) {
            return;
        }

        $.get(link, handle_page($yac));
    }

    function handle_page($yac) {
        return function (page) {
            var $page = $(page);
            $('th', $page).each(handle_summary($yac));
            $('th', $page).each(handle_headline($yac));
            $('a', $page).each(handle_kanban_state($yac));
            $('th', $page).each(handle_yac_state($yac));
        };
    }

    function handle_summary($yac) {
        if (location.href.match(/view-user_stories/)) {
            return function () {};
        }
        return function () {
            if ($(this).text() != 'Summary') {
                return;
            }

            var summary = $('td', $(this).parents('tr')).html();
            var $display = $('<span></span>');
            $display.html(' - ' + summary);
            $display.css('color', 'green');
            $yac.after($display);
        };
    }

    function handle_headline($yac) {
        return function () {
            if ($(this).text() != 'Headline') {
                return;
            }

            var headline = $('td', $(this).parents('tr')).html();

            if (!headline) {
                return;
            }

            var $display = $('<span></span>');
            $display.html(' | [' + headline + ']');
            $display.css('color', 'orange');
            $yac.after($display);
        };
    }
    function handle_yac_state($yac) {
        return function () {
            if ($(this).text() != 'State') {
                return;
            }

            var state = $('td', $(this).parents('tr')).html();

            if (state != 'Closed' && state != 'Cancelled') {
                return;
            }

            var $display = $('<span></span>');
            $display.html(' | ' + state);
            $display.css('color', 'black');
            $yac.after($display);
        };
    }
    function handle_kanban_state($yac) {
        return function () {
            var link = $(this).attr('href') || '';

            if (!link.match(/view-kanban_states/)) {
                return;
            }

            var $display = $('<span></span>');
            $display.html(' | [<u>' + $(this).html() + '</u>]');
            $display.css('color', 'red');
            $yac.after($display);
        }
    }
});
