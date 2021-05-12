if (location.href.match(/view-change_requests/)) $(document).ready(function () {
    var users = {};
    var roles = {
        requested: {
            'Tech Auth': true,
            'Queue Manager': true,
            'Ops Manager': true,
            'Support Manager': true,
            'Eng Manager': true,
            'PSM': true,
            'Emergency': true,
        },
        simple: {
            'Requester': true,
            'Change Engineer': true,
        }
    };

    $('th').filter(function (i, j) {
        var $role = $(j);
        var role  = $role.text();
        var user;

        if (roles.requested[role]) {
            user = $role.siblings('td').text().match(/Requested - ([^\/]+)/)[1];
        }
        else if (roles.simple[role]) {
             user = $role.siblings('td').text();
        }
        else return;

        if (user) {
            user = user.replace(/^\s+/, '').replace(/\s+$/, '');
            users[user] ||= [];
            users[user].push(role);
        }
    });

    var logins = {};

    $('a').filter(function (i, j) {
        var $link = $(j);
        var username = $link.html();
        if (!users[username]) return;
        $link.html(username + ' (' +  users[username].join(' | ') + ')');
        logins[username] ||= {};
        logins[username]['id'] = $link.attr('href').match(/id=(\d+)/)[1];
        logins[username]['link'] ||= [];
        logins[username]['link'].push($link);
    });

    var usernames = Object.keys(logins)

    function set_iam () {
        if (usernames.length == 0) return;

        var username = usernames.shift();
        var login    = logins[username];

        function fetch() {
            var $link = login.link[0];
            var link  = $link.attr('href');
            
            $.get(link, function (html) {
                $('th', html).filter(function (i, j) {
                    if (!$(j).html().match(/Username/)) return;
                    var login_username = $(j).siblings('td').text().replace(/^\s+/, '').replace(/\s+$/, '');
                    
                    for(var i in login.link) {
                        var $link = login.link[i];
                        add_iam($link, login_username);
                    }

                    set_iam();
                });
            });
        }
        fetch();
    }
    set_iam();

    function add_iam($link, login) {
        if (location.href.match(/iam=/)) {
            $link.attr('href',
                location.href.replace(/iam=[^&]+/, 'iam=' + login)
            ).prepend('[+] iam=');
        }
        else {
            $link.attr('href',
                location.href + '&iam=' + login
            ).prepend('[+] iam=');
        }
    };
});
