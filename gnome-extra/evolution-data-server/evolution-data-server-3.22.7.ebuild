# Distributed under the terms of the GNU General Public License v2

EAPI="8"
PYTHON_COMPAT=( python{3_10,3_11,3_12,3_13} pypy )

inherit db-use flag-o-matic gnome2 python-any-r1 systemd vala virtualx

DESCRIPTION="Evolution groupware backend"
HOMEPAGE="https://wiki.gnome.org/Apps/Evolution https://gitlab.gnome.org/GNOME/evolution-data-server"

# Note: explicitly "|| ( LGPL-2 LGPL-3 )", not "LGPL-2+".
LICENSE="|| ( LGPL-2 LGPL-3 ) BSD Sleepycat"
SLOT="0/59" # subslot = libcamel-1.2 soname version
KEYWORDS="*"

IUSE="berkdb +gnome-online-accounts +gtk gtk-doc google +introspection ldap kerberos vala +weather"
REQUIRED_USE="vala? ( introspection )"

# Some tests fail due to missing locales.
# Also, dbus tests are flaky, bugs #397975 #501834
# It looks like a nightmare to disable those for now.
RESTRICT="!test? ( test )"

# gdata-0.17.7 soft required for new gdata_feed_get_next_page_token API to handle more than 100 google tasks
# berkdb needed only for migrating old addressbook data from <3.13 versions, bug #519512
gdata_depend=">=dev-libs/libgdata-0.17.7:="
RDEPEND="
	>=app-crypt/gcr-3.4:0=
	>=app-crypt/libsecret-0.5[crypt]
	>=dev-db/sqlite-3.7.17:=
	>=dev-libs/glib-2.46:2
	>=dev-libs/libical-0.43:=
	>=dev-libs/libxml2-2
	>=dev-libs/nspr-4.4:=
	>=dev-libs/nss-3.9:=
	>=net-libs/libsoup-2.42:2.4

	dev-libs/icu:=
	sys-libs/zlib:=
	virtual/libiconv

	berkdb? ( >=sys-libs/db-4:= )
	gtk? (
		>=app-crypt/gcr-3.4:0=[gtk]
		>=x11-libs/gtk+-3.10:3
	)
	google? (
		>=dev-libs/json-glib-1.0.4
		>=net-libs/webkit-gtk-2.11.91:4
		${gdata_depend}
	)
	gnome-online-accounts? (
		>=net-libs/gnome-online-accounts-3.8:=
		${gdata_depend} )
	introspection? ( >=dev-libs/gobject-introspection-0.9.12:= )
	kerberos? ( virtual/krb5:= )
	ldap? ( >=net-nds/openldap-2:= )
	weather? ( >=dev-libs/libgweather-3.10:2= )
"
DEPEND="${RDEPEND}
	vala? ( $(vala_depend) )
"
BDEPEND="
	${PYTHON_DEPS}
	dev-util/gdbus-codegen
	dev-util/gperf
	>=dev-build/gtk-doc-am-1.14
	>=dev-util/intltool-0.35.5
	>=gnome-base/gnome-common-2
	>=sys-devel/gettext-0.17
	virtual/pkgconfig
"

pkg_setup() {
	python-any-r1_pkg_setup
}

src_prepare() {
	# From GNOME:
	# 	https://bugzilla.gnome.org/show_bug.cgi?id=795295
	eapply "${FILESDIR}"/${PN}-3.13.90-bug-795295-fails-to-compile-after-icu-61-1-upgrade-icuunicodestring.patch

	use vala && vala_setup
	gnome2_src_prepare
}

src_configure() {
	# /usr/include/db.h is always db-1 on FreeBSD
	# so include the right dir in CPPFLAGS
	use berkdb && append-cppflags "-I$(db_includedir)"

	# phonenumber does not exist in tree
	gnome2_src_configure \
		$(use_enable gtk-doc) \
		$(use_with gtk-doc private-docs) \
		$(usex berkdb --with-libdb="${EPREFIX}"/usr --with-libdb=no) \
		$(use_enable gnome-online-accounts goa) \
		$(use_enable gtk) \
		$(use_enable google google-auth) \
		$(use_enable google) \
		$(use_enable introspection) \
		--enable-ipv6 \
		$(use_with kerberos krb5 "${EPREFIX}"/usr) \
		$(use_with kerberos krb5-libs "${EPREFIX}"/usr/$(get_libdir)) \
		$(use_with ldap openldap) \
		$(use_enable vala vala-bindings) \
		$(use_enable weather) \
		--enable-largefile \
		--enable-smime \
		--with-systemduserunitdir="$(systemd_get_userunitdir)" \
		--without-phonenumber \
		--disable-examples \
		--disable-uoa
}

src_test() {
	unset ORBIT_SOCKETDIR
	unset SESSION_MANAGER
	virtx emake check
}

src_install() {
	gnome2_src_install

	if use ldap; then
		insinto /etc/openldap/schema
		doins "${FILESDIR}"/calentry.schema
		dosym /usr/share/${PN}/evolutionperson.schema /etc/openldap/schema/evolutionperson.schema
	fi
}

pkg_postinst() {
	gnome2_pkg_postinst
	if ! use berkdb; then
		ewarn "You will need to enable berkdb USE for migrating old"
		ewarn "(pre-3.13 evolution versions) addressbook data"
	fi
}
