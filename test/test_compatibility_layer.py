from utils import run_local, run_prefix
import os


def test_prefix():
    """Test whether we can use the given Gentoo Prefix environment by running a simple echo command."""
    assert run_prefix('echo hello').output == 'hello'


def test_emerge(eessi_compat_layer_path):
    """Test the emerge command."""
    assert run_prefix('emerge --version').exit_code == 0
    assert run_prefix('which emerge').output.startswith(eessi_compat_layer_path)


def test_equery(eessi_compat_layer_path):
    """Test the equery command."""
    assert run_prefix('equery --version').exit_code == 0
    assert run_prefix('which equery').output.startswith(eessi_compat_layer_path)


def test_whoami():
    """Test whether the local username can be correctly resolved inside Gentoo Prefix."""
    assert run_prefix('whoami').output == run_local('whoami').output


def test_archspec(eessi_compat_layer_path):
    """Test the archspec installation/command."""
    assert run_prefix('which archspec').output.startswith(eessi_compat_layer_path)
    assert run_prefix('archspec cpu').exit_code == 0


def test_lmod(eessi_compat_layer_path, eessi_version):
    """Test the Lmod installation by running a 'module avail'."""
    if eessi_version.startswith('2020'):
        module_avail = run_prefix(f'source {eessi_compat_layer_path}/usr/lmod/lmod/init/profile && module avail')
    else:
        module_avail = run_prefix(f'source {eessi_compat_layer_path}/usr/share/Lmod/init/profile && module avail')
    assert module_avail.exit_code == 0
    assert 'Use "module spider" to find all possible modules and extensions.' in module_avail.output


def test_eessi_set_available(eessi_arch, eessi_os, eessi_version):
    """Test whether a EESSI set is available for the given architecture, operating system, and version."""
    my_eessi_set = f'eessi-{eessi_version}-{eessi_os}-{eessi_arch}'
    assert my_eessi_set in run_prefix('emerge --list-sets').output


def test_eessi_set_installation(eessi_compat_layer_path, eessi_arch, eessi_os, eessi_version):
    """Test whether all packages of the corresponding EESSI set have been installed."""
    set_packages = []
    set_filename = f'eessi-{eessi_version}-{eessi_os}-{eessi_arch}'
    set_path = os.path.join(eessi_compat_layer_path, 'etc', 'portage', 'sets', set_filename)
    with open(set_path, 'r') as setfile:
        packages = setfile.read().strip().split('\n')
        if package != ['']:
            set_packages = [package[1:] if package.startwith('=') else package for package in packages]

    installed_packages = run_prefix('qlist -IRv').output

    for set_package in set_packages:
        # TODO: though very unlikely, this could in theory give a false positive if the set has 
        # an unversioned package name that is a substring of some other installed package.
        assert set_package in installed_packages


def test_utf8_locale():
    """Test whether the default locale en_US.utf8 is available."""
    assert 'en_US.utf8' in run_prefix('locale -a').output


def test_host_symlinks(eessi_compat_layer_path):
    """Test whether all required symlinks to the host have been (correctly) created."""
    symlinks_to_host = [
        'etc/group',
        'etc/passwd',
        #'etc/hosts',
        'etc/nsswitch.conf',
        'etc/resolv.conf',
        'lib64/libnss_centrifydc.so.2',
        'lib64/libnss_ldap.so.2',
        'lib64/libnss_sss.so.2',
    ]

    for symlink in symlinks_to_host:
        assert os.path.islink(os.path.join(eessi_compat_layer_path, symlink))
        assert os.readlink(os.path.join(eessi_compat_layer_path, symlink)) == os.path.join('/', symlink)
