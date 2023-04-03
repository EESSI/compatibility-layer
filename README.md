# Compatibility layer

## Introduction

The compatibility layer of the EESSI project uses [Gentoo Prefix](https://wiki.gentoo.org/wiki/Project:Prefix)
to provide a known base on top of the host. This is the foundation we use to build our software stack on.
An alternative would be the [NixOS](https://nixos.org/).

## Installation and Configuration

The installation of the compatibility layer is implemented with an Ansible playbook and Ansible role,
which you can find in the `ansible` subdirectory. It will do the Gentoo Prefix bootstrap (which usually takes several hours to complete!),
add a lot of EESSI configurations and customizations, install a bunch of packages that we require for EESSI, and finally it will
run a ReFrame test suite to check the installation.

To make the installation even easier, we provide a script `install_compatibility_layer.sh` that can be used on basically any host that has Apptainer installed,
without requiring special privileges.
The script will execute the Ansible playbook inside an Apptainer build container, ensuring that all dependencies (including Ansible itself) are available.
In order to be able to write to `/cvmfs`, the container will bind mount a directory from the host as `/cvmfs` inside the container.

# License

The software in this repository is distributed under the terms of the
[GNU General Public License v2.0](https://opensource.org/licenses/GPL-2.0).

See [LICENSE](https://github.com/EESSI/compatibility-layer/blob/main/LICENSE) for more information.

SPDX-License-Identifier: GPL-2.0-only
