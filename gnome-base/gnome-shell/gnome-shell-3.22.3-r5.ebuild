# Distributed under the terms of the GNU General Public License v2

EAPI="6"
GNOME2_LA_PUNT="yes"
PYTHON_COMPAT=( python{3_4,3_5,3_6,3_7} )

inherit autotools gnome2 multilib pax-utils python-r1 systemd

DESCRIPTION="Provides core UI functions for the GNOME 3 desktop"
HOMEPAGE="https://wiki.gnome.org/Projects/GnomeShell"

LICENSE="GPL-2+ LGPL-2+"
SLOT="0"
KEYWORDS="*"

IUSE="+bluetooth browser-extension ck +deprecated-background elogind +ibus +networkmanager nsplugin systemd vanilla-gc vanilla-motd vanilla-screen xephyr"
REQUIRED_USE="${PYTHON_REQUIRED_USE}
	?? ( ck elogind systemd )
	xephyr? ( ck !elogind !systemd )
"

# libXfixes-5.0 needed for pointer barriers
# FIXME:
#  * gstreamer support is currently automagic
COMMON_DEPEND="
	>=app-accessibility/at-spi2-atk-2.5.3
	>=dev-libs/atk-2[introspection]
	>=app-crypt/gcr-3.7.5[introspection]
	>=dev-libs/glib-2.45.3:2[dbus]
	>=dev-libs/gjs-1.39
	>=dev-libs/gobject-introspection-1.49.1:=
	dev-libs/libical:=
	>=x11-libs/gtk+-3.15.0:3[introspection]
	>=dev-libs/libcroco-0.6.8:0.6
	>=gnome-base/gnome-desktop-3.7.90:3=[introspection]
	>=gnome-base/gsettings-desktop-schemas-3.21.3
	>=gnome-extra/evolution-data-server-3.17.2:=
	>=media-libs/gstreamer-0.11.92:1.0
	>=net-im/telepathy-logger-0.2.4[introspection]
	>=net-libs/telepathy-glib-0.19[introspection]
	>=sys-auth/polkit-0.100[introspection]
	>=x11-libs/libXfixes-5.0
	x11-libs/libXtst
	>=x11-wm/mutter-3.20.0[deprecated-background=,introspection]
	>=x11-libs/startup-notification-0.11

	${PYTHON_DEPS}
	dev-python/pygobject:3[${PYTHON_USEDEP}]

	dev-libs/dbus-glib
	dev-libs/libxml2:2
	media-libs/libcanberra[gtk3]
	media-libs/mesa
	>=media-sound/pulseaudio-2
	>=net-libs/libsoup-2.40:2.4[introspection]
	x11-libs/libX11
	x11-libs/gdk-pixbuf:2[introspection]

	x11-apps/mesa-progs

	bluetooth? ( >=net-wireless/gnome-bluetooth-3.9[introspection] )
	networkmanager? (
		app-crypt/libsecret
		>=gnome-extra/nm-applet-0.9.8
		>=net-misc/networkmanager-0.9.8:=[introspection] )
	nsplugin? ( >=dev-libs/json-glib-0.13.2 )
	xephyr? ( <x11-wm/mutter-3.21.1 )
	!xephyr? ( >=x11-wm/mutter-3.22.0 )
"
# Runtime-only deps are probably incomplete and approximate.
# Introspection deps generated using:
#  grep -roe "imports.gi.*" gnome-shell-* | cut -f2 -d: | sort | uniq
# Each block:
# 1. Introspection stuff needed via imports.gi.*
# 2. gnome-session is needed for gnome-session-quit
# 3. Control shell settings
# 4. Systemd optional for suspending support
# 5. xdg-utils needed for xdg-open, used by extension tool
# 6. adwaita-icon-theme and dejavu font neeed for various icons & arrows
# 7. mobile-broadband-provider-info, timezone-data for shell-mobile-providers.c
# 8. IBus is needed for nls integration
RDEPEND="${COMMON_DEPEND}
	app-accessibility/at-spi2-core:2[introspection]
	>=app-accessibility/caribou-0.4.8
	dev-libs/libgweather:2[introspection]
	>=sys-apps/accountsservice-0.6.14[introspection]
	>=sys-power/upower-0.99:=[introspection]
	x11-libs/pango[introspection]

	>=gnome-base/gnome-session-2.91.91
	>=gnome-base/gnome-settings-daemon-3.8.3

	ck? ( >=sys-power/upower-0.99:=[ck] )
	elogind? ( sys-auth/elogind )
	systemd? ( >=sys-apps/systemd-186:0= )

	x11-misc/xdg-utils

	media-fonts/dejavu
	>=x11-themes/adwaita-icon-theme-3.19.90

	networkmanager? (
		net-misc/mobile-broadband-provider-info
		sys-libs/timezone-data )
	ibus? ( >=app-i18n/ibus-1.4.99[dconf(+),gtk,introspection] )
