<?php
/**
 * LODEL - Logiciel d'Édition ÉLectronique.
 * @license GPL 2 (http://www.gnu.org/licenses/gpl.html) See COPYING file
 * @authors See COPYRIGHT file
 */

$cfg['version']="1.0";

##########################

define("LODELROOT","../");

require(LODELROOT."lodelconfig.php");

/*
 * The Lodel application is served from the document root by Apache.
 * PHP does not necessarily use the directory containing this script as
 * its current working directory, so relative paths are unsafe here.
 * Normalize the shared paths against the actual Lodel document root.
 */
$documentRoot = realpath(__DIR__ . "/..");
if ($documentRoot === false) {
    throw new RuntimeException("Unable to resolve Lodel document root.");
}

$cfg['home'] = $documentRoot . "/lodel/scripts/";
$cfg['sharedir'] = $documentRoot . "/share";

ini_set('include_path', $cfg['home'] . PATH_SEPARATOR . ini_get("include_path"));

$cfg['site']="";

require 'context.php';
C::setCfg($cfg);
require 'class.errors.php';

