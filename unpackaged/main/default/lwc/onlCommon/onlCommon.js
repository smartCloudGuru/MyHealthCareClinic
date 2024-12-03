const defaultRecordType = '012000000000000AAA';

const distanceOptions = [
    {label: '5 miles', value: '5'},
    {label: '10 miles', value: '10'},
    {label: '25 miles', value: '25'},
    {label: '50 miles', value: '50'},
    {label: '100 miles', value: '100'}
    // {label: 'Any distance', value: null}
];


function parsePicklistData(data, error, controllerValue) {
    let options = [];

    if (data) {
        options = [];
        // console.log('::data:', data);
        let cValue = null;
        if (controllerValue) cValue = data.controllerValues[controllerValue];
        Object.entries(data.values).forEach(val => {
            if (!controllerValue || (val[1].validFor && val[1].validFor.includes(cValue)))
                options.push({'label': val[1].label, 'value': val[1].value});
        });
    } else if (error) {
        // handle errors
        console.log('parsePicklistData got error ' + JSON.stringify(error));
    }

    return options;
}

export {
    parsePicklistData,
    distanceOptions,
    defaultRecordType
}