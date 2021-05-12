var single_run_log = {};

function single_run(tag, callback) {
    if (!single_run_log.hasOwnProperty(tag)) {
        single_run_log[tag] = 0;
    }

    if (single_run_log[tag] == 1) {
        console.log(tag + ' is in progress ...');
        return;
    }

    single_run_log[tag] = 1;

    callback(() => {
        setTimeout(function () {
            single_run_log[tag] = 0;
        }, 1000);
    });
}

function non_blocking_loop(args) {
    if (!args.progress) {
        args.progress = function (state) {};
    }

    args.progress('begin');

    args._occupated = false;

    var loop = setInterval(function () {
        if (args._occupated) return;

        args._occupated = true;

        while (args.control() != 'last') {
            args.progress('start work');

            args.callback();

            args.progress('end work');

            if (args.control() == 'pause') {
                args.progress('pause');
                args._occupated = false;
                return;
            }
        }

        args.progress('last');
        clearInterval(loop);
        if (args.then) args.then();
        return;

    }, args.pause_ms || 500);
}

function hash(data) {
    this.data = data || {};

    this.item = (path, value) => {
        var keys = _keys(path);
        var hash = _last_item(this.data, keys);

        var last = hash.item,
            key  = hash.key;

        if (typeof(value) != 'undefined') {
            last[key] = value;
        }

        return last[key];
    };

    this.keys = (path) => {
        var hash = this.item(path);
        return (typeof(hash) == 'object') ? Object.keys(hash) : [];
    };

    this.values = (path) => {
        var hash = this.item(path);
        return (typeof(hash) == 'object') ? Object.keys(hash).map((key) => {return hash[key]}) : [];
    };

    this.delete = (path) => {
        var keys = _keys(path);
        var hash = _last_item(this.data, keys);

        var last = hash.item,
            key  = hash.key;

        var value = last[key];

        delete last[key];

        return value;
    };

    this.exists = (path) => {
        var keys = _keys(path);
        var hash = _last_item(this.data, keys);

        var last = hash.item,
            key  = hash.key;

        return key in last;
    };

    function _keys(path) {
        if (typeof(path) == 'undefined') {
            console.error('Missing path');
        }

        var keys = [];

        if (Array.isArray(path)) {
            path.filter((key) => {
                var _ = _keys(key);
                keys = keys.concat(_);
                return;
            });
        }
        else {
            path.split(/\./).map((key) => {
                if (key.match(/\./)) {
                    keys = keys.concat(_keys(key));
                }
                else {
                    keys.push(key);
                }
            });
        }

        return keys;
    }

    function _last_item(data, keys) {
        var last = data;

        for(var i = 0; i < keys.length -1; i++) {
            var key = keys[i];
            if (key in last) {
                last = last[key];
            }
            else {
                last = last[key] = {};
            }
        }

        var last_key = keys[keys.length -1];

        return {
            item: last,
            key:  last_key,
        };
    }
}
