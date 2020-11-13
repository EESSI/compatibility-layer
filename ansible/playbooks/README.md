![Ansible Lint](https://github.com/EESSI/compatibility-layer/workflows/Ansible%20Lint/badge.svg)
![Install compatibility layer](https://github.com/EESSI/compatibility-layer/workflows/Install%20compatibility%20layer/badge.svg)

# Ansible role/playbooks for installing the compatibility layer

This directory contains an Ansible role (`compatibility_layer`) in the subdirectory `roles` which has
all functionality for installing the compatibility layer into an existing Gentoo Prefix installation.
It performs the following tasks:

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
| custom_overlay_name | Repository name for the custom overlay |
| custom_overlay_source | Source of the custom overlay |
| custom_overlay_url | URL to the custom overlay |

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
| gentoo_prefix_path | Path to the root of your Gentoo Prefix installation |
|prefix_locales|List of locales to be generated|
| package_sets | List of package sets to be installed |
| prefix_packages | List of additional packages to be installed |
| python_targets | String consisting of [Gentoo Python targets](https://wiki.gentoo.org/wiki/Project:Python/PYTHON_TARGETS) |
| symlinks_to_host | List of paths that should get a symlink to the corresponding host path |

## Running the playbook 

The playbook can be run using:
```
ansible-playbook -i hosts -b install.yml
```
The `-b` option will assume you can become root without a sudo password; if you do need to provide a password, also include `-K`. Furthermore, you have to supply a valid hosts file (here named `hosts`).
By default, the playbook will only run on the host listed in the `cvmfsstratum0servers` section of the supplied `hosts` file. So, your `hosts` file should at least have:
```
[cvmfsstratum0servers]
ip-or-hostname-of-your-stratum0 eessi_host_arch=x86_64
```

The eessi_host_arch corresponds to the architecture of the machine that executes the playbook and for which this compatibility layer has to be built, e.g. `x86_64`, `aarch64`, or `ppc64le`.