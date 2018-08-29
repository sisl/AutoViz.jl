using Pkg
packages = keys(Pkg.installed())
if !in("Vec", packages)
    Pkg.add(PackageSpec(url="https://github.com/sisl/Vec.jl.git"))
end
if !in("AutomotiveDrivingModels", packages)
    Pkg.add(PackageSpec(url="https://github.com/sisl/AutomotiveDrivingModels.jl.git"))
end