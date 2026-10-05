<?php
/**
 * LODEL - Logiciel d'Édition ÉLectronique.
 * @license GPL 2 (http://www.gnu.org/licenses/gpl.html) See COPYING file
 * @authors See COPYRIGHT file
 */

$cfg['version']="1.0";

##########################

/*
 * Resolve the Lodel document root from this file rather than relying on
 * PHP's current working directory.
 */
$documentRoot = realpath(__DIR__ . "/..");
if ($documentRoot === false) {
    throw new RuntimeException("Unable to resolve Lodel document root.");
}

require $documentRoot . "/lodelconfig.php";

/*
 * The Lodel application is served from the document root by Apache.
 * Normalize the shared paths against the actual Lodel document root.
 */
$cfg['home'] = $documentRoot . "/lodel/scripts/";
$cfg['sharedir'] = $documentRoot . "/share";

ini_set('include_path', $cfg['home'] . PATH_SEPARATOR . ini_get("include_path"));

$cfg['site']="";

require 'context.php';
C::setCfg($cfg);
require 'class.errors.php';

