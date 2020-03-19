component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    property name="authenticationService" inject="AuthenticationService";

    function run() {
        describe( "Guard Specs", function() {
            beforeEach( function() {
                variables.authenticationService.logout();
            } );

            it( "throws an exception if the user is not logged in", function() {
                expect( function() {
                    execute( event = "GuardSpecHandler.notLoggedIn" );
                } ).toThrow( type = "NotLoggedIn" );
            } );

            it( "returns true if a user is allowed for a permission", function() {
                variables.authenticationService.login( createUser( { permissions = [ "do-something" ] } ) );
                var event = execute( event = "GuardSpecHandler.authorizedSinglePermission" );
                expect( event.getPrivateValue( "isAllowed" ) ).toBeTrue();
            } );

            it( "returns false if a user is not allowed for a permission", function() {
                variables.authenticationService.login( createUser( { permissions = [] } ) );
                var event = execute( event = "GuardSpecHandler.notAuthorizedSinglePermission" );
                expect( event.getPrivateValue( "isAllowed" ) ).toBeFalse();
            } );

            it( "returns true if a user is allowed for any of the permissions", function() {
                variables.authenticationService.login( createUser( { permissions = [ "do-something", "do-something-else" ] } ) );
                var event = execute( event = "GuardSpecHandler.authorizedMultiplePermission" );
                expect( event.getPrivateValue( "isAllowed" ) ).toBeTrue();
            } );

            it( "returns true if a user is denied for a permission", function() {
                variables.authenticationService.login( createUser( { permissions = [] } ) );
                var event = execute( event = "GuardSpecHandler.deniedSinglePermission" );
                expect( event.getPrivateValue( "isDenied" ) ).toBeTrue();
            } );

            it( "returns false if a user is not denied for a permission", function() {
                variables.authenticationService.login( createUser( { permissions = [ "do-something" ] } ) );
                var event = execute( event = "GuardSpecHandler.notDeniedSinglePermission" );
                expect( event.getPrivateValue( "isDenied" ) ).toBeFalse();
            } );

            it( "returns true if a user is denied for any of the permissions", function() {
                variables.authenticationService.login( createUser( { permissions = [ "do-something" ] } ) );
                var event = execute( event = "GuardSpecHandler.deniedMultiplePermission" );
                expect( event.getPrivateValue( "isDenied" ) ).toBeTrue();
            } );

            it( "can check if the user is allowed for all the permissions", function() {
                variables.authenticationService.login( createUser( { permissions = [ "do-something", "do-something-else" ] } ) );
                var event = execute( event = "GuardSpecHandler.allowedAllPermissions" );
                expect( event.getPrivateValue( "isAllowed" ) ).toBeTrue();
            } );

            it( "can check if the user is not allowed for all the permissions", function() {
                variables.authenticationService.login( createUser( { permissions = [ "do-something" ] } ) );
                var event = execute( event = "GuardSpecHandler.notAllowedAllPermissions" );
                expect( event.getPrivateValue( "isAllowed" ) ).toBeFalse();
            } );

            it( "can check if the user is allowed for none of the permissions", function() {
                variables.authenticationService.login( createUser( { permissions = [] } ) );
                var event = execute( event = "GuardSpecHandler.deniedAllPermissions" );
                expect( event.getPrivateValue( "isDenied" ) ).toBeTrue();
            } );

            it( "can check if the user fails the none check", function() {
                variables.authenticationService.login( createUser( { permissions = [ "do-something" ] } ) );
                var event = execute( event = "GuardSpecHandler.notDeniedAllPermissions" );
                expect( event.getPrivateValue( "isDenied" ) ).toBeFalse();
            } );

            it( "throws an exception if a user is not authorized", function() {
                variables.authenticationService.login( createUser( { permissions = [] } ) );
                expect( function() {
                    var event = execute( event = "GuardSpecHandler.authorized" );
                } ).toThrow( type = "NotAuthorized" );
            } );

            it( "does not throw an exception if a user is authorized", function() {
                variables.authenticationService.login( createUser( { permissions = [ "do-something" ] } ) );
                expect( function() {
                    var event = execute( event = "GuardSpecHandler.authorized" );
                } ).notToThrow( type = "NotAuthorized" );
            } );

            it( "can pass additional arguments to guard methods", function() {
                variables.authenticationService.login( createUser( { id = 1, permissions = [] } ) );
                var event = execute( event = "GuardSpecHandler.accessPost" );
                expect( event.getPrivateValue( "isAllowed" ) ).toBeTrue();
            } );

            it( "can pass additional arguments to guard methods and fail", function() {
                variables.authenticationService.login( createUser( { id = 2, permissions = [] } ) );
                var event = execute( event = "GuardSpecHandler.accessPost" );
                expect( event.getPrivateValue( "isAllowed" ) ).toBeFalse();
            } );

            it( "can define a guard that will be fired instead of hasPermission if it exists", function() {
                var guard = getWireBox().getInstance( "Guard@cbguard" );
                guard.define( "access-post", function( user, additionalArgs ) {
                    return user.getId() == 2;
                } );

                try {
                    variables.authenticationService.login( createUser( { id = 2, permissions = [] } ) );
                    var event = execute( event = "GuardSpecHandler.accessPost" );
                    expect( event.getPrivateValue( "isAllowed" ) ).toBeTrue();
                } finally {
                    guard.removeDefinition( "access-post" );
                }
            } );

            it( "can define a guard that will be fired instead of hasPermission if it exists using a Wirebox mapping", function() {
                var guard = getWireBox().getInstance( "Guard@cbguard" );
                guard.define( "access-post", "CustomGuard" );

                try {
                    variables.authenticationService.login( createUser( { id = 2, permissions = [] } ) );
                    var event = execute( event = "GuardSpecHandler.accessPost" );
                    expect( event.getPrivateValue( "isAllowed" ) ).toBeTrue();
                } finally {
                    guard.removeDefinition( "access-post" );
                }
            } );
        } );
    }

}
