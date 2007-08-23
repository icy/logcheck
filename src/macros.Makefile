#/usr/bin/make -f
#
# logcheck interpolation Makefile
#
# The Makefile allows for the automatic generation of logcheck/egrep -f files,
# using interpolation. Any lines starting with '#: ' and specifying a variable
# assignment are parsed into variable/value pairs, which are then subsequently
# interpolated recursively into the rest of the file, replacing occurrences of
# the variable name enclosed with 'at' signes (@).
#
# Example:
#
#   #: MYVAR = myval @ANOTHER@
#   #: ANOTHER = foo
#
#   @MYVAR@
#
# This will yield
#
#   myval foo
#
# Limitations:
# - no way to work around the situation when a string /@[_[:alnum:]]+@/ should
#   actually be part of the result.
#
# Copyright © 2006 martin f. krafft <madduck@debian.org>
# Released under the terms of the Artistic Licence
#
# Revision: 2006.06.30.1253
#

all: $(patsubst %.in,%,$(wildcard *.in))

LEAD = ^\#:
VAR = [_[:alnum:]]+
VAR_ASSIGN = ($(VAR))[[:space:]]*=[[:space:]]*(.*)
ESCAPES = s,\\,\\\\\\,g;s,/,\\/,g

%: SEDSCRIPT = $(shell sed -rne '$(ESCAPES)' -e 's,$(LEAD) $(VAR_ASSIGN),s/@\1@/\2/g;,p' $<)
%: %.in
	sed -re '/$(LEAD) /d' \
			-e '/^(#|[[:space:]]*$$)/d' \
		$< > $@
	while egrep -q '@$(VAR)@' $@; do \
		md5sum=$$(md5sum $@); \
		sed -i -e "$(SEDSCRIPT)" $@; \
		if [ "$$(md5sum $@)" = "$$md5sum" ]; then \
			VAR="$$(sed -rne 's,.*@([^@]+)@.*,\1,p' $@)"; \
			echo "E: found the variable $$VAR but did not know what to substitute." >&2; \
			exit 1; \
		fi; \
		cat $@; \
	done
