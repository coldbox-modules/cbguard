interface {

    /**
    * Returns true if the user has the specified permission.
    * Any additional arguments may be passed in as the second argument.
    * This allows you to check if a user can access a specific resource,
    * rather than just a generic check.
    */
    public boolean function hasPermission( required string permission, struct additionalArgs );

}
