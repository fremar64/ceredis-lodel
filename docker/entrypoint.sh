#!/bin/sh
set -eu
APP_ROOT="/var/www/html"
SOURCE_ROOT="/opt/lodel"
CONFIG_FILE="$APP_ROOT/lodelconfig.php"

if [ ! -f "$APP_ROOT/index.php" ]; then
    echo "Initializing persistent Lodel document root..."
    cp -a "$SOURCE_ROOT"/. "$APP_ROOT"/
fi

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
\$cfg['singledatabase'] = 'off';
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

chown -R www-data:www-data "$APP_ROOT"
exec "$@"
