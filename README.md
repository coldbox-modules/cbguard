# cbguard

[![Master Branch Build Status](https://img.shields.io/travis/coldbox-modules/cbguard/master.svg?style=flat-square&label=master)](https://travis-ci.org/coldbox-modules/cbguard)

## Annotation driven guards for authentication and authorization in ColdBox

### Usage

`cbguard` lets us lock down methods to logged in users and users with specific permissions using one annotation — `secured`.  Just sticking the secured annotation on a handler or action is enough to require a user to log in before executing those events.

Here's an example of how to lock down an entire handler:

```cfc
component secured {

    function index( event, rc, prc ) {
        // ...
    }

    function show( event, rc, prc ) {
        // ...
    }

}
```

You can be more specific and lock down only specific actions using the same annotation:

```cfc
component {

    function create( event, rc, prc ) secured {
        // ...
    }

}
```

You can further lock down handlers and actions to a list of specific permissions.  If specified, the logged in user must have one of the permissions in the list specified.

```cfc
component secured="admin" {

    function index( event, rc, prc ) {
        // ...
    }

    function show( event, rc, prc ) {
        // ...
    }

}
```

In the above component, the user must have the `admin` permission to access the actions in this handler.

```cfc
component {

    function show( event, rc, prc ) secured="admin,reviews_posts" {
        // ...
    }

}
```

Individual actions can be secured in the same way.  Above, the `show` action requires the logged in user to have either the `admin` or the `reviews_posts` permission.

These two approaches can be combined and both handler and actions can be secured together:

```cfc
component secured {

    function index( event, rc, prc ) {
        // ...
    }

    function new( event, rc, prc ) secured="create_posts" {
        // ...
    }

}
```

While the user needs to be logged in to interact at all with this handler, they also need the `create_posts` permission to interact with the `new` action.

### Service approach

`cbguard` also allows you to check for authorization at any point in the request lifecycle using the `Guard@cbguard` component.

```cfc
component secured {

    property name="guard" inject="@cbguard";

    function update( event, rc, prc ) {
        var post = getInstance( "Post" ).findOrFail( rc.post );

        // this will throw a `NotAuthorized` exception if the user cannot update the post
        guard.authorize( "update-post", { "post": post } );

        // update the post as normal...
    }

}
```

The methods available to you on the `Guard` component are as follows:

```
public boolean function allows( required any permissions, struct additionalArgs = {} );
public boolean function denies( required any permissions, struct additionalArgs = {} );
public boolean function all( required any permissions, struct additionalArgs = {} );
public boolean function none( required any permissions, struct additionalArgs = {} );
public void function authorize( required any permissions, struct additionalArgs = {}, string errorMessage );
```

In all cases `permissions` can be either a string, a list of strings, or an array of strings.

In the case of `authorize` the `errorMessage` replaces the thrown error message
in the `NotAuthorized`. exception.  It can also be a closure that takes the following shape:

```
string function errorMessage( string failedPermission, any user, struct additionalArgs );
```

### Redirects

When a user is denied access to a action, an event of your choosing is executed instead.  There are four keys that can be set in the `moduleSettings` struct that all come with good defaults.

1. `authenticationOverrideEvent` (Default: `Main.onAuthenticationFailure`)

This is the event that is executed when the user is not logged in and is attempting to execute a secured action, whether or not that handler or action has permissions.

2. `authorizationOverrideEvent` (Default: same as `authenticationOverrideEvent`)

This is the event that is executed when the user is logged in and is attempting to execute a secured action but does not have the requisite permissions.

3. `authenticationAjaxOverrideEvent` (Default: `Main.onAuthenticationFailure`)

This is the event that is executed when the user is not logged in and is attempting to execute a secured action via ajax (`event.isAjax()`), whether or not that handler or action has permissions.  By default, this will execute the same action that is configured for `authenticationOverrideEvent`.

4. `authorizationAjaxOverrideEvent` (Default: same as `authorizationOverrideEvent`)

This is the event that is executed when the user is logged in and is attempting to execute a secured action via ajax (`event.isAjax()`) but does not have the requisite permissions. By default, this will execute the same action that is configured for `authorizationOverrideEvent`.


### Setup

`cbguard` requires a bit of setup to function properly.

First, there are two interfaces that must be followed:

1. AuthenticationServiceInterface

```cfc
interface {

    /**
    * Must return an object that conforms to `HasPermissionInterface`.
    * (This may be an implicit implements.)
    */
    public HasPermissionInterface function getUser();

    /**
    * Returns true if the user is logged in.
    */
    public boolean function isLoggedIn();

}

```

2. HasPermissionInterface

```cfc
interface {

    /**
    * Returns true if the user has the specified permission.
    * Any additional arguments may be passed in as the second argument.
    * This allows you to check if a user can access a specific resource,
    * rather than just a generic check.
    */
    public boolean function hasPermission( required string permission, struct additionalArgs );

}
```

> **Note**: These interfaces are not enforced at compile time to give you maximum flexibility.

To configure the AuthenticationService, set the value of `authenticationService` in your `moduleSettings` to a WireBox mapping:

```
moduleSettings = {
    cbguard = {
        authenticationService = "SecurityService@myapp"
    }
};
```

The default `authenticationService` for `cbguard` is `AuthenticationService@cbauth`.  `cbauth` follows the `AuthenticationServiceInterface` out of the box.


### config/ColdBox.cfc Settings

You can change the method names called on the `AuthenticationService` and the returned `User` if you need to.  We highly discourage this use case, as it makes it harder to utilize the `cbguard` conventions across projects.  However, should the need arise, you can modify the method names as follows:

```cfc
moduleSettings = {
    cbguard = {
        methodNames = {
            isLoggedIn    = "getIsLoggedIn",
            getUser       = "retrieveUser",
            hasPermission = "checkPermission"
        }
    }
};
```

Additionally, you can modify the override action for each of the event types:

```cfc
moduleSettings = {
    cbguard = {
        overrideActions = {
            authenticationOverrideEvent = "relocate",
            authenticationAjaxOverrideEvent = "override",
            authorizationOverrideEvent = "relocate",
            authorizationAjaxOverrideEvent = "override"
        }
    }
};
```

`relocate` refers to calling `relocate` on the controller. The user will be redirected to the new page.
`override` refers to `event.overrideEvent`. This will not redirect but simply change the running event.


### Module Overrides

All of the `cbguard` settings can be overriden inside a module.  This allows modules, such as an API module, to provide
their own authentication services as well as redirect events.

To specify some overrides, create a `cbguard` struct in your desired module's `settings` in that module's `ModuleConfig.cfc`.

```cfc
component {

    this.name = "myModule";

    function configure() {
        settings = {
            "cbguard" = {
                "authenticationOverrideEvent" = "myModule:Main.onAuthenticationFailure",
                "authorizationOverrideEvent" = "myModule:Main.onAuthorizationFailure"
            }
        };
    }

}
```

### Local Handler Overrides

If an `onAuthenticationFailure` or `onAuthorizationFailure` method exists on the handler being
secured, it will be used in the case of an authentication or authorization failure event,
respectively.

```
// handlers/Admin.cfc
component secured {

    function index( event, rc, prc ) {
        event.setView( "admin/index" );
    }

    function secret( event, rc, prc ) secured="superadmin" {
        event.setView( "admin/secret" );
    }

    function onAuthenticationFailure( event, rc, prc ) {
        relocate( "/login" );
    }

    function onAuthenticationFailure( event, rc, prc ) {
        flash.put( "authorizationError", "You don't have the correct permissions to access that resource." );
        redirectBack(); // from the redirectBack module
    }

}
```

### Override Order
cbguard will process your authorization and authentication failures in the following order:
1. Inline handler methods (`onAuthenticationFailure` & `onAuthorizationFailure` within your handlers).
2. cbguard settings in the ModuleConfig of the handler's module. (Overrides in `modules_app/api/ModuleConfig.cfc` when the handler is in the module, i.e. `modules_app/api/handlers/Main.cfc`.)
3. Overrides in `config/ColdBox.cfc` using `moduleSettings`.
4. Default settings for the module.

## `autoRegisterInterceptor`

If you need more control over the order of your interceptors you can
disable the automatic loading of the `SecuredEventInterceptor` interceptor.
If you do this you will need to register it yourself
(most likely in `config/ColdBox.cfc`) as `cbguard.interceptors.SecuredEventInterceptor`.
