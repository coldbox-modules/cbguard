component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "local handler overrides", function() {
            it( "looks for a local onAuthenticationFailure method on the handler for authentication failure events first", function() {
                var event = execute( event = "LocalOverrides.index" );
                expect( event.getValue( "event", "" ) ).toBe( "LocalOverrides.onAuthenticationFailure" );
            } );

            it( "looks for a local onAuthorizationFailure method on the handler for authentication failure events first", function() {
                authenticationService.login( createUser( { permissions = [] } ) );
                var event = execute( event = "LocalOverrides.secret" );
                expect( event.getValue( "relocate_event", "" ) ).toBe( "LocalOverrides.onAuthorizationFailure" );
            } );
        } );
  }

}
