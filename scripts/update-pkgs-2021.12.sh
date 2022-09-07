#!/bin/bash

set -e

if [ -z "$EPREFIX" ]; then
    # this assumes we're running in a Gentoo Prefix environment
    EPREFIX=$(dirname $(dirname $SHELL))
fi

# first update checkout of gentoo repository to sufficiently recent commit
# this is required because we pin to a specific commit when bootstrapping the compat layer
# see gentoo_git_commit in ansible/playbooks/roles/compatibility_layer/defaults/main.yml
cd $EPREFIX/var/db/repos/gentoo
git fetch origin
git checkout d7c647404a632309810851c52c1d350cafc26949  # 2022-08-25
cd -

# unmask GCC 9.4, since we're using that as system compiler in EESSI pilot 2021.12;
# see also $EPREFIX/var/db/repos/gentoo/profiles/package.mask
echo '=sys-devel/gcc-9.4.0' >> ${EPREFIX}/etc/portage/package.unmask

# stick to Python 3.9
# see also https://wiki.gentoo.org/wiki/Project:Python/PYTHON_TARGETS
# note: make sure that ${EPREFIX}/etc/python-exec/python-exec.conf has the right version of Python in it too
echo '# replace profile default Python with Python 3.9' >> ${EPREFIX}/etc/portage/package.use
echo '*/* PYTHON_TARGETS: -* python3_9' >> ${EPREFIX}/etc/portage/package.use
echo '*/* PYTHON_SINGLE_TARGET: -python3_10 python3_9' >> ${EPREFIX}/etc/portage/package.use

emerge --sync

# update lxml due to https://glsa.gentoo.org/glsa/202208-06
# requires commit b93e546746f6b60c5efe97ad6d98636547c3b797 (2022-07-02)
emerge --update --oneshot --verbose '=dev-python/lxml-4.9.1'

# update vim + vim-core due to https://glsa.gentoo.org/glsa/202208-32
# requires commit d9ecb3a289029dde9bd9452f8007df2a51d5128d (2022-07-29) for vim
# requires commit 2e633d404c39d32f7f0e3c4815bd0849fdbb2f08 (2022-07-29) for vim-core
emerge --update --oneshot --verbose '=app-editors/vim-9.0.0099' '=app-editors/vim-core-9.0.0099'

# update libarchive due to https://glsa.gentoo.org/glsa/202208-26
# requires commit c1c88aacbc6763b92e58fee14b7dbe5d8b84aa73 (2022-08-04)
emerge --update --oneshot --verbose '=app-arch/libarchive-3.6.1'

# (2021.06) update glibc due to https://glsa.gentoo.org/glsa/202208-24
# emerge --oneshot --verbose '=sys-libs/glibc-2.34-r14'
