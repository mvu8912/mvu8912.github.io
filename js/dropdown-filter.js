$(document).ready(function () {
    var origin_options = {};
    var default_value  = {};
    var placeholder    = {};

    $('select').filter((i, select) => {
        $(select).after(
            $('<input>').addClass('filter')
                        .attr('type', 'text')
                        .attr('target', $(select).attr('name'))
        );
    });

    $('.filter').focus(function () {
        var $filter = $(this);
        var target  = $filter.attr('target');
        var width   = $filter.attr('width') || '10ch';
        $filter.css({width: width, 'border-width': '0px'});
        $filter.attr('placeholder', placeholder[target]);
        $filter.keyup();
    });

    $('.filter').blur(function () {
        var $filter = $(this);
        $filter.css({width: '2ch', 'border-width': '0px'});
        $filter.attr('placeholder', '☺');
        $filter.val('');
    });

    // Backup Options
    $('.filter').each(function () {
        var $filter = $(this);
        var target  = $filter.attr('target');
        var $target = $('select[name="' + target + '"]');
        origin_options[target] = [];
        var $options = $target.find('option');

        if ($options.length < 10 || $target.attr('disabled')) {
            $filter.remove();
        }

        $options.each(function (i, option) {
            origin_options[target].push($(option));
            default_value[target] = $target.val();
        });

        placeholder[target] = $filter.attr('placeholder');
        $filter.blur();
    });

    // Key Worker
    $('.filter').keyup(function () {
        var $filter = $(this).css({color: 'black'});
        var search  = $filter.val();
        var target  = $filter.attr('target');
        var $target = $('select[name="' + target + '"]');

        $target.html(origin_options[target][0]);

        $.each(origin_options[target], function (i, option) {
            $target.append(option);
        });

        $target.val(default_value[target]);

        if (!search) return;

        var found_value = {};
        var found_options = $target.find('option').filter(function (i, option) {
            var found_option = $(option).text().toLowerCase().match(search.split(/,/).join('.+').toLowerCase());
            if (!found_option) return;
            found_value[$(option).val()] = true;
            return found_option;
        });

        if (found_options.length == 0) {
            $filter.css({color: 'red'});
            return;
        }

        $target.html('');

        $.each(found_options, function (i, option) {
            $target.append(option);
        });

        if ($filter.attr('select_first_choice')) {
            default_value[target] = $target.val();
        }
        else {
            $target.val(0);
        }
    });
});

