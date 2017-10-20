# cbguard

[![Master Branch Build Status](https://img.shields.io/travis/elpete/cbguard/master.svg?style=flat-square&label=master)](https://travis-ci.org/elpete/cbguard)

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

Individual actions can be secured in the same way.  Above, the `show` action requires the logged in user yo have either the `admin` or the `reviews_posts` permission.

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


### Redirects

When a user is denied access to a action, an event of your choosing is executed instead.  There are four keys that can be set in the `moduleSettings` struct that all come with good defaults.

1. `authenticationOverrideEvent` (Default: `Main.onAuthenticationFailure`)

This is the event that is executed when the user is not logged in and is attempting to execute a secured action, whether or not that handler or action has permissions.

1. `authorizationOverrideEvent` (Default: same as `authenticationOverrideEvent`)

This is the event that is executed when the user is not logged in and is attempting to execute a secured action via ajax (`event.isAjax()`), whether or not that handler or action has permissions.  By default, this will execute the same action that is configured for `authenticationOverrideEvent`.

1. `authenticationAjaxOverrideEvent` (Default: `Main.onAuthenticationFailure`)

This is the event that is executed when the user is logged in and is attempting to execute a secured action but does not have the requisite permissions.

1. `authenticationAjaxOverrideEvent` (Default: `Main.onAuthenticationFailure`)

This is the event that is executed when the user is logged in and is attempting to execute a secured action via ajax (`event.isAjax()`) but does not have the requisite permissions. By default, this will execute the same action that is configured for `authorizationOverrideEvent`.


### Setup

`cbguard` requires a bit of setup to function properly.

First, there are two interfaces that must be followed:

1. AuthenticationServiceInterface

```cfc
interface {

    /**
    * Must return an object that conforms to `HasPermissionsInterface`.
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
    */
    public boolean function hasPermission( required string permission );

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


### Advanced Setup

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
