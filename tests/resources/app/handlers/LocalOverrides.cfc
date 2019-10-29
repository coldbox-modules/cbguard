component secured {

    function index( event, rc, prc ) {
        event.noRender();
    }

    function secret( event, rc, prc ) secured="superadmin" {
        event.noRender();
    }

    function onAuthenticationFailure( event, rc, prc ) {
        event.noRender();
    }

    function onAuthorizationFailure( event, rc, prc ) {
        event.noRender();
    }

}
