component extends="coldbox.system.Interceptor" {

    property name="flash" inject="coldbox:flash";
    property name="moduleService" inject="coldbox:moduleService";
    property name="handlerService" inject="coldbox:handlerService";
    property name="coldboxVersion" inject="coldbox:fwSetting:version";
    property name="invalidEventHandler" inject="coldbox:setting:invalidEventHandler";

    void function configure() {
        variables.onInvalidEventHandlerBean = javacast( "null", "" );
        if ( len( variables.invalidEventHandler ) ) {
            variables.onInvalidEventHandlerBean = handlerService.getHandlerBean( variables.invalidEventHandler );
        }
    }

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
    function preProcess(
        event,
        rc,
        prc,
        interceptData,
        buffer
    ) {
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

        if ( isInvalidEventHandlerBean( handlerBean ) ) {
            // ColdBox tries to detect invalid event handler loops by keeping
            // track of the last invalid event to fire.  If that invalid event
            // fires twice, it throws a hard exception to prevent infinite loops.
            // Unfortunately for us, just attempting to get a handler bean
            // starts the invalid event handling.  Here, if we got the invalid
            // event handler bean back, we reset the `_lastInvalidEvent` so
            // ColdBox can handle the invalid event properly.
            request._lastInvalidEvent = variables.invalidEventHandler;
            return;
        }

        if ( handlerBean.getHandler() == "" ) {
            return;
        }

        if ( !handlerBean.isMetadataLoaded() ) {
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

        if ( !structKeyExists( handlerMetadata, "secured" ) ) {
            return false;
        }

        if ( handlerMetadata.secured == false ) {
            return false;
        }

        if ( !invoke( props.authenticationService, props.methodNames[ "isLoggedIn" ] ) ) {
            saveSecuredUrl( event );

            // Override the coldbox.cfc global onAuthenticationFailure if it exists in the handler.
            // Per docs, they will override for Ajax requests also.
            var eventType = event.isAjax() ? "authenticationAjaxOverrideEvent" : "authenticationOverrideEvent";
            var relocateEvent = getOverrideEvent(
                handlerMetadata,
                event,
                props,
                eventType
            );
            var overrideAction = props.overrideActions[ eventType ];

            // If the override is within the same handler that is being secured,
            // we have to override the event instead of relocating. Prevents a circle of death.
            if ( event.getCurrentHandler() == handlerService.getHandlerBean( relocateEvent ).getHandler() ) {
                overrideAction = "override";
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
        neededPermissions = isArray( neededPermissions ) ? neededPermissions : listToArray( neededPermissions );

        if ( arrayIsEmpty( neededPermissions ) ) {
            return false;
        }

        var loggedInUser = invoke( props.authenticationService, props.methodNames[ "getUser" ] );

        for ( var permission in neededPermissions ) {
            if ( invoke( loggedInUser, props.methodNames[ "hasPermission" ], { permission: permission } ) ) {
                return false;
            }
        }

        saveSecuredUrl( event );

        // At this point, we know the user did NOT have any of the required permissions,
        // so we will fire the appropriate authorization failure events
        var eventType = event.isAjax() ? "authorizationAjaxOverrideEvent" : "authorizationOverrideEvent";
        var relocateEvent = getOverrideEvent(
            handlerMetadata,
            event,
            props,
            eventType
        );
        var overrideAction = props.overrideActions[ eventType ];

        // If the override is within the same handler that is being secured,
        // we have to override the event instead of relocating. Prevents a circle of death.
        if ( event.getCurrentHandler() == handlerService.getHandlerBean( relocateEvent ).getHandler() ) {
            overrideAction = "override";
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

        if ( !structKeyExists( handlerMetadata, "functions" ) ) {
            return false;
        }

        var funcsMetadata = arrayFilter( handlerMetadata.functions, function( func ) {
            return func.name == event.getCurrentAction();
        } );

        if ( arrayIsEmpty( funcsMetadata ) ) {
            return false;
        }

        var targetActionMetadata = funcsMetadata[ 1 ];
        if ( !structKeyExists( targetActionMetadata, "secured" ) || targetActionMetadata.secured == false ) {
            return false;
        }

        if ( !invoke( props.authenticationService, props.methodNames[ "isLoggedIn" ] ) ) {
            saveSecuredUrl( event );

            var eventType = event.isAjax() ? "authenticationAjaxOverrideEvent" : "authenticationOverrideEvent";
            var relocateEvent = getOverrideEvent(
                handlerMetadata,
                event,
                props,
                eventType
            );
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
        neededPermissions = isArray( neededPermissions ) ? neededPermissions : listToArray( neededPermissions );

        if ( arrayIsEmpty( neededPermissions ) ) {
            return false;
        }

        var loggedInUser = invoke( props.authenticationService, props.methodNames[ "getUser" ] );

        for ( var permission in neededPermissions ) {
            if ( invoke( loggedInUser, props.methodNames[ "hasPermission" ], { permission: permission } ) ) {
                return false;
            }
        }

        saveSecuredUrl( event );

        // Override the coldbox.cfc global onAuthorizationFailure if it exists in the handler.
        // Per docs, they will override for Ajax requests also.
        var eventType = event.isAjax() ? "authorizationAjaxOverrideEvent" : "authorizationOverrideEvent";
        var relocateEvent = getOverrideEvent(
            handlerMetadata,
            event,
            props,
            eventType
        );
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
    /**
     * Override the coldbox.cfc global on[eventType]Failure if it exists in the handler.
     */
    private function getOverrideEvent(
        handlerMetadata,
        event,
        props,
        eventType
    ) {
        var handlerOverrides = arrayFilter( arguments.handlerMetadata.functions, function( func ) {
            // In case some other override comes up in the future, using switch
            switch ( eventType ) {
                case "authenticationOverrideEvent":
                case "authenticationAjaxOverrideEvent":
                    return func.name == "onAuthenticationFailure";
                case "authorizationOverrideEvent":
                case "authorizationAjaxOverrideEvent":
                    return func.name == "onAuthorizationFailure";
                default:
                    return false;
            }
        } );
        return handlerOverrides.isEmpty() ? arguments.props[ eventType ] : arguments.event.getCurrentHandler() & "." & handlerOverrides[
            1
        ].name;
    }

    private boolean function isInvalidEventHandlerBean( required handlerBean ) {
        if ( isNull( variables.onInvalidEventHandlerBean ) ) {
            return false;
        }

        return (
            variables.onInvalidEventHandlerBean.getInvocationPath() == arguments.handlerBean.getInvocationPath() &&
            variables.onInvalidEventHandlerBean.getHandler() == arguments.handlerBean.getHandler() &&
            variables.onInvalidEventHandlerBean.getMethod() == arguments.handlerBean.getMethod() &&
            variables.onInvalidEventHandlerBean.getModule() == arguments.handlerBean.getModule()
        );
    }

    /**
     * Flash the incoming secured Url so we can redirect to it or use it in the next request.
     *
     * @event The event object
     */
    private function saveSecuredUrl( required event ) {
        var securedUrl = arguments.event.getFullUrl();

        if ( arguments.event.isSES() ) {
            securedURL = arguments.event.buildLink(
                to = event.getCurrentRoutedURL(),
                queryString = CGI.QUERY_STRING,
                translate = false
            );
        }

        // Flash it and place it in RC as well
        flash.put( "_securedUrl", securedUrl );
        arguments.event.setValue( "_securedUrl", securedUrl );
    }

}
