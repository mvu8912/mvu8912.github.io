(run => {
    var retry = setInterval(() => {
        try {
            var login = get_credential();
            if ($(login.done).length) return clearnInterval(retry);
            var $username = $(login.field.username);
            var $password = $(login.field.password);
            var username  = login.detail.username;
            var password  = login.detail.password;
            var submit    = $(login.field.submit);
            clearnInterval(retury);
            $username.val(username);
            $password.val(password);
            submit.click()
        }
        catch (e) {
        }
    }, 1000);
})();
