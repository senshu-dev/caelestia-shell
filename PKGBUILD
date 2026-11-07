# Custom fork of caelestia-shell with per-monitor notifications

# Maintainer: senshu

_pkgname='caelestia-shell'
pkgname="$_pkgname-custom"
pkgver=2.5.0.r187.g8c8a748f
pkgrel=1
pkgdesc='Custom fork of Caelestia shell with per-monitor notifications'
arch=('x86_64' 'aarch64')
url='https://github.com/senshu-dev/caelestia-shell'
license=('GPL-3.0-only')
depends=(
    'caelestia-cli'
    'caelestia-lib'
    'quickshell-git'
    'glibc'
    'gcc-libs'

    # Brightness
    'ddcutil'
    'brightnessctl'

    # Services
    'libcava'
    'networkmanager'
    'lm_sensors'
    'aubio'
    'libpipewire'
    'libqalculate'
    'power-profiles-daemon'

    # Fonts
    'ttf-material-symbols-variable'
    'ttf-rubik-vf'
    'ttf-cascadia-code-nerd'

    # Qt modules
    'qt6-base'
    'qt6-declarative'
    'qt6-imageformats'
    'qt6-multimedia'
    'qt6-m3shapes-git'

    # Extra functionality
    'swappy'
    'fish'
    'bash'
)
optdepends=(
    'asdbctl: controlling the brightness of Apple Studio Displays'
    'fprintd: fingerprint unlock for the lock screen'
    'howdy-next: face unlock for the lock screen'
)
makedepends=('cmake' 'ninja' 'qt6-shadertools')
provides=($_pkgname)
conflicts=($_pkgname "$_pkgname-git")

pkgver() {
    cd "$startdir"
    printf "%s" "$(git describe --long --tags | sed 's/^v//;s/-/.r/;s/-/./')"
}

build() {
    cd "$startdir"

    cmake -B build-pkg -G Ninja \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_INSTALL_SYSCONFDIR=/etc
    cmake --build build-pkg
}

package() {
    cd "$startdir"

    DESTDIR="$pkgdir" cmake --install build-pkg
    install -Dm644 LICENSE "$pkgdir"/usr/share/licenses/$_pkgname/LICENSE
}
