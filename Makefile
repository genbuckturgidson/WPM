SHELL := /bin/bash
PREFIX?=/usr/local
BIN=${PREFIX}/bin
ETC=${PREFIX}/etc/wpm
LIB=${PREFIX}/lib

install:
	@echo "Installing wpm"
	install -m 500 ./bin/wpm.sh $(BIN)/
	ln -s $(BIN)/wpm.sh $(BIN)/wpm
	install -m 500 ./lib/fixserial.sh $(LIB)/
	install -m 500 ./lib/updater.pl $(LIB)/
	install -m 400 ./lib/wpm-backup.inc $(LIB)/
	install -m 400 ./lib/wpm-copy.inc $(LIB)/
	install -m 400 ./lib/wpm-delete.inc $(LIB)/
	install -m 400 ./lib/wpm-find.inc $(LIB)/
	install -m 400 ./lib/wpm-install.inc $(LIB)/
	install -m 400 ./lib/wpm-mangle.inc $(LIB)/
	install -m 400 ./lib/wpm-password.inc $(LIB)/
	install -m 400 ./lib/wpm-permissions.inc $(LIB)/
	install -m 400 ./lib/wpm-rename.inc $(LIB)/
	install -m 400 ./lib/wpm-settings.inc $(LIB)/
	install -m 400 ./lib/wpm-update.inc $(LIB)/
	install -m 400 ./lib/wpm-verify.inc $(LIB)/
	[ -d $(ETC) ] || mkdir -p -m 700 $(ETC)
	install -m 600 ./etc/wpm/wpm.conf $(ETC)/
	install -m 400 ./etc/wpm/changelog.txt $(ETC)/
	sed -i "s#6b4178521b3f#${PREFIX}#g" $(BIN)/wpm.sh
	sed -i "s#6b4178521b3f#${PREFIX}#g" $(LIB)/wpm-backup.inc
	sed -i "s#6b4178521b3f#${PREFIX}#g" $(LIB)/wpm-copy.inc
	sed -i "s#6b4178521b3f#${PREFIX}#g" $(LIB)/wpm-delete.inc
	sed -i "s#6b4178521b3f#${PREFIX}#g" $(LIB)/wpm-find.inc
	sed -i "s#6b4178521b3f#${PREFIX}#g" $(LIB)/wpm-install.inc
	sed -i "s#6b4178521b3f#${PREFIX}#g" $(LIB)/wpm-mangle.inc
	sed -i "s#6b4178521b3f#${PREFIX}#g" $(LIB)/wpm-password.inc
	sed -i "s#6b4178521b3f#${PREFIX}#g" $(LIB)/wpm-permissions.inc
	sed -i "s#6b4178521b3f#${PREFIX}#g" $(LIB)/wpm-rename.inc
	sed -i "s#6b4178521b3f#${PREFIX}#g" $(LIB)/wpm-settings.inc
	sed -i "s#6b4178521b3f#${PREFIX}#g" $(LIB)/wpm-update.inc

uninstall:
	@echo "Removing wpm"
	rm -rf $(BIN)/{wpm,wpm.sh} $(ETC) ${LIB}/{fixserial.sh,updater.pl,wpm-backup.inc,wpm-copy.inc,wpm-delete.inc,wpm-find.inc,wpm-install.inc,wpm-password.inc,wpm-permissions.inc,wpm-rename.inc,wpm-settings.inc,wpm-mangle.inc,wpm-update.inc,wpm-verify.inc}

reinstall:
	@echo "Running reinstall"
	make uninstall && make install

