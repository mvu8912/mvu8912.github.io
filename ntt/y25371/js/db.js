function KVStore(args) {
    this.key        = args.key;
    this.searchable = args.searchable;
    this.data       = args.data;
    this.index      = "";
    this.kvstore    = {};
    this.original_keys_orders = [];

    this.key_pattern = args.key_pattern || "\\d+";
    this.key_pattern = '(' + this.key_pattern + ')';

    var seperator = '::%--%::';

    this.data.map((row) => {
        this.original_keys_orders.push(row[this.key]);
        this.kvstore[row[this.key]] = row;
        this.searchable.map((search_field) => this.index += search_field + seperator + row[this.key] + seperator + row[search_field] + "\n");
    });

    this.link = (another_kvstore) => {
        var new_keys_orders = [].concat(this.original_keys_orders, another_kvstore.original_keys_orders),
            new_index       = this.index + another_kvstore.index;

        this.original_keys_orders            = new_keys_orders,
        another_kvstore.original_keys_orders = new_keys_orders,

        this.index            = new_index,
        another_kvstore.index = new_index;
    };

    this.search = (args) => {
        var search_field = args.field;
        var keyword      = args.keyword;

        if (!keyword) return [];

        keyword = keyword.replace(new RegExp(seperator, 'g'), '');

        if (!keyword) return [];

        var search_pattern = new RegExp('^' + search_field + seperator + this.key_pattern + seperator + '.*' + keyword + ".*$", 'gmi');
        var matches        = this.index.match(search_pattern) || [];

        return matches.map((match) => {
            var key = match.replace(search_pattern, '$1');
            var row = this.kvstore[key];
            if (row) return row;
        });
    };

    this.keys = (args) => {
        var want = new hash(args).item('want') || '';
        var keys = [];
        for(var i in this.original_keys_orders) {
            var key = this.original_keys_orders[i];
            var row = this.kvstore[key];
            if (!row) {
                continue;
            }
            else if (want == 'row') {
                keys.push(row);
            }
            else {
                keys.push(key);
            }
        }
        return keys;
    };

    this.values = (    ) => this.keys({want: 'row'});
    this.item   = (key ) => this.kvstore[key];
    this.items  = (keys) => keys.map(this.item);

    this.delete_item = (key) => {
        var value = this.kvstore[key];
        delete this.kvstore[key];
        return value;
    };

    this.delete_items = (keys)  => keys.map(this.delete_item);
    this.add_item     = (item)  => this.kvstore[item[this.key]] = item;
    this.add_items    = (items) => items.map(this.add_item);

    this.sort = (rows, field, way) => {
        return way == 'a-z' ?
            rows.sort((a, b) => {
                a = (a[field] + '').toUpperCase(),
                b = (b[field] + '').toUpperCase();
                return a < b ? -1
                             : a > b ? 1 : 0
            })
            : rows.sort((a, b) => {
                a = (a[field] + '').toUpperCase(),
                b = (b[field] + '').toUpperCase();
                return a > b ? -1
                             : a < b ? 1 : 0
            })
    };
}
