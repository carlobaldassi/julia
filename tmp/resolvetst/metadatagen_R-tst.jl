require("../../base/pkg")

module MetadataGen

import Metadata.Version, Metadata.VersionSet
import Metadata.older

export generate, clean

function generate()
    cp("tst_pkgs.txt", "pkgs.txt")
    cp("tst_reqs.txt", "reqs.txt")
    cp("tst_vers.txt", "vers.txt")
    cp("tst_deps.txt", "deps.txt")
    return
end

function clean()
    rm("pkgs.txt")
    rm("vers.txt")
    rm("deps.txt")
    rm("reqs.txt")
    return
end

end # module
