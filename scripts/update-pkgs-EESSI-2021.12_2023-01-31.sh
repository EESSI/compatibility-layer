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

# https://gitweb.gentoo.org/repo/gentoo.git/commit/?id=5507d83c30321cbb24626eb2f2c445368020d65e (2023-01-31)
gentoo_commit='5507d83c30321cbb24626eb2f2c445368020d65e'
echo "Updating $EPREFIX/var/db/repos/gentoo to recent commit (${gentoo_commit})..."
cd $EPREFIX/var/db/repos/gentoo
time git fetch origin
echo "Checking out ${gentoo_commit} in ${PWD}..."
time git checkout ${gentoo_commit}
cd -

# unmask glibc 2.34 so we can update to it (glibc <2.36 is masked via $EPREFIX/var/db/repos/gentoo/profiles/package.mask)
echo '# unmask glibc 2.34 (glibc < 2.36 is masked via $EPREFIX/var/db/repos/gentoo/profiles/package.mask)' >> ${EPREFIX}/etc/portage/package.unmask
echo '=sys-libs/glibc-2.34-r14' >> ${EPREFIX}/etc/portage/package.unmask
# update glibc due to https://glsa.gentoo.org/glsa/202208-24
emerge --update --oneshot --verbose '=sys-libs/glibc-2.34-r14'  # was sys-libs/glibc-2.33-r7

# update binutils due to https://glsa.gentoo.org/glsa/202208-30
emerge --update --oneshot --verbose '=sys-devel/binutils-2.38-r2'  # was sys-devel/binutils-2.37_p1-r1

# update openssl due to https://glsa.gentoo.org/glsa/202210-02
emerge --update --oneshot --verbose '=dev-libs/openssl-1.1.1q'  # was dev-libs/openssl-1.1.1l-r1

# update libxml2 due to https://glsa.gentoo.org/glsa/202210-03
emerge --update --oneshot --verbose '=dev-libs/libxml2-2.10.3-r1'  # was dev-libs/libxml2-2.9.12-r5

# update gzip due to https://glsa.gentoo.org/glsa/202209-01
emerge --update --oneshot --verbose '=app-arch/gzip-1.12-r4'  # was app-arch/gzip-1.11

# update libksba due to https://glsa.gentoo.org/glsa/202212-07 + https://glsa.gentoo.org/glsa/202210-23
emerge --update --oneshot --verbose '=dev-libs/libksba-1.6.3'  # was dev-libs/libksba-1.6.0

# update libgcrypt due to https://glsa.gentoo.org/glsa/202210-13
emerge --update --oneshot --verbose '=dev-libs/libgcrypt-1.9.4-r2'  # was dev-libs/libgcrypt-1.8.8

# update expat due to https://glsa.gentoo.org/glsa/202209-24 + https://glsa.gentoo.org/glsa/202210-38
emerge --update --oneshot --verbose '=dev-libs/expat-2.5.0'  # was dev-libs/expat-2.4.1

# update sqlite due to https://glsa.gentoo.org/glsa/202210-40
emerge --update --oneshot --verbose '=dev-db/sqlite-3.40.1'  # dev-db/sqlite-3.35.5

# update curl due to https://glsa.gentoo.org/glsa/202212-01
emerge --update --oneshot --verbose '=net-misc/curl-7.86.0-r3'  # was net-misc/curl-7.80.0

# update zlib due to https://glsa.gentoo.org/glsa/202210-42
emerge --update --oneshot --verbose '=sys-libs/zlib-1.2.13-r1'  # was sys-libs/zlib-1.2.11-r4

# collect list of installed packages after updating packages
list_installed_pkgs_post_update=${mytmpdir}/installed-pkgs-post-update.txt
echo "Collecting list of installed packages to ${list_installed_pkgs_post_update}..."
qlist -IRv | sort | tee ${list_installed_pkgs_post_update}

echo
echo "diff in installed packages:"
diff -u ${list_installed_pkgs_pre_update} ${list_installed_pkgs_post_update}

rm -rf ${mytmpdir}
