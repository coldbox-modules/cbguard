component {

    function authorize( required user, struct additionalArgs = {} ) {
        return arguments.user.getId() == 2;
    }

}
