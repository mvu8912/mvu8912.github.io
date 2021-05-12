// ; https://mvu8912.github.io/ntt/confluence/resource-planner.js

$(document).ready(() => {
    var now = new Date();

    find_element('.expand-control-text', now.getYear() + 1900, ($link) => {
        $link.click();
        find_element('.expand-control-text', now.toLocaleString('default', { month: 'long' }), ($link) => {
            $link.click()
            find_element('.confluenceTd', 'Michael', ($me) => {
                $([document.documentElement, document.body]).animate({
                    scrollTop: $me.offset().top - 100
                }, 2000);
            });
        });
    });

    function find_element(selector, name, then) {
        var wait = setInterval(() => {
            var $found;

            $(selector).filter((i, element) => {
                var $element = $(element);
                if ($element.text().match(new RegExp('^' + name))) {
                    $found = $element;
                }
            });

            if (!$found) return;

            clearInterval(wait);

            if (then) then($found);
        }, 1000);
    }
});