"
# avoid circular dependency, see bug #546134
PDEPEND="
	>=gnome-base/gdm-3.5[introspection]
	>=gnome-base/gnome-control-center-3.8.3[bluetooth(+)?,networkmanager(+)?]
	browser-extension? ( gnome-extra/chrome-gnome-shell )
"
DEPEND="${COMMON_DEPEND}
	dev-libs/libxslt
	>=dev-util/gdbus-codegen-2.45.3
	>=dev-util/gtk-doc-am-1.17
	gnome-base/gnome-common
	sys-devel/autoconf-archive
	>=sys-devel/gettext-0.19.6
	virtual/pkgconfig
"

src_prepare() {
	if use ck && use xephyr; then
		# From GNOME (enforce old X11 backend):
		# 	https://gitlab.gnome.org/GNOME/gnome-shell/commit/0c22a21a2490024110d8a61afd4d385b2e91de6c
		# 	https://gitlab.gnome.org/GNOME/gnome-shell/commit/f9ef80749af3535879f6e3d11ac3489270b849f1
		# 	https://gitlab.gnome.org/GNOME/gnome-shell/commit/22f0d3076ead0c20ff5fc0e5f861d7164142e168
		# 	https://gitlab.gnome.org/GNOME/gnome-shell/commit/f5c058a036b21da747921d0ed9eefa64331e4f17
		# 	https://gitlab.gnome.org/GNOME/gnome-shell/commit/358f64d66b37fa547af3e06dc85f4c5f008b7847
		# 	https://gitlab.gnome.org/GNOME/gnome-shell/commit/b7867fe44c45f60a9399baf737132a9ba30351aa
		# 	https://gitlab.gnome.org/GNOME/gnome-shell/commit/093fd54e2b7cf2e57982f78f729394f4f1c0cf4b
		# 	https://gitlab.gnome.org/GNOME/gnome-shell/commit/5ae3e5aeb78d9d47641c85d3e15096912dc36cad
		# 	https://gitlab.gnome.org/GNOME/gnome-shell/commit/af28a219be30490c1c50a9ed99c1e22e70a36826
		eapply -R "${FILESDIR}"/${PN}-3.22.1-window-tracker-consider-flatpak-id-for-window-matching.patch
		eapply -R "${FILESDIR}"/${PN}-3.21.92-recorder-composite-captured-images-before-passing-into-gstreamer.patch
		eapply -R "${FILESDIR}"/${PN}-3.21.92-screenshot-composite-multiple-captures-into-one-image.patch
		eapply -R "${FILESDIR}"/${PN}-3.21.4-use-clutter-stage-capture-instead-of-cogls-read-pixels.patch
		eapply -R "${FILESDIR}"/${PN}-3.21.4-main-reload-theme-on-video-memory-purge-errors.patch
		eapply -R "${FILESDIR}"/${PN}-3.21.2-build-set-rpath-on-more-executables.patch
		eapply -R "${FILESDIR}"/${PN}-3.21.1-build-point-executables-to-our-private-lib-path.patch
		eapply -R "${FILESDIR}"/${PN}-3.21.1-build-explicitly-add-mutter-cogl-pango-dependency.patch
		eapply -R "${FILESDIR}"/${PN}-3.21.1-build-with-merged-mutter-clutter-cogl.patch

		# From GNOME (enforce old X11 backend):
		# 	https://gitlab.gnome.org/GNOME/gnome-shell/commit/296b61b61c623b6a2a1011618ab1300041f45840
		eapply "${FILESDIR}"/${PN}-3.22.1-reduce-mutter-dependency-requirement.patch
	fi

	if use ck; then
		# From Funtoo:
		# 	https://bugs.funtoo.org/browse/FL-1329
		eapply "${FILESDIR}"/${PN}-3.22.0-restore-deprecated-code.patch
		eapply "${FILESDIR}"/${PN}-3.12.2-expose-hibernate-functionality.patch
	fi

	if use deprecated-background; then
		eapply "${FILESDIR}"/${PN}-3.22.3-restore-deprecated-background-code.patch
	fi

	if ! use vanilla-gc; then
		# From GNOME:
		# 	https://gitlab.gnome.org/GNOME/gnome-shell/issues/64
		eapply "${FILESDIR}"/${PN}-3.14.4-force-garbage-collection.patch
	fi

	if ! use vanilla-motd; then
		eapply "${FILESDIR}"/${PN}-3.16.4-improve-motd-handling.patch
	fi

	if ! use vanilla-screen; then
		eapply "${FILESDIR}"/${PN}-3.16.4-improve-screen-blanking.patch
	fi

	if ! use xephyr; then
		# Fix build failure against Mutter-Clutter-Cogl if the libraries are not exported or symlinked
		# https://bugzilla.gnome.org/show_bug.cgi?id=768781
		eapply "${FILESDIR}"/${PN}-3.22.0-fix-mutter-libs.patch
	fi

	# Change favorites defaults, bug #479918
	eapply "${FILESDIR}"/${PN}-3.22.0-defaults.patch

	# Fix automagic gnome-bluetooth dep, bug #398145
	eapply "${FILESDIR}"/${PN}-3.12-bluetooth-flag.patch

	# Fix silent bluetooth linking failure with ld.gold, bug #503952
	# https://bugzilla.gnome.org/show_bug.cgi?id=726435
	eapply "${FILESDIR}"/${PN}-3.14.0-bluetooth-gold.patch

	# Little bug when user has toggled version validation in the session, bug #616698
	eapply "${FILESDIR}"/${PN}-3.22.3-CVE-2017-8288.patch

	eautoreconf
	gnome2_src_prepare
}

