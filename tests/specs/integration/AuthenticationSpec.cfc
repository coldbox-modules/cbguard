component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    property name="authenticationService" inject="AuthenticationService";

    function beforeAll() {
        super.beforeAll();
        getWireBox().autowire( this );
    }

    function run() {
        describe( "Authentication Specs", function() {
            beforeEach( function() {
                authenticationService.logout();
            } );

            it( "does nothing to events where neither the component or method is annotated secure", function() {
                var event = execute( event = "NotSecured.index" );
                expect( event.getValue( "event", "" ) ).toBe( "NotSecured.index" );
            } );

            it( "redirects the user if the component has a secured annotation and the user is not logged in", function() {
                var event = execute( event = "Secured.index" );
                expect( event.getValue( "relocate_EVENT", "" ) ).toBe( "Main.onAuthenticationFailure" );
            } );

            it( "overrides the event if the component has a secured annotation and the user is not logged in with specific settings", function() {
                withSwappedSettings(
                    function( settings ) {
                        settings.overrideActions.authenticationOverrideEvent = "override";
                    },
                    function() {
                        var event = execute( event = "Secured.index" );
                        expect( event.getValue( "event", "" ) ).toBe( "Main.onAuthenticationFailure" );
                    }
                );
            } );

            it( "does not redirect the user if the component has a secured annotation and the user is logged in", function() {
                authenticationService.login( createUser() );
                var event = execute( event = "Secured.index" );
                expect( event.getValue( "event", "" ) ).toBe( "Secured.index" );
            } );

            it( "redirects the user if the action has a secured annotation and the user is not logged in", function() {
                var event = execute( event = "PartiallySecured.secured" );
                expect( event.getValue( "relocate_EVENT", "" ) ).toBe( "Main.onAuthenticationFailure" );
            } );

            it( "overrides the event if the action has a secured annotation and the user is not logged in with specific settings", function() {
                withSwappedSettings(
                    function( settings ) {
                        settings.overrideActions.authenticationOverrideEvent = "override";
                    },
                    function() {
                        var event = execute( event = "PartiallySecured.secured" );
                        expect( event.getValue( "event", "" ) ).toBe( "Main.onAuthenticationFailure" );
                    }
                );
            } );

            it( "does not redirect the user if the action has a secured annotation and the user is logged in", function() {
                authenticationService.login( createUser() );
                var event = execute( event = "PartiallySecured.secured" );
                expect( event.getValue( "event", "" ) ).toBe( "PartiallySecured.secured" );
            } );

            it( "does nothing if the event is for an has no handler", function() {
                var event = execute( event = "without.handlers" );
                expect( event.getValue( "event", "" ) ).toBe( "without.handlers" );
            } );

            it( "does nothing for options requests", function() {
                prepareMock( getRequestContext() ).$( "getHTTPMethod", "OPTIONS" );
                var event = execute( event = "Secured.index" );
                expect( event.getValue( "event", "" ) ).toBe( "Secured.index" );
                expect( event.valueExists( "relocate_EVENT" ) ).toBeFalse( "Event should not be relocated on an OPTIONS request" );
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
