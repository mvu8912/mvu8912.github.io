function manual(service) {
    if (service == null) {
        console.log('No service was provided.');
        return;
    }

    $(document).ready(() => {
        // Find all <tr> elements, then filter based on the presence of a button with text 
        $('tr').each(tr => {
            let $row = $(tr.target); // Cache the current <tr>
            
            // Check if there's a button with text  in this <tr>
            let hasServiceLabel = $row.find('button').filter((i, btn) => {
                let label = $(btn).text().trim();
                if (label == null) return false;
                else return label == service;
            }).length > 0;
            
            // If found, proceed to find the toggle
            if (!hasServiceLabel) return;

            // Find the toggle button within the same <tr>
            // We're looking for a button without the specific title attribute
            let $toggle = $row.find('button').filter((i, toggle) => {
                let title = $(toggle).attr('title');
                if (!title) return false;
                else if (title.match(/Auto\:/)) return false;
                else return true;
            });
            
            // If the toggle button is found and it's not in manual mode, click it
            if ($toggle.length > 0) {
                $toggle.click();
                console.log('Toggle clicked because it was not in manual mode.');
            } else {
                console.log('No toggle needing a click was found.');
            }
        });
    });
}
