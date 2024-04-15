#!/usr/bin/env bash

set -e

mytmpdir=$(mktemp -d)

if [ -z "$EPREFIX" ]; then
    # this assumes we're running in a Gentoo Prefix environment
    EPREFIX=$(dirname $(dirname $SHELL))
fi
echo "EPREFIX=${EPREFIX}"

cd ${EPREFIX}/var/db/repos/eessi/

# collect list of installed packages before updating packages
list_installed_pkgs_pre_update=${mytmpdir}/installed-pkgs-pre-update.txt
echo "Collecting list of installed packages to ${list_installed_pkgs_pre_update}..."
qlist -IRv | sort | tee ${list_installed_pkgs_pre_update}

# update checkout of eessi overlay to sufficiently recent commit to include fix from https://github.com/EESSI/gentoo-overlay/pull/99
# TODO: add URL when the PR is merged
eessi_commit='d5355267ad6b52d90c65e0c41af726cc0e83afea'
echo "Updating $EPREFIX/var/db/repos/eessi to recent commit (${eessi_commit})..."
cd $EPREFIX/var/db/repos/eessi
time git fetch origin
echo "Checking out ${eessi_commit} in ${PWD}..."
time git checkout ${eessi_commit}
cd -

# reinstall the currently installed version of glibc to apply the changes from https://github.com/EESSI/gentoo-overlay/pull/99
emerge --verbose =$(qlist -IRv sys-libs/glibc)

# reinstall the packages that provide the who and last commands to make them pick up the modified glibc header files
# with locations to /var/log/[u,]wtmp
emerge --verbose =sys-apps/util-linux-2.38.1-r3 # we currently have r2, but that's not available anymore in the current gentoo commit
emerge --verbose =sys-apps/coreutils-9.3-r3 # we currently have r1, but that's not available anymore in the current gentoo commit

# add the USE flags for packages related to LDAP and SSSD, and install the corresponding packages
# see: https://github.com/EESSI/compatibility-layer/pull/199
cat << EOF >> ${EPREFIX}/etc/portage/package.use
# only build libraries and userspace tools
net-nds/openldap minimal
# only build libnss, don't build the daemon (use the one from the host)
sys-auth/nss-pam-ldapd -nslcd
# don't build the SSSD daemon (and man pages) either
sys-auth/sssd -daemon -man
EOF
emerge --verbose sys-auth/nss-pam-ldapd::eessi
emerge --verbose sys-auth/sssd::eessi

# remove the host symlinks that are no longer needed
# see: https://github.com/EESSI/compatibility-layer/pull/199
rm ${EPREFIX}/etc/nsswitch.conf
rm ${EPREFIX}/lib64/libnss_ldap.so.2
rm ${EPREFIX}/lib64/libnss_sss.so.2
rm ${EPREFIX}/var/run
# the following symlink is in our playbook, but it hadn't been added to the production repository yet
# rm ${EPREFIX}/var/log/wtmp

# collect list of installed packages after updating packages
list_installed_pkgs_post_update=${mytmpdir}/installed-pkgs-post-update.txt
echo "Collecting list of installed packages to ${list_installed_pkgs_post_update}..."
qlist -IRv | sort | tee ${list_installed_pkgs_post_update}

echo
echo "diff in installed packages:"
diff -u ${list_installed_pkgs_pre_update} ${list_installed_pkgs_post_update}

rm -rf ${mytmpdir}
