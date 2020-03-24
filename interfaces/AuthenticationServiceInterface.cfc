interface {

    /**
     * Must return an object that conforms to the `HasPermissions` interface.
     * (This may be an implicit implements.)
     */
    public HasPermissionInterface function getUser();

    /**
     * Returns true if the user is logged in.
     */
    public boolean function isLoggedIn();

}
