if (location.href.match(/action=view-(people|users)/)) {
    var global_id;

    $('a').filter((i, a) => {
        var $a = $(a);
        var found = $a.attr('href').match(/view-people&id=(.+)/);
        if (found && found[1] && found[1].match(/^NBOSS/)) {
            global_id = found[1];
        }
    });

    $("th").filter((i, th) => {
        var $th = $(th);
        if ($th.text() == "UUID") {
            var $value   = $th.siblings();
            var uuid     = $value.text();
            var $insight = $('<span>').append(
                $('<span>').html('&nbsp;'),

                $('<a>').attr("href", "https://eu-nboss.nttltd.global.ntt/users/" + uuid)
                        .attr('target', '_blank')
                        .html('[Goto Insight]'),

                $('<span>').html('&nbsp;'),

                $('<a>').attr("href", "https://eu-nboss.nttltd.global.ntt/angora-op-gui-eu?action=view-operator_portal_users&id=" + global_id)
                        .attr('target', '_blank')
                        .html('[Goto Angora]')
            );
            $value.append($insight);
        }
    });
}

function cp_sel(section_name) {
    var name;

    $('.header_title').filter((i, td) => {
        if ($(td).text().match(new RegExp(section_name.trim(), 'i'))) {
            $('.pivot-chooser select', $(td).parents('.section_content')).filter((i, select) => {
                var sel_name = $(select).attr('name');
                if (sel_name && sel_name.match(/^FPAR_/) && sel_name.match(/sel$/)) {
                    name = sel_name.split(/__/)[0];
                }
            })
        }
    });

    if (!name) {
        return console.error('Chooser "' + section_name + '" is not found');
    }

    var left   = name + '__notsel';
    var right  = name + '__sel';
    var $right = $('option', '[name='+right+']');

    if ($right.length == 0) {
        return console.error("Is any chooser in the page?");
    }

    var cmd = "";

    $right.filter((i, opt) => {
        cmd += "$('[name="+right+"]').append($('[name="+left+"] option[value="+$(opt).val()+"]'));\n";
    });

    console.log(cmd);
}
