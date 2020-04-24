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
	install -m 400 ./lib/wpm-backup.sh $(LIB)/
	install -m 400 ./lib/wpm-copy.sh $(LIB)/
	install -m 400 ./lib/wpm-delete.sh $(LIB)/
	install -m 400 ./lib/wpm-find.sh $(LIB)/
	install -m 400 ./lib/wpm-install.sh $(LIB)/
	install -m 400 ./lib/wpm-mangle.sh $(LIB)/
	install -m 400 ./lib/wpm-password.sh $(LIB)/
	install -m 400 ./lib/wpm-permissions.sh $(LIB)/
	install -m 400 ./lib/wpm-rename.sh $(LIB)/
	install -m 400 ./lib/wpm-settings.sh $(LIB)/
	install -m 400 ./lib/wpm-update.sh $(LIB)/
	install -m 400 ./lib/wpm-verify.sh $(LIB)/
	[ -d $(ETC) ] || mkdir -p -m 700 $(ETC)
	install -m 600 ./etc/wpm/wpm.conf $(ETC)/
	install -m 400 ./etc/wpm/changelog.txt $(ETC)/
	sed -i "s#6b4178521b3f#${PREFIX}#g" $(BIN)/wpm.sh
	sed -i "s#6b4178521b3f#${PREFIX}#g" $(LIB)/wpm-backup.sh
	sed -i "s#6b4178521b3f#${PREFIX}#g" $(LIB)/wpm-copy.sh
	sed -i "s#6b4178521b3f#${PREFIX}#g" $(LIB)/wpm-delete.sh
	sed -i "s#6b4178521b3f#${PREFIX}#g" $(LIB)/wpm-find.sh
	sed -i "s#6b4178521b3f#${PREFIX}#g" $(LIB)/wpm-install.sh
	sed -i "s#6b4178521b3f#${PREFIX}#g" $(LIB)/wpm-mangle.sh
	sed -i "s#6b4178521b3f#${PREFIX}#g" $(LIB)/wpm-password.sh
	sed -i "s#6b4178521b3f#${PREFIX}#g" $(LIB)/wpm-permissions.sh
	sed -i "s#6b4178521b3f#${PREFIX}#g" $(LIB)/wpm-rename.sh
	sed -i "s#6b4178521b3f#${PREFIX}#g" $(LIB)/wpm-settings.sh
	sed -i "s#6b4178521b3f#${PREFIX}#g" $(LIB)/wpm-update.sh

uninstall:
	@echo "Removing wpm"
	rm -rf $(BIN)/{wpm,wpm.sh} $(ETC) ${LIB}/{fixserial.sh,updater.pl,wpm*.inc,wpm*.sh}

reinstall:
	@echo "Running reinstall"
	make uninstall && make install

