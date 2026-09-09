({
	handleOnChange : function(component, event, helper) {
        component.set( "v.selectedRecordId", event.getParams( "fields" ).value );
        var id = component.get('v.Id');
        window.open('/lightning/r/Account/' + id + '/view','_top')
    }
})