component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    property name="interceptorService" inject="coldbox:interceptorService";

    function run() {
        describe( "API Redirect Specs", function() {
            it( "redirects the user to the normal authentication failure event if no API authentication event is set", function() {
                var securedEventInterceptor = interceptorService.getInterceptor( "SecuredEventInterceptor" );
                var authenticationFailureRedirect = securedEventInterceptor.getProperty( "authenticationOverrideEvent" );
                prepareMock( getRequestContext() )
                    .$( "getHTTPHeader" )
                    .$args( "X-Requested-With", "" )
                    .$results( "XMLHttpRequest" );
                var event = execute( event = "Secured.index" );
                expect( event.getValue( "event", "" ) ).toBe( authenticationFailureRedirect );
            } );

            it( "redirects the user to the api authentication failure event if one is set", function() {
                var securedEventInterceptor = interceptorService.getInterceptor( "SecuredEventInterceptor" );
                securedEventInterceptor.setProperty(
                    "authenticationAjaxOverrideEvent",
                    "BaseAPIHandler.onAuthenticationFailure"
                );
                prepareMock( getRequestContext() )
                    .$( "getHTTPHeader" )
                    .$args( "X-Requested-With", "" )
                    .$results( "XMLHttpRequest" );
                var event = execute( event = "Secured.index" );
                expect( event.getValue( "event", "" ) ).toBe( "BaseAPIHandler.onAuthenticationFailure" );
            } );

            it( "redirects the user to the normal authorization failure event if no API authorization event is set", function() {
                var securedEventInterceptor = interceptorService.getInterceptor( "SecuredEventInterceptor" );
                var authorizationFailureRedirect = securedEventInterceptor.getProperty( "authorizationOverrideEvent" );
                prepareMock( getRequestContext() )
                    .$( "getHTTPHeader" )
                    .$args( "X-Requested-With", "" )
                    .$results( "XMLHttpRequest" );
                authenticationService.login( createUser() );
                var event = execute( event = "PermissionSecured.fooPermissionAction" );
                expect( event.getValue( "event", "" ) ).toBe( authorizationFailureRedirect );
            } );

            it( "redirects the user to the api authorization failure event if one is set", function() {
                var securedEventInterceptor = interceptorService.getInterceptor( "SecuredEventInterceptor" );
                securedEventInterceptor.setProperty(
                    "authorizationAjaxOverrideEvent",
                    "BaseAPIHandler.onAuthorizationFailure"
                );
                prepareMock( getRequestContext() )
                    .$( "getHTTPHeader" )
                    .$args( "X-Requested-With", "" )
                    .$results( "XMLHttpRequest" );
                authenticationService.login( createUser() );
                var event = execute( event = "PermissionSecured.fooPermissionAction" );
                expect( event.getValue( "event", "" ) ).toBe( "BaseAPIHandler.onAuthorizationFailure" );
            } );
        } );
    }

    private function createUser( overrides = {} ) {
        var props = {
            id: 1,
            email: "johndoe@example.com",
            username: "johndoe",
            permissions: []
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
