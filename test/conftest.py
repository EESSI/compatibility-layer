import os
import pytest


def pytest_addoption(parser):
    """Add EESSI-specific command-line arguments."""
    group = parser.getgroup('eessi', 'EESSI settings')
    group.addoption(
        '--eessi-basedir', action='store', default='/cvmfs/pilot.eessi-hpc.org', help='path to the root/base directory of the EESSI repository'
    )
    group.addoption(
        '--eessi-version', action='store', default='latest', help='EESSI repository version'
    )
    group.addoption(
        '--eessi-arch', action='store', choices=['aarch64', 'ppc64le', 'x86_64'], default=os.uname().machine, help='EESSI architecture'
    )
    group.addoption(
        '--eessi-os', action='store', choices=['linux', 'macos'], default=os.uname().sysname.lower(), help='EESSI operating system'
    )
    group.addoption(
        '--eessi-compat-layer-dir', action='store', default=None, help='path to an EESSI compatibility layer directory'
    )


# Fixtures

@pytest.fixture()
def eessi_basedir(request):
    basedir = request.config.getoption('--eessi-basedir')
    if not os.path.exists(basedir):
        pytest.exit('the given base dir does not exist!')
    return request.config.getoption('--eessi-basedir')


@pytest.fixture()
def eessi_version(request, eessi_basedir):
    version = request.config.getoption('--eessi-version')
    if not os.path.exists(os.path.join(eessi_basedir, version)):
        pytest.exit('the given version dir does not exist in the base dir')
    if version == 'latest':
        # Use the 'latest' symlink in the repository to find the corresponding version
        version = os.readlink(os.path.join(eessi_basedir, 'latest'))
    return version


@pytest.fixture()
def eessi_os(request):
    return request.config.getoption('--eessi-os')


@pytest.fixture()
def eessi_arch(request):
    return request.config.getoption('--eessi-arch')


@pytest.fixture()
def eessi_compat_layer_path(request, eessi_basedir, eessi_version, eessi_os, eessi_arch):
    default_path = os.path.join(
        eessi_basedir, eessi_version, 'compat', eessi_os, eessi_arch
    )
    compat_layer_path = request.config.getoption('--eessi-compat-layer-dir') or default_path
    if not os.path.exists(compat_layer_path):
        pytest.exit('the given EESSI compatibility layer directory does not exist')
    return compat_layer_path


@pytest.fixture(autouse=True)
def eessi_startprefix(request, eessi_compat_layer_path):
    startprefix_path = os.path.join(eessi_compat_layer_path, 'startprefix')
    if not os.path.exists(startprefix_path):
        pytest.exit(f'the startprefix script cannot be found at {startprefix_path}')
    pytest.startprefix = startprefix_path
    return startprefix_path
