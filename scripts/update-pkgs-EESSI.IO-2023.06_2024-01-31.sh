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

# update checkout of eessi overlay to sufficiently recent commit to include fix from https://github.com/EESSI/gentoo-overlay/pull/98
# https://github.com/EESSI/gentoo-overlay/commit/bf189508bf7510d8acf8ef089d4c7f03f6c512d1 (2024-01-29)
eessi_commit='bf189508bf7510d8acf8ef089d4c7f03f6c512d1'
echo "Updating $EPREFIX/var/db/repos/eessi to recent commit (${eessi_commit})..."
cd $EPREFIX/var/db/repos/eessi
time git fetch origin
echo "Checking out ${eessi_commit} in ${PWD}..."
time git checkout ${eessi_commit}
cd -

# update checkout of gentoo repository to sufficiently recent commit
# this is required because we pin to a specific commit when bootstrapping the compat layer
# see gentoo_git_commit in ansible/playbooks/roles/compatibility_layer/defaults/main.yml;
# https://gitweb.gentoo.org/repo/gentoo.git/commit/?id=d9718dafa6ecd841f4364f2ee0039613f0b8efec (2023-10-30)
gentoo_commit='d9718dafa6ecd841f4364f2ee0039613f0b8efec'
echo "Updating $EPREFIX/var/db/repos/gentoo to recent commit (${gentoo_commit})..."
cd $EPREFIX/var/db/repos/gentoo
time git fetch origin
echo "Checking out ${gentoo_commit} in ${PWD}..."
time git checkout ${gentoo_commit}
cd -

# update zlib due to https://security.gentoo.org/glsa/202401-18
# this has to be done before switching to an even newer commit of the gentoo repository,
# as that doesn't have this zlib version anymore, while the current commit does
emerge --update --oneshot --verbose '=sys-libs/zlib-1.2.13-r2'  # was sys-libs/zlib-1.2.13-r1

# update checkout of gentoo repository to an even more recent commit,
# which contains the required versions of openssl and glibc
# https://gitweb.gentoo.org/repo/gentoo.git/commit/?id=ac78a6d2a0ec2546a59ed98e00499ddd8343b13d (2024-01-31)
gentoo_commit='ac78a6d2a0ec2546a59ed98e00499ddd8343b13d'
echo "Updating $EPREFIX/var/db/repos/gentoo to recent commit (${gentoo_commit})..."
cd $EPREFIX/var/db/repos/gentoo
time git fetch origin
echo "Checking out ${gentoo_commit} in ${PWD}..."
time git checkout ${gentoo_commit}
cd -

# unmask dev-libs/openssl-1.1.1w, so we can update to it
# (masked by $EPREFIX/var/db/repos/gentoo/profiles/package.mask, because OpenSSL 1.1.x is EOL)
echo '# unmask dev-libs/openssl-1.1.1w (openssl 1.1.x is masked via $EPREFIX/var/db/repos/gentoo/profiles/package.mask)' >> ${EPREFIX}/etc/portage/package.unmask
echo '=dev-libs/openssl-1.1.1w' >> ${EPREFIX}/etc/portage/package.unmask
# update openssl due to https://nvd.nist.gov/vuln/detail/CVE-2023-4807
emerge --update --oneshot --verbose '=dev-libs/openssl-1.1.1w'  # was dev-libs/openssl-1.1.1u

# update glibc due to https://security.gentoo.org/glsa/202402-01
emerge --update --oneshot --verbose '=sys-libs/glibc-2.37-r10'  # was sys-libs/glibc-2.37-r7

# collect list of installed packages after updating packages
list_installed_pkgs_post_update=${mytmpdir}/installed-pkgs-post-update.txt
echo "Collecting list of installed packages to ${list_installed_pkgs_post_update}..."
qlist -IRv | sort | tee ${list_installed_pkgs_post_update}

echo
echo "diff in installed packages:"
diff -u ${list_installed_pkgs_pre_update} ${list_installed_pkgs_post_update}

rm -rf ${mytmpdir}
