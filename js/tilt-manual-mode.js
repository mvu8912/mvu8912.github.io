function manual(service) {
    if (service == null) {
        console.log('No service was provided.');
        return;
    }

    $(document).ready(() => {
        // Find all <tr> elements, then filter based on the presence of a button with text 
        $('tr').each(() => {
            var $row = $(this); // Cache the current <tr>
            
            // Check if there's a button with text  in this <tr>
            var hasServiceLabel = $row.find('button').filter(() => {
                return $(this).text().trim().match(service);
            }).length > 0;
            
            // If found, proceed to find the toggle
            if (!hasServiceLabel) return;

            // Find the toggle button within the same <tr>
            var $toggle = $row.find('button').filter(() => {
                var title = $(this).attr('title');
                // We're looking for a button without the specific title attribute
                return !title.match(/changes don\'t trigger updates/);
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
