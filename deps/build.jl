using BinDeps
import Compat.Sys

import Compat: Sys

if VERSION >= v"0.7-"
    import Libdl
end

@BinDeps.setup

function validate_clp(name,handle)
    try
        p = Libdl.dlsym(handle, :Clp_VersionMajor)
        return p != C_NULL
    catch
        return false
    end
end

function validate_cbc(name,handle)
    try
        # Pre 2.8.12 doesn't have this defined
        p = Libdl.dlsym(handle, :Cbc_setInitialSolution)
        return p != C_NULL
    catch
        return false
    end
end

if Sys.isunix()
    libclp = library_dependency("libclp",aliases=["libClp"], validate=validate_clp)
    libcbcsolver = library_dependency("libcbcsolver",aliases=["libCbcSolver"], validate=validate_cbc)
end
if Sys.iswindows()
    using WinRPM
    libclp = library_dependency("libclp",aliases=["libClp-1"], validate=validate_clp)
    libcbcsolver = library_dependency("libcbcsolver",aliases=["libCbcSolver-3"], validate=validate_cbc)
    provides(WinRPM.RPM, "Cbc", [libclp,libcbcsolver], os = :Windows)
end

cbcname = "Cbc-2.9.8"

provides(Sources, URI("http://www.coin-or.org/download/source/Cbc/$cbcname.tgz"),
    [libclp,libcbcsolver], os = :Unix)

if Sys.isapple()
    using Homebrew
    if Homebrew.installed("coinmp") # coinmp package is old and conflicts with cbc package
        Homebrew.rm("coinmp")
    end
    provides( Homebrew.HB, "cbc", [libclp, libcbcsolver], os = :Darwin )
end

prefix=joinpath(BinDeps.depsdir(libclp),"usr")
patchdir=BinDeps.depsdir(libclp)
srcdir = joinpath(BinDeps.depsdir(libclp),"src",cbcname)

provides(SimpleBuild,
    (@build_steps begin
        if length(BinDeps._find_library(libclp)) == 0 || length(BinDeps._find_library(libcbcsolver)) == 0
            GetSources(libclp)
            @build_steps begin
                ChangeDirectory(srcdir)
                `./configure --prefix=$prefix --without-blas --without-lapack --enable-cbc-parallel`
                `make install`
            end
        end
    end),[libclp,libcbcsolver], os = :Unix)

@BinDeps.install Dict(:libclp => :libclp, :libcbcsolver => :libcbcsolver)
