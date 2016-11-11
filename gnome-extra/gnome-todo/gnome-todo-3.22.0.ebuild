# Distributed under the terms of the GNU General Public License v2

EAPI="6"

inherit autotools gnome2

DESCRIPTION="Personnal task manager"
HOMEPAGE="https://wiki.gnome.org/Apps/Todo"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="*"

IUSE=""

RDEPEND="
	>=dev-libs/glib-2.43.4:2
	>=dev-libs/gobject-introspection-1.42:=
	>=dev-libs/libical-0.43
	>=dev-libs/libpeas-1.17
	>=gnome-extra/evolution-data-server-3.17.1[gtk]
	>=net-libs/gnome-online-accounts-3.2:=
	>=x11-libs/gtk+-3.22.0:3
"
DEPEND="${RDEPEND}
	>=dev-util/intltool-0.40.6
	dev-libs/appstream-glib
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
	gnome2_src_configure --enable-eds-plugin
}
