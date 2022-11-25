#! /usr/bin/env bash

#
#     beaver build script calamares unit
#
#     (c)2021 nexryai@ablaze.one
#
#     unit.sh
#

# set -e

distro_name=${1}

touch usr/share/calamares/branding/default/branding.desc

cat <<EOF >  usr/share/calamares/branding/default/branding.desc
# Product branding information. This influences some global
# user-visible aspects of Calamares, such as the product
# name, window behavior, and the slideshow during installation.
#
# Additional styling can be done using the stylesheet.qss
# file, also in the branding directory.
---
componentName:  default

# This selects between different welcome texts. When false, uses
# the traditional "Welcome to the %1 installer.", and when true,
# uses "Welcome to the Calamares installer for %1." This allows
# to distinguish this installer from other installers for the
# same distribution.
welcomeStyleCalamares:   false

# Should the welcome image (productWelcome, below) be scaled
# up beyond its natural size? If false, the image does not grow
# with the window but remains the same size throughout (this
# may have surprising effects on HiDPI monitors).
welcomeExpandingLogo:   true

# Size and expansion policy for Calamares.
#  - "normal" or unset, expand as needed, use *windowSize*
#  - "fullscreen", start as large as possible, ignore *windowSize*
#  - "noexpand", don't expand automatically, use *windowSize*
windowExpanding:    normal

# Size of Calamares window, expressed as w,h. Both w and h
# may be either pixels (suffix px) or font-units (suffix em).
#   e.g.    "800px,600px"
#           "60em,480px"
# This setting is ignored if "fullscreen" is selected for
# *windowExpanding*, above. If not set, use constants defined
# in CalamaresUtilsGui, 800x520.
windowSize: 800px,540px

# Placement of Calamares window. Either "center" or "free".
# Whether "center" actually works does depend on the window
# manager in use (and only makes sense if you're not using
# *windowExpanding* set to "fullscreen").
windowPlacement: center

# These are strings shown to the user in the user interface.
# There is no provision for translating them -- since they
# are names, the string is included as-is.
#
# The four Url strings are the Urls used by the buttons in
# the welcome screen, and are not shown to the user. Clicking
# on the "Support" button, for instance, opens the link supportUrl.
# If a Url is empty, the corresponding button is not shown.
#
# bootloaderEntryName is how this installation / distro is named
# in the boot loader (e.g. in the GRUB menu).
#
# These strings support substitution from /etc/os-release
# if KDE Frameworks 5.58 are available at build-time. When
# enabled, @{var-name} is replaced by the equivalent value
# from os-release. All the supported var-names are in all-caps,
# and are listed on the FreeDesktop.org site,
#       https://www.freedesktop.org/software/systemd/man/os-release.html
# Note that ANSI_COLOR and CPE_NAME don't make sense here, and
# are not supported (the rest are). Remember to quote the string
# if it contains substitutions, or you'll get YAML exceptions.
#
# The *Url* entries are used on the welcome page, and they
# are visible as buttons there if the corresponding *show* keys
# are set to "true" (they can also be overridden).
strings:
    productName:         $distro_name
    shortProductName:    $distro_name
    version:
    shortVersion:
    versionedName:       $distro_name
    shortVersionedName:  $distro_name
    bootloaderEntryName: $distro_name
    productUrl:          https://github.com/nexryai/project-alexandrite
    supportUrl:          https://google.com
    knownIssuesUrl:      https://github.com/nexryai/project-alexandrite/issues
    releaseNotesUrl:     https://github.com/nexryai/project-alexandrite

# These images are loaded from the branding module directory.
#
# productIcon is used as the window icon, and will (usually) be used
#       by the window manager to represent the application. This image
#       should be square, and may be displayed by the window manager
#       as small as 16x16 (but possibly larger).
# productLogo is used as the logo at the top of the left-hand column
#       which shows the steps to be taken. The image should be square,
#       and is displayed at 80x80 pixels (also on HiDPI).
# productWelcome is shown on the welcome page of the application in
#       the middle of the window, below the welcome text. It can be
#       any size and proportion, and will be scaled to fit inside
#       the window. Use \`welcomeExpandingLogo\` to make it non-scaled.
#       Recommended size is 320x150.
#
# These filenames can also use substitutions from os-release (see above).
images:
    productIcon:         "logo-16.png"
    productLogo:         "logo-128.png"
    productWelcome:      "languages.png"

# The slideshow is displayed during execution steps (e.g. when the
# installer is actually writing to disk and doing other slow things).
slideshow:               "show.qml"
# There are two available APIs for the slideshow:
#  - 1 (the default) loads the entire slideshow when the installation-
#      slideshow page is shown and starts the QML then. The QML
#      is never stopped (after installation is done, times etc.
#      continue to fire).
#  - 2 loads the slideshow on startup and calls onActivate() and
#      onLeave() in the root object. After the installation is done,
#      the show is stopped (first by calling onLeave(), then destroying
#      the QML components).
slideshowAPI: 2


# Colors for text and background components.
#
#  - sidebarBackground is the background of the sidebar
#  - sidebarText is the (foreground) text color
#  - sidebarTextHighlight sets the background of the selected (current) step.
#    Optional, and defaults to the application palette.
#  - sidebarSelect is the text color of the selected step.
#
# These colors can **also** be set through the stylesheet, if the
# branding component also ships a stylesheet.qss. Then they are
# the corresponding CSS attributes of #sidebarApp.
style:
#   sidebarBackground:    "#EFEFEF"
   sidebarBackground:    "#FFFFFF"
   sidebarText:          "#000000"
   sidebarTextSelect:    "#1565C0"
   sidebarTextHighlight: "#EFEFEF"

EOF