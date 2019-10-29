component extends="coldbox.system.testing.BaseTestCase" {

    property name="authenticationService" inject="AuthenticationService";

    function beforeAll() {
        super.beforeAll();

        getController().getModuleService()
            .registerAndActivateModule( "cbguard", "testingModuleRoot" );

        getWireBox().autowire( this );
    }

    /**
     * @beforeEach
     */
    function setupIntegrationTest() {
        setup();
    }

    /**
     * @beforeEach
     */
    function autoLogOut() {
        authenticationService.logout();
    }

    function withSwappedSettings( applyOverrides, callback ) {
        var newSettings = duplicate( getController().getConfigSettings().modules.cbguard.settings );
        applyOverrides( newSettings );
        var interceptor = getController().getInterceptorService().getInterceptor( "SecuredEventInterceptor" );
        interceptor.setProperties( newSettings );
        try {
            callback();
        } catch ( any e ) {
            rethrow;
        } finally {
            interceptor.setProperties( getController().getConfigSettings().modules.cbguard.settings );
        }
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
