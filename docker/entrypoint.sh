#!/bin/sh
set -eu
APP_ROOT="/var/www/html"
SOURCE_ROOT="/opt/lodel"
CONFIG_FILE="$APP_ROOT/lodelconfig.php"

if [ ! -f "$APP_ROOT/index.php" ]; then
    echo "Initializing persistent Lodel document root..."
    cp -a "$SOURCE_ROOT"/. "$APP_ROOT"/
fi

# The Lodel document root is a persistent volume. New image builds therefore
# do not automatically replace the application code already present in that
# volume. Synchronize only the immutable application trees on every startup;
# keep the runtime configuration and user/site data in the persistent root.
echo "Synchronizing Lodel application code into persistent document root..."
mkdir -p "$APP_ROOT/lodel/scripts" "$APP_ROOT/lodel/src" "$APP_ROOT/share" "$APP_ROOT/lodeladmin"
rsync -a "$SOURCE_ROOT/lodel/scripts/" "$APP_ROOT/lodel/scripts/"
rsync -a "$SOURCE_ROOT/lodel/src/" "$APP_ROOT/lodel/src/"
rsync -a "$SOURCE_ROOT/share/" "$APP_ROOT/share/"
rsync -a "$SOURCE_ROOT/lodeladmin/" "$APP_ROOT/lodeladmin/"

if [ ! -f "$CONFIG_FILE" ]; then
    : "${LODEL_DB_NAME:?LODEL_DB_NAME is required}"
    : "${LODEL_DB_USER:?LODEL_DB_USER is required}"
    : "${LODEL_DB_PASSWORD:?LODEL_DB_PASSWORD is required}"
    : "${LODEL_DB_HOST:?LODEL_DB_HOST is required}"

    INSTALL_KEY="$(cat /proc/sys/kernel/random/uuid)"

    cat > "$CONFIG_FILE" <<EOF
<?php
/* CEREDIS runtime configuration for Lodel ${LODEL_VERSION}. */
\$cfg['install_key'] = '${INSTALL_KEY}';
\$cfg['database'] = '${LODEL_DB_NAME}';
\$cfg['dbusername'] = '${LODEL_DB_USER}';
\$cfg['dbpasswd'] = '${LODEL_DB_PASSWORD}';
\$cfg['dbhost'] = '${LODEL_DB_HOST}';
\$cfg['dbDriver'] = 'mysqli';
\$cfg['valid_db_charset'] = array('utf8', 'utf8mb3', 'utf8mb4');
\$cfg['timezone'] = '${LODEL_TIMEZONE:-Africa/Brazzaville}';
\$cfg['locale'] = '${LODEL_LOCALE:-fr_FR.UTF-8}';
\$cfg['pathroot'] = '.';
\$cfg['urlroot'] = '/';
\$cfg['home'] = './lodel/scripts/';
\$cfg['importdir'] = '';
\$cfg['timeout'] = 120*60;
\$cfg['cookietimeout'] = 4*3600;
\$cfg['cacheOptions'] = array('driver'=>'file','prefix'=>'lodel','cache_dir'=>sys_get_temp_dir(),'default_expire'=>3600);
\$cfg['cacheDir'] = sys_get_temp_dir();
\$cfg['version'] = '1.0';
\$cfg['revision'] = '443X';
\$cfg['shareurl'] = \$cfg['urlroot'].'share';
\$cfg['sharedir'] = "${APP_ROOT}/share";
\$cfg['contactbug'] = 'support@ceredis.net';
\$cfg['mysqldir'] = '/usr/bin';
\$cfg['singledatabase'] = 'on';
\$cfg['tableprefix'] = '';
\$cfg['sessionname'] = 'session'.\$cfg['database'];
\$cfg['detectlanguage'] = true;
\$cfg['extensionscripts'] = 'php';
define("URI","id");
\$cfg['otxurl'] = '';
\$cfg['otxusername'] = '';
\$cfg['otxpasswd'] = '';
\$cfg['tmpoutdir'] = '';
\$cfg['maxUploadFileSize'] = 10240000;
\$cfg['proxyhost'] = '';
\$cfg['proxyport'] = '8080';
\$cfg['authorizedFiles'] = array('.png','.gif','.jpg','.jpeg','.tif','.doc','.odt','.ods','.odp','.pdf','.ppt','.sxw','.xls','.rtf','.zip','.gz','.ps','.ai','.eps','.swf','.rar','.mpg','.mpeg','.avi','.asf','.flv','.wmv','.docx','.xlsx','.pptx','.mp3','.mp4','.ogg','.xml');
\$cfg['authorized_import'] = array('doc','docx','sxw','odt','rtf');
define("DONTUSELOCKTABLES",false);
\$cfg['db_no_intrusion'] = array();
\$cfg['chooseoptions'] = "oui";
\$cfg['includepath'] = "";
\$cfg['htaccess'] = "on";
\$cfg['filemask'] = "0700";
\$cfg['usesymlink'] = "oui";
\$cfg['installoption'] = "2";
\$cfg['installlang'] = "fr";
\$GLOBALS['cacheOptions'] = \$cfg['cacheOptions'];
\$cfg['debugMode'] = 0;
\$cfg['showPubErrMsg'] = false;
\$cfg['dieOnErr'] = false;
setlocale(LC_ALL, \$cfg['locale']);
date_default_timezone_set(\$cfg['timezone']);
ignore_user_abort();
\$currentdb = "";
\$cfg['currentdb'] = "";
\$GLOBALS['currentdb'] = \$cfg['currentdb'];
if (!\$cfg['filemask']) { \$cfg['filemask'] = 0700; }
define("NORECORDURL",1);
define("INC_LODELCONFIG",1);
EOF

    touch "$APP_ROOT/$INSTALL_KEY"
