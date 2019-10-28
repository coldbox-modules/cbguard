component extends="coldbox.system.Interceptor"{

    property name="coldboxVersion" inject="coldbox:fwSetting:version";
    property name="handlerService" inject="coldbox:handlerService";
    property name="moduleService" inject="coldbox:moduleService";

    void function configure() {}

    /**
    * Check the current event's handler for `secured` metadata annotations
    * on the handler and the current action.
    *
    * If a `secured` annotation is found, the permissions list attached
    * is checked against the current user's permissions.
    *
    * If the user is not logged in or does not have one of the required permissions,
    * the event is overridden to the event specified in module settings.
    */
    function preProcess( event, rc, prc, interceptData, buffer ) {
        if ( event.getHTTPMethod() == "OPTIONS" ) {
            return;
        }

        var overrides = {};
        if ( event.getCurrentModule() != "" ) {
            var moduleConfig = moduleService.getModuleConfigCache()[ event.getCurrentModule() ];
            var moduleSettings = moduleConfig.getPropertyMixin( "settings", "variables", {} );
            if ( structKeyExists( moduleSettings, "cbguard" ) ) {
                overrides = moduleSettings.cbguard;
            }
        }

        var handlerBean = handlerService.getHandlerBean( event.getCurrentEvent() );
        if ( handlerBean.getHandler() == "" ) {
            return;
        }

        if ( ! handlerBean.isMetadataLoaded() ) {
            handlerService.getHandler( handlerBean, event );
        }
        var handlerMetadata = handlerBean.getHandlerMetadata();

        return notAuthorizedForHandler( handlerMetadata, event, overrides ) ||
            notAuthorizedForAction( handlerMetadata, event, overrides );
    }

    /**
    * Check the current event's handler for `secured` metadata annotations.
    *
    * If a `secured` annotation is found, the permissions list attached
    * is checked against the current user's permissions.
    *
    * If the user is not logged in or does not have one of the required permissions,
    * the event is overridden to the event specified in module settings.
    */
    private function notAuthorizedForHandler( handlerMetadata, event, overrides = {} ) {
        var props = {};
        structAppend( props, variables.properties, true );
        structAppend( props, overrides, true );

        if ( isSimpleValue( props.authenticationService ) ) {
            props.authenticationService = wirebox.getInstance( props.authenticationService );
        }
        param props.authenticationOverrideEvent = "";
        param props.authenticationAjaxOverrideEvent = props.authenticationOverrideEvent;
        param props.authorizationOverrideEvent = "";
        param props.authorizationAjaxOverrideEvent = props.authorizationOverrideEvent;
    
        if ( ! structKeyExists( handlerMetadata, "secured" ) ) {
            return false;
        }
        if ( handlerMetadata.secured == false ) {
            return false;
        }

        if ( ! invoke( props.authenticationService, props.methodNames[ "isLoggedIn" ] ) ) {
            //override the coldbox.cfc global onAuthenticationFailure if it exists in the handler. Per docs, they will override for Ajax requests also.  
            props.override = "authenticationOverrideEvent"
            props[props.override] = getOverride(handlerMetadata, event, props);
            var eventType = event.isAjax() ? "authenticationAjaxOverrideEvent" : props.override;
            var relocateEvent = props[ eventType ];
            var overrideAction = props.overrideActions[ eventType ];
            //If the override is within the same handler that is being secured, we have to override the event instead of relocating. Prevents a circle of death.
            props.overrideHandler = handlerService.getHandlerBean( props[props.override] ).getHandler();
            if(props.overrideHandler EQ event.getCurrentHandler() ){
                overrideAction = 'override';
            } 
            switch ( overrideAction ) {
                case "relocate":
                    relocate( relocateEvent );
                    break;
                case "override":
                    event.overrideEvent( relocateEvent );
                    break;
                default:
                    throw(
                        type = "InvalidOverideActionType",
                        message = "The type [#overrideAction#] is not a valid override action.  Valid types are ['relocate', 'override']."
                    );
            }
            return true;
        }

        var neededPermissions = handlerMetadata.secured;
        neededPermissions = isArray( neededPermissions ) ?
            neededPermissions :
            listToArray( neededPermissions );

        if ( arrayIsEmpty( neededPermissions ) ) {
            return false;
        }

        var loggedInUser = invoke( props.authenticationService, props.methodNames[ "getUser" ] );

        for ( var permission in neededPermissions ) {
            if ( invoke( loggedInUser, props.methodNames[ "hasPermission" ], { permission = permission } ) ) {
                return false;
            }
        }
        props.override = "authorizationOverrideEvent";
        props[props.override] = getOverride(handlerMetadata, event, props);
        var eventType = event.isAjax() ? "authorizationAjaxOverrideEvent" : props.override;
        var relocateEvent = props[ eventType ];
        var overrideAction = props.overrideActions[ eventType ];
        //If the override is within the same handler that is being secured, we have to override the event instead of relocating. Prevents a circle of death.
        props.overrideHandler = handlerService.getHandlerBean( props[props.override] ).getHandler();
        if(props.overrideHandler EQ event.getCurrentHandler() ){
            overrideAction = 'override';
        } 
        switch ( overrideAction ) {
            case "relocate":
                relocate( relocateEvent );
                break;
            case "override":
                event.overrideEvent( relocateEvent );
                break;
            default:
                throw(
                    type = "InvalidOverideActionType",
                    message = "The type [#overrideAction#] is not a valid override action.  Valid types are ['relocate', 'override']."
                );
        }
        return true;
    }

    /**
    * Check the current event's action for `secured` metadata annotations.
    *
    * If a `secured` annotation is found, the permissions list attached
    * is checked against the current user's permissions.
    *
    * If the user is not logged in or does not have one of the required permissions,
    * the event is overridden to the event specified in module settings.
    */
    private function notAuthorizedForAction( handlerMetadata, event, overrides = {} ) {
        var props = {};
        structAppend( props, variables.properties, true );
        structAppend( props, overrides, true );

        if ( isSimpleValue( props.authenticationService ) ) {
            props.authenticationService = wirebox.getInstance( props.authenticationService );
        }
        param props.authenticationOverrideEvent = "";
        param props.authenticationAjaxOverrideEvent = props.authenticationOverrideEvent;
        param props.authorizationOverrideEvent = "";
        param props.authorizationAjaxOverrideEvent = props.authorizationOverrideEvent;

        if ( ! structKeyExists( handlerMetadata, "functions" ) ) {
            return false;
        }

        var funcsMetadata = arrayFilter( handlerMetadata.functions, function( func ) {
            return func.name == event.getCurrentAction();
        } );

        if ( arrayIsEmpty( funcsMetadata ) ) {
            return false;
        }

        var targetActionMetadata = funcsMetadata[ 1 ];
        if ( ! structKeyExists( targetActionMetadata, "secured" ) || targetActionMetadata.secured == false ) {
            return false;
        }
        if ( ! invoke( props.authenticationService, props.methodNames[ "isLoggedIn" ] ) ) {
            props.override = "authenticationOverrideEvent";
            props[props.override] = getOverride(handlerMetadata, event, props);
            var eventType = event.isAjax() ? "authenticationAjaxOverrideEvent" : props.override;
            var relocateEvent = props[ eventType ];
            var overrideAction = props.overrideActions[ eventType ];
            switch ( overrideAction ) {
                case "relocate":
                    relocate( relocateEvent );
                    break;
                case "override":
                    event.overrideEvent( relocateEvent );
                    break;
                default:
                    throw(
                        type = "InvalidOverideActionType",
                        message = "The type [#overrideAction#] is not a valid override action.  Valid types are ['relocate', 'override']."
                    );
            }
            return true;
        }

        var neededPermissions = targetActionMetadata.secured;
        neededPermissions = isArray( neededPermissions ) ?
            neededPermissions :
            listToArray( neededPermissions );

        if ( arrayIsEmpty( neededPermissions ) ) {
            return false;
        }

        var loggedInUser = invoke( props.authenticationService, props.methodNames[ "getUser" ] );

        for ( var permission in neededPermissions ) {
            if ( invoke( loggedInUser, props.methodNames[ "hasPermission" ], { permission = permission } ) ) {
                return false;
            }
        }

        //override the coldbox.cfc global onAuthorizationFailure if it exists in the handler. Per docs, they will override for Ajax requests also.
        props.override = "authorizationOverrideEvent";
        props[props.override] = getOverride(handlerMetadata, event, props);
        var eventType = event.isAjax() ? "authorizationAjaxOverrideEvent" : props.override;
        var relocateEvent = props[ eventType ];
        var overrideAction = props.overrideActions[ eventType ];

        switch ( overrideAction ) {
            case "relocate":
                relocate( relocateEvent );
                break;
            case "override":
                event.overrideEvent( relocateEvent );
                break;
            default:
                throw(
                    type = "InvalidOverideActionType",
                    message = "The type [#overrideAction#] is not a valid override action.  Valid types are ['relocate', 'override']."
                );
        }
        return true;
    }
    /*
    **
    ** Override the coldbox.cfc global on[eventType]Failure if it exists in the handler.
    */
    private function getOverride(handlerMetadata, event, props ) {
        var override = arguments.props.override;
        var handlerOverride = arrayFilter( arguments.handlerMetadata.functions, function( func ) {
            //In case some other override comes up in the future, using switch
            switch(override){
                case "authenticationOverrideEvent":
                    return func.name == "onAuthenticationFailure";
                    break;
                case "authorizationOverrideEvent":
                    return func.name == "onAuthorizationFailure";
                    break;
                default:
                    //return empty
                    return false;
            }
        } );
        if ( !arrayIsEmpty( handlerOverride ) ) {
            // resolves to handler.onAuthenticationFailure || handler.onAuthorizationFailure
            return arguments.event.getCurrentHandler() & "." & handlerOverride[1].name;
        }else{
            return arguments.props[override];
        }
    }
}
