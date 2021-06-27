(run => {
    var retry = setInterval(() => {
        try {
            var login = get_credential();
            if (login.done()) {
                return clearInterval(retry);
            }
            var $username = $(login.field.username);
            var $password = $(login.field.password);
            var username  = login.detail.username;
            var password  = login.detail.password;
            var submit    = $(login.field.submit);
            clearInterval(retry);
            $username.val(username);
            $password.val(password);
            setTimeout(() => submit.click(), 5000);
        }
        catch (e) {
        }
    }, 1000);
})();
