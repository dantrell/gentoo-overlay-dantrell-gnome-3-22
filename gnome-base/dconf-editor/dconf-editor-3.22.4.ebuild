# Distributed under the terms of the GNU General Public License v2

EAPI="6"

inherit gnome2

DESCRIPTION="Graphical tool for editing the dconf configuration database"
HOMEPAGE="https://gitlab.gnome.org/GNOME/dconf-editor"

LICENSE="LGPL-2.1+"
SLOT="0"
KEYWORDS="*"

COMMON_DEPEND="
	dev-libs/appstream-glib
	>=dev-libs/glib-2.46.0:2
	>=gnome-base/dconf-0.25.1
	>=x11-libs/gtk+-3.22.0:3
"
DEPEND="${COMMON_DEPEND}
	>=dev-util/intltool-0.50
	sys-devel/gettext
	virtual/pkgconfig
"
RDEPEND="${COMMON_DEPEND}
	!<gnome-base/dconf-0.22[X]
"

src_configure() {
	gnome2_src_configure \
		VALAC="$(type -P true)"
}
