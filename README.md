# WPM

### The automagical WordPress Mangler

**Project Author**: Bradford Morgan White

**Project Started**: 20131222

**Project Updated**: 20190531

**Project Name**: WordPress Mangler

**Project Purpose**: WordPress automagically

---

### SUMMARY

WPM was initially written as just a backup automation of WordPress installations. Overtime, it got extended to do more things, until a rewrite was necessary. Now, it does all the things... automagically.

### CONFIGURATION

WPM calls `$PREFIX/etc/wpm.conf` for those environmental options that it has.

### INSTALLATION

As root, just type `make install` within this archive. There is one configurable option within the make file, and that is the installation prefix. It will default to `/usr/local`. The script assumes it is running as root, and the install will set permissions accordingly. Usage information is available with `wpm --help`. There is a `make uninstall` as well if you decide you hate it, and there is a ``make reinstall` if you modify something and make the script worse.

### USAGE

So, `wpm --help` will show you this:

```
usage:
  -b | --backup	 backup a wordpress installation 
	 -n | --no-compress	 the xz or gz container won't actually be compressed 
	 -d | --delete-old	 delete older backups 
	 -s | --skip-uploads	 skip the uploads directory 
	 -p | --path	 the WordPress install's location 

  -c | --copy	 copy a WP install from one domain/directory to another 
	 -o | --oldname 
	 -n | --newname 
	 -s | --source 
	 -d | --destination 

  -d | --delete	 delete a WP install and DB 
	 -b | --backup	 do a backup first 
	 -p | --path 

  -s | --search	 locate all WP installs 
	 example: wpm -s /var/www/

  -i | --install	install wordpress 
	 -d | --domain 
	 -p | --path 

  -m | --mangle	 find and then update all WordPress installs 
	 -n | --no-backup	 do not backup the WP installs first (bad idea, btw)
	 -p | --path	 the search path for installs 
	 -s | --skip-search	 skip doing the search for installs 

  -w | --password	 change a user password permanently/temporarily 
	 -d | --duration	 duration of password change 
	 -u | --username	 user who's password should be changed 
	 -v | --view	 view the WP usernames 
	 -p | --path	 location of the WP install 

  -p | --permissions	 reset file/directory perms to safe values 
	 example: wpm -p /var/www/html 

  -r | --rename	 change the domain name of WP install 
	 -o | --oldname 
	 -n | --newname 
	 -p | --path 

  --settings	 change or view settings 
	 example: wpm --settings list 
	 example: wpm --settings BACKUPPATH=/var/www/backup 

  -u | --update	 update a wordpress install 
	 -b | --backup	 do a backup first 
	 -g | --plugins	 update plugins too 
	 -p | --path	 location of the WP install 

  -v | --verify	 scan a wordpress install 
	 -s | --scan	 scan with maldet 
	 -m | --md5	 md5 files from install against version from wordpress.org 
	 -b | --backup	 run a backup first 
	 -r | --replace	 replace modified files (requires --md5) 
	 -p | --path		 location of the WP install

  -h | --help	 print this help text
```

### NOTES

The `--install` function configures WordPress to use ftpsockets for `FS_METHOD`. This will require that you have an FTP server running even if it's only listening on 127.0.0.1. This same assumption is made by the `--permissions` function. Both `--install` and `--permissions` will set the user and group such that the web process is not the owner of the files, and that the web group will have read access only. This is to attempt to prevent file injection. The `--permissions` function does make permission settings backups if the `getfacl` command is available.

The `--verify` function requires maldet if you wish to use the `--scan` option. The `--md5` option will download a copy of the installed WP version from WordPress.org and will md5 every file and compare. If you select the `--replace` option, any file will get replaced if a difference is detected. The `--replace` option also enables quarantining in `--scan`. It is highly recommended to only use `--replace` if you use `--backup`.

You may notice that the `--mangle` function has an option for skipping search. This is because the `--search` function will generate lists in $TEMPDIR which can be modified, should you wish to skip a particular installation.

---

### LICENSE

Copyright MMXIX, Bradford Morgan White

Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
