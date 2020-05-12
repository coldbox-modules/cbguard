component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    property name="interceptorService" inject="coldbox:interceptorService";
    property name="flash" inject="coldbox:flash";

    function run() {
        describe( "Secured Url Spec", function() {
            beforeEach( function() {
                flash.clear();
            } );

            it( "puts the _securedUrl in the flash scope when relocating", function() {
                var event = execute( event = "Secured.index" );
                expect( event.getValue( "relocate_EVENT", "" ) ).toBe( "Main.onAuthenticationFailure" );
                expect( flash.exists( "_securedUrl" ) ).toBeTrue( "_securedUrl should exist in the flash scope" );
                expect( flash.get( "_securedUrl" ) ).toBe( event.getFullUrl() );
            } );
        } );
    }

}
