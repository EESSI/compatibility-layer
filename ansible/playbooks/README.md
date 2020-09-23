![Ansible Lint](https://github.com/EESSI/compatibility-layer/workflows/Ansible%20Lint/badge.svg)
![Install compatibility layer](https://github.com/EESSI/compatibility-layer/workflows/Install%20compatibility%20layer/badge.svg)

# Ansible role/playbooks for installing the compatibility layer

This directory contains an Ansible role (`compatibility-layer`) in the subdirectory `roles` which has
all functionality for installing the compatibility layer into an existing Gentoo Prefix installation.
It adds a given overlay to the installation and installs a list of package sets and list of additional packages.
The playbook `install.yml` will execute this role on a given server. 

## Configuration

Before running the playbook, make sure the following settings are correct, and override them if necessary:

### Overlay settings
| Variable | Description | Default value |
| --- | --- | --- |
| custom_overlay_name | Repository name for the custom overlay | eessi |
| custom_overlay_source | Source of the custom overlay | git |
| custom_overlay_url | URL to the custom overlay | https://github.com/EESSI/gentoo-overlay.git |

### CVMFS settings
| Variable | Description | Default value |
| --- | --- | --- |
| cvmfs_start_transaction | Whether a CVMFS transaction should be start at the start | False |
| cvmfs_publish_transaction | Whether a CVMFS transaction should be published at the end | False |
| cvmfs_abort_transaction_on_failures | Whether a CVMFS transaction should be aborted on failures | False |
| cvmfs_repository | Name of your CVMFS repository (used for the transaction) | pilot.eessi-hpc.org |

### Prefix and packages
| Variable | Description | Default value |
| --- | --- | --- |
| gentoo_prefix_path | Path to the root of your Gentoo Prefix installation | /cvmfs/pilot.eessi-hpc.org/compat/x86_64 |
| package_sets | List of package sets to be installed | 2020 |
| prefix_packages | List of additional packages to be installed | - |

## Running the playbook 

The playbook can be run using:
```
ansible-playbook -i hosts -K install.yml
```
The `-K` option will ask for your sudo password, and you have to supply a valid hosts file (here named `hosts`).
By default, the playbook will only run on the host listed in the `cvmfsstratum0servers` section of the supplied `hosts` file. So, your `hosts` file should at least have:
```
[cvmfsstratum0servers]
ip-or-hostname-of-your-stratum0
```