fi

# Lodel's installer creates a site layout around the shared source tree.
# The persistent Docker volume does not run that installer, so recreate the
# essential, idempotent links needed by the public/admin entry points.
ensure_dir() {
    dir="$1"
    mkdir -p "$dir"
}

ensure_link() {
    target="$1"
    link="$2"

    if [ -L "$link" ]; then
        current="$(readlink "$link")"
        if [ "$current" = "$target" ]; then
            return 0
        fi
        rm -f "$link"
    elif [ -e "$link" ]; then
        return 0
    fi

    ln -s "$target" "$link"
}

ensure_dir "$APP_ROOT/upload"
ensure_dir "$APP_ROOT/tpl"
ensure_dir "$APP_ROOT/css"
ensure_dir "$APP_ROOT/images"
ensure_dir "$APP_ROOT/docannexe/file"
ensure_dir "$APP_ROOT/docannexe/image"
ensure_dir "$APP_ROOT/lodel/sources"
ensure_dir "$APP_ROOT/lodel/icons"
ensure_dir "$APP_ROOT/lodel/edition"
ensure_dir "$APP_ROOT/lodel/admin"
ensure_dir "$APP_ROOT/lodel/edition/tpl"
ensure_dir "$APP_ROOT/lodel/admin/tpl"

# lodeladmin/lodelconfig.php adds lodel/scripts to PHP's include_path.
# The View layer nevertheless resolves the login template from the site root
# (./tpl/login.html), as in the original Lodel installation.
ensure_link "../lodel/src/lodel/admin/tpl/login.html" "$APP_ROOT/tpl/login.html"
ensure_link "lodel/src/lodel/admin/login.php" "$APP_ROOT/login.php"
ensure_link "lodel/src/lodel/admin/logout.php" "$APP_ROOT/logout.php"

# Keep the traditional lodel/admin layout coherent as well.
ensure_link "../../src/lodel/admin/tpl/login.html" "$APP_ROOT/lodel/admin/tpl/login.html"
ensure_link "../../src/lodel/admin/login.php" "$APP_ROOT/lodel/admin/login.php"
ensure_link "../../src/lodel/admin/logout.php" "$APP_ROOT/lodel/admin/logout.php"

touch "$APP_ROOT/docannexe/index.html" "$APP_ROOT/docannexe/image/index.html"

chown -R www-data:www-data "$APP_ROOT"
exec "$@"
