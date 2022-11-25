# This file is read each time a login shell is started.

test -z "$PROFILEREAD" && . /etc/profile || true

export GTK_IM_MODULE=ibus
export XMODIFIERS=@im=ibus
export QT_IM_MODULE=ibus
exec ibus-daemon -dx &
