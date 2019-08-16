component extends="coldbox.system.Interceptor"{

    property name="handlerService" inject="coldbox:handlerService";
    property name="coldboxVersion" inject="coldbox:fwSetting:version";

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
        if ( isNull( variables.authenticationService ) ) {
            variables.authenticationService = wirebox.getInstance( getProperty( "AuthenticationService" ) );
        }

        if( listFirst( coldboxVersion, "." ) >= 5 ){
            var handlerBean = handlerService.getHandlerBean( event.getCurrentEvent() );
        } else {
            var handlerBean = handlerService.getRegisteredHandler( event.getCurrentEvent() );
        }
        var handler = handlerService.getHandler(
            handlerBean,
            event
        );

        var handlerMetadata = getMetadata( handler );

        return notAuthorizedForHandler( handlerMetadata, event ) ||
            notAuthorizedForAction( handlerMetadata, event );
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
    private function notAuthorizedForHandler( handlerMetadata, event ) {
        if ( ! structKeyExists( handlerMetadata, "secured" ) ) {
            return false;
        }

        if ( handlerMetadata.secured == false ) {
            return false;
        }

        if ( ! invoke( authenticationService, getProperty( "methodNames" )[ "isLoggedIn" ] ) ) {
            var eventType = event.isAjax() ? "authenticationAjaxOverrideEvent" : "authenticationOverrideEvent";
            var relocateEvent = getProperty( eventType );
            var overrideAction = getProperty( "overrideActions" )[ eventType ];
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

        var loggedInUser = invoke( authenticationService, getProperty( "methodNames" )[ "getUser" ] );

        for ( var permission in neededPermissions ) {
            if ( invoke( loggedInUser, getProperty( "methodNames" )[ "hasPermission" ], { permission = permission } ) ) {
                return false;
            }
        }

        var eventType = event.isAjax() ? "authorizationAjaxOverrideEvent" : "authorizationOverrideEvent";
        var relocateEvent = getProperty( eventType );
        var overrideAction = getProperty( "overrideActions" )[ eventType ];
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
    private function notAuthorizedForAction( handlerMetadata, event ) {
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

        if ( ! invoke( authenticationService, getProperty( "methodNames" )[ "isLoggedIn" ] ) ) {
            var eventType = event.isAjax() ? "authenticationAjaxOverrideEvent" : "authenticationOverrideEvent";
            var relocateEvent = getProperty( eventType );
            var overrideAction = getProperty( "overrideActions" )[ eventType ];
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

        var loggedInUser = invoke( authenticationService, getProperty( "methodNames" )[ "getUser" ] );

        for ( var permission in neededPermissions ) {
            if ( invoke( loggedInUser, getProperty( "methodNames" )[ "hasPermission" ], { permission = permission } ) ) {
                return false;
            }
        }

        var eventType = event.isAjax() ? "authorizationAjaxOverrideEvent" : "authorizationOverrideEvent";
        var relocateEvent = getProperty( eventType );
        var overrideAction = getProperty( "overrideActions" )[ eventType ];
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

}
