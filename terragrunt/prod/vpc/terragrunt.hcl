include "envcommon" {
    path = "${dirname(find_in_parent_folders("root.hcl"))}/_envcommon/vpc.hcl"
    expose = true
}

terraform {
    source = "${include.envcommon.locals.source_url}//?ref=v6.6.0"
}