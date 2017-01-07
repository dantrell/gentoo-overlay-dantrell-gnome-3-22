# Distributed under the terms of the GNU General Public License v2

EAPI="6"

inherit autotools gnome2

DESCRIPTION="Personal task manager"
HOMEPAGE="https://wiki.gnome.org/Apps/Todo"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="*"

IUSE="+introspection"

RDEPEND="
	>=dev-libs/glib-2.43.4:2
	>=dev-libs/libical-0.43
	>=dev-libs/libpeas-1.17
	>=gnome-extra/evolution-data-server-3.17.1:=[gtk]
	>=net-libs/gnome-online-accounts-3.2:=
	>=x11-libs/gtk+-3.22.0:3

	introspection? ( >=dev-libs/gobject-introspection-1.42:= )
"
DEPEND="${RDEPEND}
	dev-libs/appstream-glib
	>=dev-util/gtk-doc-am-1.14
	>=dev-util/intltool-0.40.6
	sys-devel/gettext
	virtual/pkgconfig
"

src_prepare() {
	# From Arch Linux:
	# 	https://git.archlinux.org/svntogit/packages.git/commit/?id=2c0d28e17eca04d8905cc36d682865de762ef88f
	eapply "${FILESDIR}"/${PN}-3.22.0-correct-linking-order.patch

	eautoreconf
	gnome2_src_prepare
}

src_configure() {
	gnome2_src_configure \
		$(use_enable introspection) \
		--enable-eds-plugin \
		--enable-dark-theme-plugin \
		--enable-scheduled-panel-plugin \
		--enable-score-plugin \
		--enable-today-panel-plugin \
		--enable-unscheduled-panel-plugin
}
