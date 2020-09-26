# Compatibility layer

## Introduction

The compatibility layer of the EESSI project uses [Gentoo Prefix](https://wiki.gentoo.org/wiki/Project:Prefix)
to provide a known base on top of the host. This is the foundation we use to build our software stack on.
An alternative would be the [NixOS](https://nixos.org/).

## Installation and Configuration

### Prerequisites

The bootstrap process will need a clean environment with C and C++ compilers (the system version of gcc and g++ will do) as well as the `make` command. It also is very sensitive to 
the environment, so setup a user with unset `CFFLAGS`, `CFLAGS`, `LDFLAGS`, `PKG_CONFIG_PATH` and the always harmful `LD_LIBRARY_PATH` variables.

EESSI provides a Singularity container for this.

### Building the Singularity container
The provided Singularity definition file can be used to build a container with a clean environment:
```
sudo singularity build bootstrap-prefix.sif singularity-bootstrap-prefix.def
```

### Bootstrapping Gentoo Prefix
Gentoo Prefix provides a bootstrap script to build the prefix, see [Gentoo Prefix Bootstrap](https://wiki.gentoo.org/wiki/Project:Prefix/Bootstrap).
We forked [this version](https://gitweb.gentoo.org/repo/proj/prefix.git/tree/scripts/bootstrap-prefix.sh?id=e77fd01734f21ec2e9c985c28ba4eb30c1b2bc9d)
and made some modifications. See issue [#8](https://github.com/EESSI/compatibility-layer/issues/8) for more details. 

You can run our version of the bootstrap script (see `bootstrap-prefix.sh`) inside the Singularity container by executing:
```
singularity run bootstrap-prefix.sif
```
or simply:
```
./bootstrap-prefix.sif
```

If you want to run your own version of the bootstrap script, use:
```
singularity exec bootstrap-prefix.sif ./bootstrap-prefix.sh
```
Our version of the script allows you to pick a custom snapshot for the Portage tree. This can be done by setting `SNAPSHOT_URL` to
a URL that points to a directory, and setting `CUSTOM_SNAPSHOT` to the name of a snapshot file (must be a bzip2 archive). For instance:
```
env SNAPSHOT_URL="http://cvmfs-s0.eessi-hpc.org/snapshots" CUSTOM_SNAPSHOT="portage-20200909.tar.bz2" ./bootstrap-prefix.sif
```
If you want to limit the supported/installed Python version(s), you can set the environment variable `PYTHON_TARGETS` before starting the bootstrap script. By only including a Python 3 version, you can prevent Python 2 from being installed, e.g.:
```
env PYTHON_TARGETS="python3_7" SNAPSHOT_URL="http://cvmfs-s0.eessi-hpc.org/snapshots" CUSTOM_SNAPSHOT="portage-20200909.tar.bz2" ./bootstrap-prefix.sif
```

After starting the bootstrap have a long coffee...

Once the bootstrap is completed, run the script to replace some paths with symlinks into the host OS:

```
scripts/prefix-symlink-host-paths.sh
```

### Adding the EESSI overlay and packages
Additional packages are added in the EESSI overlay, which is based on ComputeCanada.
You can add them manually or in an automated way by using Ansible, being Ansible the preferred way. Below you can find the two options explained.

#### Ansible playbook (Option 1)
The installation of the EESSI-specific parts can be automatically executed by running the Ansible playbook `install.yml` inside the folder `ansible/playbooks`. 
This playbook will install the [EESSI Gentoo overlay](https://github.com/EESSI/gentoo-overlay) and a set of packages, including `Lmod` and `archspec`. See the `README` in the `ansible/playbooks` folder for more details.

#### Manually (Option 2)
First, set `EPREFIX` to the path containing your Gentoo Prefix installation, and start the prefix:
```
export EPREFIX=/path/to/your/prefix
${EPREFIX}/startprefix
```
Ensure that the configuration directory for repositories exists:
```
mkdir ${EPREFIX}/etc/portage/repos.conf
```
If you used `${PYTHON_TARGETS}` during the bootstrap, be sure to set it to the same value now, e.g.:
```
export PYTHON_TARGETS="python3_7"
```

Next, configure and sync the overlay:
```
emerge eselect-repository
eselect repository add eessi git https://github.com/EESSI/gentoo-overlay.git
emerge --sync eessi
```

After synchronizing the overlay, add the EESSI package set(s) that you would like to install, e.g. for set `2020.08`:
```
mkdir ${EPREFIX}/etc/portage/sets/
ln -s  ${EPREFIX}/var/db/repos/eessi/etc/portage/sets/2020.08 ${EPREFIX}/etc/portage/sets/
```

Finally, install the package set(s) defined at `${EPREFIX}/etc/portage/sets/`, e.g.:
```
emerge @2020.08
```

### Updating the Prefix
#### Packages
Updating packages can be as easy as
```
emerge --sync
emerge
```
If you run into problems, usually a newer ebuild is not suited to build in a prefix environment.
Try to mask latest versions:

Create a mask file if not existing and mask newer versions from thin provisioning tools greater or equal to 0.7.6:
```
echo ">=sys-block/thin-provisioning-tools-0.7.6" >> ${EPREFIX}/etc/portage/package.mask
```

#### Portage
Updating Portage requires the kernel source which corresponds to your running kernel on the host. Emerge will detect it in `/usr/src/linux`.

Check your running kernel version with:
```
cat /proc/version
Linux version 4.20.0-1.el7.elrepo.x86_64 (mockbuild@Build64R7) 
```

On a Centos 7 host kernel sources are installed in `/usr/src/kernels`. Link `/usr/src/linux` to the appropiate kernel source after installation. Example for an `elrepo` kernel:
```
rpm -ivh kernel-ml-devel-4.20.0-1.el7.elrepo.x86_64.rpm
cd /usr/src ; ln -s kernels/4.20.0-1.el7.elrepo.x86_64 linux
```

 When ready update Portage from the Prefix environment:
```
startprefix
emerge --oneshot sys-apps/portage
```
