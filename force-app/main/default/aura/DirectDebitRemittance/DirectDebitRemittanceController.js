({
	OpenComponent : function(c, e, h) {
        c.set("v.AreYouSure" , true);
    },
    
	OpenDDAuthComponent : function(c, e, h) {
        c.set("v.AreYouSureDDAuth" , true);
    },
    
    close: function(cmp, event){
        var closevar = event.getParam("close");
        if (closevar === 'CLOSEONLYCONF') {
            cmp.set("v.AreYouSure", false);
            cmp.set("v.AreYouSureDDAuth", false);
        }
        else if (closevar === 'CLOSEALL') {
            var dismissActionPanel = $A.get("e.force:closeQuickAction");
            dismissActionPanel.fire();
        }
    },
})