![Ansible Lint](https://github.com/EESSI/compatibility-layer/workflows/Ansible%20Lint/badge.svg)
![Install compatibility layer](https://github.com/EESSI/compatibility-layer/workflows/Install%20compatibility%20layer/badge.svg)

# Ansible role/playbooks for installing the compatibility layer

This directory contains an Ansible role (`compatibility_layer`) in the subdirectory `roles` which has
all functionality for installing the EESSI compatibility layer. It performs the following tasks:

 - install Gentoo Prefix, if this has not been done yet;
 - make symlinks to some host paths in order to fix issues with, for instance, user accounts and groups;
 - add a given overlay to the installation;
 - use the Portage configuration files from that overlay, if applicable, by making symlinks to them;
 - install a given list of package sets;
 - install a given list of additional packages.
 
The playbook `install.yml` will execute this role on a given server. 

## Configuration

Before running the playbook, make sure the following settings are correct, and override them if necessary. For the default values, see the [defaults file](roles/compatibility_layer/defaults/main.yml).

### Overlay settings

| Variable | Description |
| --- | --- |
| custom_overlays | List of dictionaries of custom overlays that will be added. The dictionaries should have keys `name`, `source` and `url`, and optionally `eclass-override`. |

### CVMFS settings
| Variable | Description |
| --- | --- |
| cvmfs_start_transaction | Whether a CVMFS transaction should be start at the start |
| cvmfs_publish_transaction | Whether a CVMFS transaction should be published at the end |
| cvmfs_abort_transaction_on_failures | Whether a CVMFS transaction should be aborted on failures |
| cvmfs_repository | Name of your CVMFS repository (used for the transaction) |

### Prefix and packages
| Variable | Description |
| --- | --- |
| eessi_version | Compatibility layer version, which will, by default, be included in the `gentoo_prefix_path` and be used to install the right `package_sets` |
| gentoo_prefix_path | Path to the root of your Gentoo Prefix installation |
| gentoo_git_repo | URL to the git repository of the (official) Gentoo ebuild repository |
| gentoo_git_commit | Git commit hash of the Gentoo ebuild repository to be used for the bootstrap |
| prefix_required_space | Minimal amount of disk space that is required for the Gentoo Prefix bootstrap |
| prefix_default_gcc | GCC compiler version to use as default compiler in Gentoo Prefix installation |
| prefix_user_defined_trusted_dirs | List of paths to the user defined trusted dirs for glibc |
| prefix_mask_packages | Contents of a [package.mask file](https://wiki.gentoo.org/wiki//etc/portage/package.mask) that should be used during the bootstrap |
| prefix_bootstrap_use_flags | Contents of [package.use file](https://wiki.gentoo.org/wiki//etc/portage/package.use) to put in place after bootstrap stage 3 |
| prefix_use_builtin_bootstrap | Use the container's built-in bootstrap script? |
| prefix_custom_bootstrap_script | Dictionary with the `local` source and `remote` destination of the bootstrap script |
| prefix_singularity_command | Singularity command for launching the container with the bootstrap script |
| prefix_source | Singularity container path used for the Prefix installtion |
| prefix_source_options | Arguments to be passed to the Prefix bootstrap script |
| prefix_install | Prefix installation command |
| prefix_locales | List of locales to be generated |
| package_sets | List of package sets to be installed |
| prefix_packages | List of additional packages to be installed |
| symlinks_to_host | List of paths that should get a symlink to the corresponding host path |

### Logging
| Variable | Description |
| --- | --- |
| eessi_log_dir | Directory for storing the log files |
| prefix_build_log | Path to the Prefix installation log file |
| emerge_log | Path to the Emerge log file |

## Running the playbook 

The playbook can be run using:
```
ansible-playbook -i hosts -b install.yml
```
The `-b` option will assume you can become root without a sudo password; if you do need to provide a password, also include `-K`. Furthermore, you have to supply a valid hosts file (here named `hosts`).
By default, the playbook will only run on the host listed in the `cvmfsstratum0servers` section of the supplied `hosts` file. So, your `hosts` file should at least have:
```
[cvmfsstratum0servers]
ip-or-hostname-of-your-stratum0 eessi_host_arch=x86_64 eessi_host_os=linux
```

The `eessi_host_arch` corresponds to the architecture of the machine that executes the playbook and for which this compatibility layer has to be built, e.g. `x86_64`, `aarch64`, or `ppc64le`.
Similarly, `eessi_host_os` should refer to the operating system of the machine, and should be set to either `linux` or `macos`.

Note that, by default, the bootstrap script from the root directory of this git repository will be used, unless you set `prefix_use_builtin_bootstrap` to `yes` 
(in which case the bootstrap script included in the Prefix build container will be used).
A different bootstrap script can be used by changing `prefix_custom_bootstrap_script.local` to a local path.
