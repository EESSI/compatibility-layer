# Compatibility layer

The compatibility layer of the EESSI project uses [Gentoo Prefix](https://wiki.gentoo.org/wiki/Project:Prefix)

## Installation of Gentoo Prefix

- Build a Singularity container with the provided definition file:
```
sudo singularity build singularity-prefix.simg singularity-prefix.def
```

- Run the bootstrap script inside the container:
```
singularity exec ./singularity-prefix.simg ./bootstrap-prefix.sh
```

- Answer the simple questions, e.g. about the installation path, and wait 
for a couple of hours for the script to complete.

## Bootstrap script
The included Prefix bootstrap script, `bootstrap-prefix.sh`, has been taken from:
https://gitweb.gentoo.org/repo/proj/prefix.git/tree/scripts/bootstrap-prefix.sh?id=050a9859dd4629a46385a24a85ecc2d195bcaf86

The following modifications have been made to this script:
- removed the minus on line 1528 to solve a circular dependency issue.

