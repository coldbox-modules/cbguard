component singleton {

    property name="settings" inject="coldbox:moduleSettings:cbguard";
    property name="moduleService" inject="coldbox:moduleService";
    property name="wirebox" inject="wirebox";

    function allows( required any permissions, struct additionalArgs = {}, boolean negate = false ) {
        var context = preflight();

        for ( var permission in arrayWrap( arguments.permissions ) ) {
            var hasPermission = invoke(
                context.user,
                context.props.methodNames[ "hasPermission" ],
                {
                    "permission": permission,
                    "additionalArgs": arguments.additionalArgs
                }
            );

            if ( hasPermission ) {
                return true;
            }
        }

        return false;
    }

    function denies( required any permissions, struct additionalArgs = {} ) {
        var context = preflight();

        for ( var permission in arrayWrap( arguments.permissions ) ) {
            var hasPermission = invoke(
                context.user,
                context.props.methodNames[ "hasPermission" ],
                {
                    "permission": permission,
                    "additionalArgs": arguments.additionalArgs
                }
            );

            if ( !hasPermission ) {
                return true;
            }
        }

        return false;
    }

    public boolean function all( required any permissions, struct additionalArgs = {} ) {
        var context = preflight();

        for ( var permission in arrayWrap( arguments.permissions ) ) {
            var hasPermission = invoke(
                context.user,
                context.props.methodNames[ "hasPermission" ],
                {
                    "permission": permission,
                    "additionalArgs": arguments.additionalArgs
                }
            );

            if ( !hasPermission ) {
                return false;
            }
        }

        return true;
    }

    public boolean function none( required any permissions, struct additionalArgs = {} ) {
        var context = preflight();

        for ( var permission in arrayWrap( arguments.permissions ) ) {
            var hasPermission = invoke(
                context.user,
                context.props.methodNames[ "hasPermission" ],
                {
                    "permission": permission,
                    "additionalArgs": arguments.additionalArgs
                }
            );

            if ( hasPermission ) {
                return false;
            }
        }

        return true;
    }

    public void function authorize(
        required any permissions,
        struct additionalArgs = {},
        string errorMessage
    ) {
        var context = preflight();

        var failedPermission = "";
        for ( var permission in arrayWrap( arguments.permissions ) ) {
            var hasPermission = invoke(
                context.user,
                context.props.methodNames[ "hasPermission" ],
                {
                    "permission": permission,
                    "additionalArgs": arguments.additionalArgs
                }
            );

            if ( !hasPermission ) {
                failedPermission = permission;
                break;
            }
        }

        if ( failedPermission != "" ) {
            param arguments.errorMessage = "The logged in user is not authorized to access this resource";

            if ( isClosure( arguments.errorMessage ) || isCustomFunction( arguments.errorMessage ) ) {
                arguments.errorMessage = arguments.errorMessage(
                    failedPermission = failedPermission,
                    user = context.user,
                    additionalArgs = arguments.additionalArgs
                );
            }

            throw(
                type = "NotAuthorized",
                message = arguments.errorMessage
            );
        }
    }

    private struct function preflight() {
        var event = variables.wirebox.getInstance( dsl = "coldbox:requestContext" );

        var props = {};
        structAppend( props, variables.settings, true );
        if ( event.getCurrentModule() != "" ) {
            var moduleConfig = variables.moduleService.getModuleConfigCache()[ event.getCurrentModule() ];
            var moduleSettings = moduleConfig.getPropertyMixin( "settings", "variables", {} );
            if ( structKeyExists( moduleSettings, "cbguard" ) ) {
                structAppend( props, moduleSettings.cbguard, true );
            }
        }

        if ( isSimpleValue( props.authenticationService ) ) {
            props.authenticationService = variables.wirebox.getInstance( dsl = props.authenticationService );
        }

        if ( ! invoke( props.authenticationService, props.methodNames[ "isLoggedIn" ] ) ) {
            throw(
                type = "NotLoggedIn",
                message = "No user is logged in to authorize."
            )
        }

        return {
            "event": event,
            "props": props,
            "user": invoke( props.authenticationService, props.methodNames[ "getUser" ] )
        };
    }

    private array function arrayWrap( required any items ) {
        return isArray( arguments.items ) ? items : items.listToArray();
    }

}
