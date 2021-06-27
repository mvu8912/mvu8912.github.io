(run => {
    var retry = setInterval(() => {
        try {
            var login = get_credential();
            clearnInterval(retury);
            var $username = login.field.username,
                $password = login.field.password,
                username  = login.detail.username,
                password  = login.detail.password,
                submit    = login.field.submit;
            $username.val(username);
            $password.val(password);
            submit.click()
        }
        catch (e) {
        }
    }, 1000);
})();
