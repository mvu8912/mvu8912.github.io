setInterval(() => {
    let service = 'SOMETHING';
    let tilt_url = 'http://localhost:10350/api/override';

    $('tr').each((i, tr) => {
        let $row = $(tr); // Cache the current <tr>
        // Check if there's a button with text  in this <tr>
        let hasServiceLabel = $row.find('button').filter((i, btn) => {
            let label = $(btn).text().trim();
            if (!label) return false;
            else return label == service;
        }).length > 0;
        // If found, proceed to find the toggle
        if (!hasServiceLabel) return;
        $.ajax({
            url: tilt_url + '/trigger_mode',
            type: 'POST',
            data: JSON.stringify({"manifest_names":[service],"trigger_mode":2}),
            contentType: 'application/json; charset=utf-8',
            success: function(result) {
                console.log("Service: " + service + " has switched to manual mode");
            }
        });
    });
}, 5000);
