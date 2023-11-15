#!/usr/bin/env bash

set -e

mytmpdir=$(mktemp -d)

if [ -z "$EPREFIX" ]; then
    # this assumes we're running in a Gentoo Prefix environment
    EPREFIX=$(dirname $(dirname $SHELL))
fi
echo "EPREFIX=${EPREFIX}"

# collect list of installed packages before updating packages
list_installed_pkgs_pre_update=${mytmpdir}/installed-pkgs-pre-update.txt
echo "Collecting list of installed packages to ${list_installed_pkgs_pre_update}..."
qlist -IRv | sort | tee ${list_installed_pkgs_pre_update}

# update checkout of gentoo repository to sufficiently recent commit
# this is required because we pin to a specific commit when bootstrapping the compat layer
# see gentoo_git_commit in ansible/playbooks/roles/compatibility_layer/defaults/main.yml;

# https://gitweb.gentoo.org/repo/gentoo.git/commit/?id=092c2383f221620534eb948f7f81596d6b8d4a86 (2023-11-15)
gentoo_commit='092c2383f221620534eb948f7f81596d6b8d4a86'
echo "Updating $EPREFIX/var/db/repos/gentoo to recent commit (${gentoo_commit})..."
cd $EPREFIX/var/db/repos/gentoo
time git fetch origin
echo "Checking out ${gentoo_commit} in ${PWD}..."
time git checkout ${gentoo_commit}
cd -

# update libarchive due to https://glsa.gentoo.org/glsa/202309-14
emerge --update --oneshot --verbose '=app-arch/libarchive-3.7.1'  # was app-arch/libarchive-3.6.2-r1

# update glibc due to https://glsa.gentoo.org/glsa/202310-03
emerge --update --oneshot --verbose '=sys-libs/glibc-2.37-r7'  # was sys-libs/glibc-2.37-r3

# update curl due to https://glsa.gentoo.org/glsa/202310-12
emerge --update --oneshot --verbose '=net-misc/curl-8.3.0-r2'  # was net-misc/curl-8.1.2

# collect list of installed packages after updating packages
list_installed_pkgs_post_update=${mytmpdir}/installed-pkgs-post-update.txt
echo "Collecting list of installed packages to ${list_installed_pkgs_post_update}..."
qlist -IRv | sort | tee ${list_installed_pkgs_post_update}

echo
echo "diff in installed packages:"
diff -u ${list_installed_pkgs_pre_update} ${list_installed_pkgs_post_update}

rm -rf ${mytmpdir}
