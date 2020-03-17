component {

    property name="guard" inject="Guard@cbguard";

    function preHandler( event, rc, prc ) {
        event.noRender();
    }

    function notLoggedIn( event, rc, prc ) {
        guard.allows( "do-something" );
    }

    function authorizedSinglePermission() {
        prc.isAllowed = guard.allows( "do-something" );
    }

    function notAuthorizedSinglePermission() {
        prc.isAllowed = guard.allows( "do-something" );
    }

    function deniedSinglePermission() {
        prc.isDenied = guard.denies( "do-something" );
    }

    function notDeniedSinglePermission() {
        prc.isDenied = guard.denies( "do-something" );
    }

    function authorizedMultiplePermission() {
        prc.isAllowed = guard.allows( [ "do-something", "do-something-else" ] );
    }

    function deniedMultiplePermission() {
        prc.isDenied = guard.denies( [ "do-something", "do-something-else" ] );
    }

    function allowedAllPermissions() {
        prc.isAllowed = guard.all( [ "do-something", "do-something-else" ] );
    }

    function notAllowedAllPermissions() {
        prc.isAllowed = guard.all( [ "do-something", "do-something-else" ] );
    }

    function deniedAllPermissions() {
        prc.isDenied = guard.none( [ "do-something", "do-something-else" ] );
    }

    function notDeniedAllPermissions() {
        prc.isDenied = guard.none( [ "do-something", "do-something-else" ] );
    }

    function authorized() {
        guard.authorize( "do-something" );
    }

    function accessPost() {
        var post = getInstance( "Post" ).setId( 1 );
        prc.isAllowed = guard.allows( "access-post", { "post": post } );
    }

}
