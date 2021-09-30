# WPM

### The automagical WordPress Mangler

**Project Author**: Bradford Morgan White

**Project Started**: 20131222

**Project Updated**: 20210930

**Project Name**: WordPress Mangler

**Project Purpose**: WordPress automagically

---

### SUMMARY

WPM was initially written as just a backup automation of WordPress installations. Overtime, it got extended to do more things, until a rewrite was necessary. Now, it does all the things... automagically.

### CONFIGURATION

WPM calls `$PREFIX/etc/wpm.conf` for those environmental options that it has.

### INSTALLATION

As root, just type `make install` within this archive. There is one configurable option within the make file, and that is the installation prefix. It will default to `/usr/local`. The script assumes it is running as root, and the install will set permissions accordingly. Usage information is available with `wpm --help`. There is a `make uninstall` as well if you decide you hate it, and there is a `make reinstall` if you modify something and make the script worse.

### USAGE

Try using `wpm --help`

```
sudo wpm -h
wpm version 4.1.1

-r       rename a wordpress installation
-c       copy a wordpress installation
-i       install wordpress
-u       update a wordpress installation
-p       attempt to set sane permissions on a WP installation
-d       delete a wordpress installation
-b       backup a wordpress installation
-w       change a wordpress user's password
-e       change wpm settings
-s       search for wordpress installations
-m       find and update wordpress installations
-v       verify a wordpress installation
```

### NOTES

The `--install` function, by default, configures WordPress to use ftpsockets for `FS_METHOD`. This will require that you have an FTP server running even if it's only listening on 127.0.0.1. This same assumption is made by the `--permissions` function. Both `--install` and `--permissions` will set the user and group such that the web process is not the owner of the files, and that the web group will have read access only. This is to attempt to prevent file injection. The `--permissions` function does make permission settings backups if the `getfacl` command is available. FTP sockets configuration can be skipped via the `--skip-ftp` for both `-i` and `-u`.

The `--verify` function requires maldet and clamdscan if you wish to use the `--scan` option. The `--md5` option will download a copy of the installed WP version from WordPress.org and will md5 every file and compare. If you select the `--replace` option, any file will get replaced if a difference is detected. The `--replace` option also enables quarantining in `--scan`. It is highly recommended to only use `--replace` if you use `--backup`.

You may notice that the `--mangle` function has an option for skipping search. This is because the `--search` function will generate lists in $TEMPDIR which can be modified, should you wish to skip a particular installation.

The `--delete` function will **NOT** remove the FTP user used for ftpsockets.

---

### LICENSE

This software is licensed under terms of the Absurd License 2.0.6. Please see the LICENSE file.
