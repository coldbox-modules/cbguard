component {

    this.title        = "myModule";
    this.description  = "myModule";
    this.version      = "1.0.0";
    this.cfmapping    = "myModule";
    this.dependencies = [];

    function configure() {
        settings = {
            "cbguard" = {
                "authenticationService" = "SecurityService@myModule",
                "authenticationOverrideEvent" = "myModule:Main.onAuthenticationFailure",
                "authenticationAjaxOverrideEvent" = "myModule:api.v1.BaseAPIHandler.onAuthenticationFailure",
                "authorizationOverrideEvent" = "myModule:Main.onAuthorizationFailure",
                "authorizationAjaxOverrideEvent" = "myModule:api.v1.BaseAPIHandler.onAuthorizationFailure"
            }
        };

        routes = [
            { pattern = "/:handler/:action?" }
        ];
    }

}