src_configure() {
	# Do not error out on warnings
	gnome2_src_configure \
		--enable-man \
		$(use_with bluetooth) \
		$(use_enable networkmanager) \
		$(use_enable nsplugin browser-plugin) \
		$(use_enable systemd) \
		BROWSER_PLUGIN_DIR="${EPREFIX}"/usr/$(get_libdir)/nsbrowser/plugins

	if use ck && use xephyr; then
		# Enforce old X11 backend
		find . -type f -name Makefile -exec sed -i 's/-lmutter-clutter-1.0 //g' {} +
		find . -type f -name Makefile -exec sed -i 's/-lmutter-cogl //g' {} +
	fi
}

src_install() {
	gnome2_src_install
	python_replicate_script "${ED}/usr/bin/gnome-shell-extension-tool"
	python_replicate_script "${ED}/usr/bin/gnome-shell-perf-tool"

	# Required for gnome-shell on hardened/PaX, bug #398941
	# Future-proof for >=spidermonkey-1.8.7 following polkit's example
	if has_version '<dev-lang/spidermonkey-1.8.7'; then
		pax-mark mr "${ED}usr/bin/gnome-shell"{,-extension-prefs}
	elif has_version '>=dev-lang/spidermonkey-1.8.7[jit]'; then
		pax-mark m "${ED}usr/bin/gnome-shell"{,-extension-prefs}
	# Required for gnome-shell on hardened/PaX #457146 and #457194
	# PaX EMUTRAMP need to be on
	elif has_version '>=dev-libs/libffi-3.0.13[pax_kernel]'; then
		pax-mark E "${ED}usr/bin/gnome-shell"{,-extension-prefs}
	else
		pax-mark m "${ED}usr/bin/gnome-shell"{,-extension-prefs}
	fi
}

pkg_postinst() {
	gnome2_pkg_postinst

	if ! has_version 'media-libs/gst-plugins-good:1.0' || \
	   ! has_version 'media-plugins/gst-plugins-vpx:1.0'; then
		ewarn "To make use of GNOME Shell's built-in screen recording utility,"
		ewarn "you need to either install media-libs/gst-plugins-good:1.0"
		ewarn "and media-plugins/gst-plugins-vpx:1.0, or use dconf-editor to change"
		ewarn "apps.gnome-shell.recorder/pipeline to what you want to use."
	fi

	if ! has_version "media-libs/mesa[llvm]"; then
		elog "llvmpipe is used as fallback when no 3D acceleration"
		elog "is available. You will need to enable llvm USE for"
		elog "media-libs/mesa if you do not have hardware 3D setup."
	fi

	# https://bugs.gentoo.org/563084
	if has_version "x11-drivers/nvidia-drivers[-kms]"; then
		ewarn "You will need to enable kms support in x11-drivers/nvidia-drivers,"
		ewarn "otherwise Gnome will fail to start"
	fi

	if use systemd && ! systemd_is_booted; then
		ewarn "${PN} needs Systemd to be *running* for working"
		ewarn "properly. Please follow this guide to migrate:"
		ewarn "https://wiki.gentoo.org/wiki/Systemd"
	fi

	if ! use systemd; then
		ewarn "You have emerged ${PN} without systemd,"
		ewarn "if you experience any issues please use the support thread:"
		ewarn "https://forums.gentoo.org/viewtopic-t-1082226.html"
	fi
}
