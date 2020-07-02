# Compatibility layer

## Introduction

The compatibility layer of the EESSI project uses [Gentoo Prefix](https://wiki.gentoo.org/wiki/Project:Prefix)
to provide a known base on top of the host. This is the foundation we use to build our software stack on.
An alternative would be the [NixOS](https://nixos.org/).

## Installation and Configuration

### Prerequisites

The bootstrap process will need a clean environment with a compiler (the system version of gcc will do). It also is very sensitive to 
the environment, so setup a user with unset CFFLAGS, CFLAGS, LDFLAGS, PKG_CONFIG_PATH and the always harmful LD_LIBRARY_PATH variables.
EESSI provides a singularity container for this.

## Installation and Configuration

### Bootstrapping Gentoo Prefix
Gentoo Prefix provides a bootstrap script to build the prefix. See [Gentoo Prefix Bootstrap](https://wiki.gentoo.org/wiki/Project:Prefix/Bootstrap)
or build and use the singularity container. After starting the bootstrap have a long coffee...

### Adding EESSI overlay
Additional packages are added in the EESSI overlay, which is based on ComputeCanada.
To add the overlay: 

Start the prefix
```
startprefix
```
Configure the overlay
```
mkdir $(EPREFIX)/etc/portage/repos.conf
emerge eselect-repository
eselect repository add eessi git https://github.com/EESSI/gentoo-overlay.git
```
Sync the overlay
```
emerge --sync
```


