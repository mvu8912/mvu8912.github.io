function create_selective_list(args) {
    var $selector = args.selector,
    kvdb     = args.kvdb,
    side     = args.side,
    page     = 1,
    size     = args.page_size || 15,
    selected = {},
    $list    = $('<div>').addClass('list'),
    after_selected = args.after_selected,

    load_list = (args) => {
       var $data = $('<select>').addClass('data')
                                .css('min-width', '15em')
                                .css('overflow-y', 'auto')
                                .attr('multiple', true)
                                .attr('size', size + 1),

        page = args['page'] || 1,
        $unselect_btn  = $('<input>').attr('type', 'button').addClass('unselect').val('Unselect'),
        $selectall_btn = $('<input>').attr('type', 'button').addClass('select_all').val('Select All'),

        update_selected_btns = () => {
            if (Object.keys(selected).length >= 1) {
                $unselect_btn.show();
                $selectall_btn.hide();
            }
            else {
                $unselect_btn.hide();
                $selectall_btn.show();
            }
            after_selected(selected);
        },

        check_selected_options = () => {
            $('option', $data).filter((i, option) => {
                var $option = $(option);
                var row     = $option.data('row');

                if ($option.is(':selected')) {
                    selected[row.value] = true;
                }
                else {
                    delete selected[row.value];
                }
            });

            update_selected_btns();
        },

        $list = $('<div>').addClass('list')
                          .append($data)
                          .css('min-width',     '15em')
                          .data('load_list',    load_list)
                          .data('get_selected', (    ) => selected                               )
                          .data('unselect',     (    ) => selected = {}                          )
                          .data('select',       (keys) => keys.map((key) => selected[key] = true));

        $('.list', $selector).replaceWith($list);

        var datalist = kvdb.values();

        if (args.search) {
            datalist = kvdb.search({
                field: 'name',
                keyword: args.search,
            });
        }

        $selectall_btn.click(() => {
            selected = {};
            kvdb.keys().map((key) => {
                var row = {};
                row[key] = true;
                Object.assign(selected, row);
            });
            load_list(Object.assign(args, {page: 1}));
            after_selected(selected);
        });

        $unselect_btn.click(() => {
            selected = {};
            load_list(Object.assign(args, {page: 1}));
        });

        $data.keyup(check_selected_options);

        var total_rows = datalist.length;

        var total_pages = total_rows / size;

        if ((total_pages + '').match(/\./)) {
            total_pages = (total_pages + '').replace(/\.\d+$/, '') * 1 + 1;
        }

        if (page == 'last') {
            page = total_pages;
        }

        var offset = (page * size) - size;

        check_page_range = (page_info, $input) => {
            var page        = page_info.page,
                total_pages = page_info.total_pages;

            if (page < 0 || page > total_pages || (page + '').match(/\D/)) {
                if ($input) {
                    $input.css('color', 'red');
                }
                return false;
            }
            else if ($input) {
                $input.css('color', '');
            }

            return true;
        };

        if ((total_pages + '').match(/\./)) {
            total_pages = (total_pages+1).toFixed(0) * 1;
        }

        if (!check_page_range({page: page, total_pages: total_pages})) {
            if (args.then) {
                args.then({list: $list, last_page: total_pages, data: $data});
            }
            return;
        }

        for(var i = offset; i < offset + size; i++) {
            var row = datalist[i];

            if (!row) {
                continue;
            }

            var $option = $('<option>').text(row.name)
                                       .val(row.value)
                                       .data('row', row);

            if (selected[row.value]) {
                $option.attr('selected', true);
            }
            else {
                $option.attr('selected', false);
            }

            $option.click(check_selected_options);

            $data.append($option);
        }

        var total_page_len = (total_pages + '').length;

        if (total_page_len <= 3) {
            total_page_len += 3;
        }

        var $nav   = $('<div>'),
            $first = $('<input>').addClass('first').attr('type', 'button').val('|<'),
            $prev  = $('<input>').addClass('prev').attr('type', 'button').val('<'),
            $next  = $('<input>').addClass('next').attr('type', 'button').val('>'),
            $last  = $('<input>').addClass('last').attr('type', 'button').val('>|'),
            $pn    = $('<input>').addClass('pn').attr('type', 'text').val(page)
                                 .css('text-align', 'center')
                                 .css('width', total_page_len + 'em'),
            $rows_show = $('<span>').text(total_rows + ' ent' + (total_rows == 1 ? 'y' : 'ies'));

        $list.data('nav', $nav)
             .data('page_info', {page: page, total_pages: total_pages});

        $list.append(
            $nav.append(
                $first,
                $prev,
                $pn,
                $next,
                $last,
                $('<div>'),
                $selectall_btn,
                $unselect_btn,
                $rows_show
            )
        );

        if (page <= 1) {
            $first.attr('disabled', true);
            $prev.attr('disabled', true);
        }

        if (page >= total_pages) {
            $next.attr('disabled', true);
            $last.attr('disabled', true);
        }

        $first.click(() => {
            load_list(Object.assign(args, {page: 1}));
        });

        $prev.click(() => {
            load_list(Object.assign(args, {page: page * 1 - 1}));
        });

        $next.click(() => {
            load_list(Object.assign(args, {page: page * 1 + 1}));
        });

        $last.click(() => {
            load_list(Object.assign(args, {page: total_pages}));
        });

        var get_pn = () => {return $pn};

        $pn.keyup((e) => {
            var page = $(e.target).val().replace(/\D/g, '');

            if (!check_page_range($list.data('page_info'), $pn)) {
                return;
            }

            load_list(Object.assign(args, {page: page, then: (args) => {
                $('.pn', args.list).focus();
            }}));
        });

        update_selected_btns();

        if (args.then) {
            args.then({list: $list, last_page: total_pages, data: $data});
        }
    };

    $selector.append($list);

    load_list({page: page});

    after_selected(selected);
}
