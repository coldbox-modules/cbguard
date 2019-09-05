component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    property name="authenticationService" inject="AuthenticationService";

    function beforeAll() {
        super.beforeAll();
        getWireBox().autowire( this );
    }

    function run() {
        describe( "Authorization Specs", function() {
            beforeEach( function() {
                authenticationService.logout();
            } );

            it( "redirects the user if the component has a secured annotation with a list of permissions and the user is not logged in", function() {
                var event = execute( event = "myModule:PermissionSecured.fooPermissionAction" );
                expect( event.getValue( "relocate_EVENT", "" ) ).toBe( "myModule:Main.onAuthenticationFailure" );
            } );

            it( "redirects the user if the component has a secured annotation with a list of permissions and the user does not have any permissions", function() {
                authenticationService.login( createUser( { permissions = [] } ) );
                var event = execute( event = "myModule:PermissionSecured.fooPermissionAction" );
                expect( event.getValue( "relocate_EVENT", "" ) ).toBe( "myModule:Main.onAuthorizationFailure" );
            } );

            it( "redirects the user if the component has a secured annotation with a list of permissions and the user does not have any of the required permissions", function() {
                authenticationService.login( createUser( { permissions = [ "bar" ] } ) );
                var event = execute( event = "myModule:PermissionSecured.fooPermissionAction" );
                expect( event.getValue( "relocate_EVENT", "" ) ).toBe( "myModule:Main.onAuthorizationFailure" );
            } );

            it( "does not redirect the user if the component has a secured annotation with a list of permissions and the user has at least one of the required permissions", function() {
                authenticationService.login( createUser( { permissions = [ "foo" ] } ) );
                var event = execute( event = "myModule:PermissionSecured.fooPermissionAction" );
                expect( event.valueExists( "relocate_EVENT" ) ).toBeFalse();
                expect( event.getValue( "event", "" ) ).toBe( "myModule:PermissionSecured.fooPermissionAction" );
            } );

            it( "redirects the user if the action has a secured annotation with a list of permissions and the user is not logged in", function() {
                var event = execute( event = "myModule:PermissionActionSecured.fooPermissionAction" );
                expect( event.getValue( "relocate_EVENT", "" ) ).toBe( "myModule:Main.onAuthenticationFailure" );
            } );

            it( "redirects the user if the action has a secured annotation with a list of permissions and the user does not have any permissions", function() {
                authenticationService.login( createUser( { permissions = [] } ) );
                var event = execute( event = "myModule:PermissionActionSecured.fooPermissionAction" );
                expect( event.getValue( "relocate_EVENT", "" ) ).toBe( "myModule:Main.onAuthorizationFailure" );
            } );

            it( "redirects the user if the action has a secured annotation with a list of permissions and the user does not have any of the required permissions", function() {
                authenticationService.login( createUser( { permissions = [ "bar" ] } ) );
                var event = execute( event = "myModule:PermissionActionSecured.fooPermissionAction" );
                expect( event.getValue( "relocate_EVENT", "" ) ).toBe( "myModule:Main.onAuthorizationFailure" );
            } );

            it( "does not redirect the user if the action has a secured annotation with a list of permissions and the user has at least one of the required permissions", function() {
                authenticationService.login( createUser( { permissions = [ "foo" ] } ) );
                var event = execute( event = "myModule:PermissionActionSecured.fooPermissionAction" );
                expect( event.valueExists( "relocate_EVENT" ) ).toBeFalse();
                expect( event.getValue( "event", "" ) ).toBe( "myModule:PermissionActionSecured.fooPermissionAction" );
            } );

            it( "redirects the user if the component has a secured annotatoin with a list of permissions and the user has at least one of the required permissions but the action also has a secured annotation with a list of permissions and the user does not have any of the required permissions", function() {
                authenticationService.login( createUser( { permissions = [ "one" ] } ) );
                var event = execute( event = "myModule:DoubleSecured.securedAction" );
                expect( event.getValue( "relocate_EVENT", "" ) ).toBe( "myModule:Main.onAuthorizationFailure" );
            } );

            it( "does not redirect the user if the component has a secured annotatoin with a list of permissions and the user has at least one of the required permissions and the action also has a secured annotation with a list of permissions and the user has at least one of the required permissions", function() {
                authenticationService.login( createUser( { permissions = [ "one", "two" ] } ) );
                var event = execute( event = "myModule:DoubleSecured.securedAction" );
                expect( event.valueExists( "relocate_EVENT" ) ).toBeFalse();
                expect( event.getValue( "event", "" ) ).toBe( "myModule:DoubleSecured.securedAction" );
            } );
        } );
    }

    private function createUser( overrides = {} ) {
        var props = {
            id = 1,
            email = "johndoe@example.com",
            username = "johndoe",
            permissions = []
        };
        structAppend( props, overrides, true );
        return tap( getInstance( "User" ), function( user ) {
            user.setId( props.id );
            user.setEmail( props.email );
            user.setUsername( props.username );
            user.setPermissions( props.permissions );
        } );
    }

    private function tap( variable, callback ) {
        callback( variable );
        return variable;
    }

}
