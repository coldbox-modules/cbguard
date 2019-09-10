component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "module settings", function() {
            it( "registers the interceptor automatically by default", function() {
                getController().getModuleService()
                    .registerAndActivateModule( "cbguard", "testingModuleRoot" );
                expect( function() {
                    getController().getInterceptorService().getInterceptor( "SecuredEventInterceptor" );
                } ).notToThrow();
            } );

            it( "can prevent the interceptor from being added automatically", function() {
                getController().getInterceptorService().unregister( "SecuredEventInterceptor" );
                getController().getConfigSettings().moduleSettings.cbguard.autoRegisterInterceptor = false;
                getController().getModuleService()
                    .registerAndActivateModule( "cbguard", "testingModuleRoot" );
                expect( function() {
                    getController().getInterceptorService().getInterceptor( "SecuredEventInterceptor" );
                } ).toThrow( "Injector.InstanceNotFoundException" );
            } );
        } );
  }

}
