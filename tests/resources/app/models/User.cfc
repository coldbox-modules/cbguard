component accessors="true" {

    property name="id";
    property name="email";
    property name="username";
    property name="permissions";

    function init() {
        setPermissions( [] );
        return this;
    }

    public boolean function hasPermission( required string permission, struct additionalArgs = {} ) {
        if ( arguments.permission == "access-post" ) {
            return arguments.additionalArgs.post.getId() == getId();
        }
        return arrayContains( getPermissions(), permission );
    }

}
