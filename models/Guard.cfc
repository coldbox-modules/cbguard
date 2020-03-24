component singleton accessors="true" {

    property name="settings" inject="coldbox:moduleSettings:cbguard";
    property name="moduleService" inject="coldbox:moduleService";
    property name="wirebox" inject="wirebox";

    property name="guards" type="struct";

    /**
     * Creates a new Guard service
     *
     * @returns cbguard.models.Guard
     */
    public Guard function init() {
        variables.guards = {};
        return this;
    }

    /**
     * Defines a new custom guard.  A custom guard is used instead of the
     * user model's `hasPermission` method.
     *
     * @name      The name of the permission to match for this custom guard.
     * @callback  The callback to resolve the custom guard. It should return a boolean.
     *            This can be one of the following:
     *                1. A UDF or closure.
     *                2. A component with an `authorize` method.
     *                3. A WireBox mapping that resolves to a component with an `authorize` method.
     *
     * @throws    InvalidGuardType
     *
     * @returns   cbguard.models.Guard
     */
    public Guard function define( required string name, required any callback ) {
        if ( isSimpleValue( arguments.callback ) ) {
            arguments.callback = variables.wirebox.getInstance( dsl = callback );
            if ( !structKeyExists( arguments.callback, "authorize" ) ) {
                throw(
                    type = "InvalidGuardType",
                    message = "A component guard must have an `authorize` method defined."
                );
            }
        } else if ( isClosure( arguments.callback ) || isCustomFunction( arguments.callback ) ) {
            arguments.callback = { "authorize": arguments.callback };
        } else {
            throw(
                type = "InvalidGuardType",
                message = "Cannot define a guard without either a component with an `authorize` method, a WireBox mapping to a component with an `authorize` method, or a closure or UDF function."
            );
        }

        variables.guards[ arguments.name ] = arguments.callback;
        return this;
    }

    /**
     * Removes a custom guard definition.
     *
     * @name     The name of the permission to remove the custom guard.
     * @returns  cbguard.models.Guard
     */
    public Guard function removeDefinition( required string name ) {
        structDelete( variables.guards, arguments.name );
        return this;
    }


    /**
     * Returns true if the logged in user is allowed for any of the permissions.
     *
     * @permissions     A single string permission, list of string permissions,
     *                  or array of string permissions to check.
     * @additionalArgs  A struct of any additional arguments to pass to the guard.
     *
     * @returns         boolean
     */
    public boolean function allows( required any permissions, struct additionalArgs = {} ) {
        var context = preflight();

        for ( var permission in arrayWrap( arguments.permissions ) ) {
            if ( resolvePermission( permission, context, arguments.additionalArgs ) ) {
                return true;
            }
        }

        return false;
    }

    /**
     * Returns true if the logged in user is not allowed for at least one of the permissions.
     *
     * @permissions     A single string permission, list of string permissions,
     *                  or array of string permissions to check.
     * @additionalArgs  A struct of any additional arguments to pass to the guard.
     *
     * @returns         boolean
     */
    public boolean function denies( required any permissions, struct additionalArgs = {} ) {
        var context = preflight();

        for ( var permission in arrayWrap( arguments.permissions ) ) {
            if ( !resolvePermission( permission, context, arguments.additionalArgs ) ) {
                return true;
            }
        }

        return false;
    }

    /**
     * Returns true if the logged in user is allowed for all of the permissions.
     *
     * @permissions     A single string permission, list of string permissions,
     *                  or array of string permissions to check.
     * @additionalArgs  A struct of any additional arguments to pass to the guard.
     *
     * @returns         boolean
     */
    public boolean function all( required any permissions, struct additionalArgs = {} ) {
        var context = preflight();

        for ( var permission in arrayWrap( arguments.permissions ) ) {
            if ( !resolvePermission( permission, context, arguments.additionalArgs ) ) {
                return false;
            }
        }

        return true;
    }

    /**
     * Returns true if the logged in user is denied for all of the permissions.
     *
     * @permissions     A single string permission, list of string permissions,
     *                  or array of string permissions to check.
     * @additionalArgs  A struct of any additional arguments to pass to the guard.
     *
     * @returns         boolean
     */
    public boolean function none( required any permissions, struct additionalArgs = {} ) {
        var context = preflight();

        for ( var permission in arrayWrap( arguments.permissions ) ) {
            if ( resolvePermission( permission, context, arguments.additionalArgs ) ) {
                return false;
            }
        }

        return true;
    }

    /**
     * Throws an exception if the logged in user is not allowed for any of the permissions.
     *
     * @permissions     A single string permission, list of string permissions,
     *                  or array of string permissions to check.
     * @additionalArgs  A struct of any additional arguments to pass to the guard.
     * @errorMessage    The error message to throw with the exception.
     *                  It can be either:
     *                      1. A string error message
     *                      2. A closure or UDF that will produce a string error
     *                         message.  This callback receives the following arguments:
     *                             a. The `permissions` tried.
     *                             b. The logged in `user`.
     *                             c. The `additionalArgs` passed.
     *
     * @throws          NotAuthorized
     *
     * @returns         cbguard.models.Guard
     */
    public Guard function authorize( required any permissions, struct additionalArgs = {}, any errorMessage ) {
        var context = preflight();

        arguments.permissions = arrayWrap( arguments.permissions );
        var passed = false;
        for ( var permission in arguments.permissions ) {
            if ( resolvePermission( permission, context, arguments.additionalArgs ) ) {
                passed = true;
                break;
            }
        }

        if ( !passed ) {
            param arguments.errorMessage = "The logged in user is not authorized to access this resource";

            if ( isClosure( arguments.errorMessage ) || isCustomFunction( arguments.errorMessage ) ) {
                arguments.errorMessage = arguments.errorMessage(
                    permissions = arguments.permissions,
                    user = context.user,
                    additionalArgs = arguments.additionalArgs
                );
            }

            throw( type = "NotAuthorized", message = arguments.errorMessage );
        }

        return this;
    }

    /**
     * Handles getting the current cbguard context for this guard.
     * Returns a struct with the current `RequestContext` (`event`), the current
     * settings for the request (`props`), and the currently logged in user (`user`).
     *
     * @throws   NotLoggedIn
     *
     * @returns  { "event", "props", "user" }
     */
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

        if ( !invoke( props.authenticationService, props.methodNames[ "isLoggedIn" ] ) ) {
            throw( type = "NotLoggedIn", message = "No user is logged in to authorize." )
        }

        return {
            "event": event,
            "props": props,
            "user": invoke( props.authenticationService, props.methodNames[ "getUser" ] )
        };
    }

    /**
     * Resolves the permission check.  It first checks and tries any custom guards.
     * If no custom guards exist, it checks the current user's `hasPermission` method.
     *
     * @permission      The permission being checked.
     * @context         The guard context, including `event`, `props`, and `user`.
     * @additionalArgs  A struct of any additional arguments to pass to the guard.
     *
     * @return          boolean
     */
    private boolean function resolvePermission(
        required string permission,
        required struct context,
        struct additionalArgs = {}
    ) {
        if ( variables.guards.keyExists( arguments.permission ) ) {
            return invoke(
                variables.guards[ arguments.permission ],
                "authorize",
                { "user": arguments.context.user, "additionalArgs": arguments.additionalArgs }
            );
        }

        return invoke(
            arguments.context.user,
            arguments.context.props.methodNames[ "hasPermission" ],
            { "permission": arguments.permission, "additionalArgs": arguments.additionalArgs }
        );
    }

    /**
     * Ensures that the returned value is an array.
     * Returns a passed array unmodified. Calls `listToArray` on all other values.
     *
     * @doc_generic  any
     * @return       [any]
     */
    private array function arrayWrap( required any items ) {
        return isArray( arguments.items ) ? items : items.listToArray();
    }

}
