component extends="coldbox.system.testing.BaseTestCase" {

    function beforeAll() {
        super.beforeAll();

        getController().getModuleService()
            .registerAndActivateModule( "cbguard", "testingModuleRoot" );
    }

    /**
    * @beforeEach
    */
    function setupIntegrationTest() {
        setup();
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

}
