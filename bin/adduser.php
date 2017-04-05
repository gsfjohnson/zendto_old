#!/usr/bin/php
<?PHP

if (count($argv)==7 && getenv('ZENDTOPREFS')) {
  array_splice($argv, 1, 0, getenv('ZENDTOPREFS'));
}

if ( count($argv) != 8 ) {
  $prefs=getenv('ZENDTOPREFS');
  if ($prefs=='') {
    printf("
  usage:
  
   %s <ZendTo preferences.php file> '<username>' '<password>' '<email>' '<realname>' '<organization>' '<quota in bytes>'
  
   The ZendTo preferences.php file path should be canonical, not relative.
   (It must start with a \"/\")
   Alternatively, do
     export ZENDTOPREFS=<full file path of preferences.php>
     %s '<username>' '<password>' '<email>' '<realname>' '<organization>' '<quota in bytes>'

   The quota figure must be specified, but is only used by MyZendTo.
   A value of 1 will do fine if you are not using MyZendTo, which you
   probably are not.

",$argv[0],$argv[0]);
  } else {
    printf("
  usage:
  
   %s '<username>' '<password>' '<email>' '<realname>' '<organization>' '<quota in bytes>'
  
   The ZendTo preferences.php file path is pointed to by the environment
   variable ZENDTOPREFS, which is currently set to
   %s

   The quota figure must be specified, but is only used by MyZendTo.
   A value of 1 will do fine if you are not using MyZendTo, which you
   probably are not.

",$argv[0],$prefs);
  }
  return 0;
}

if ( ! preg_match('/^\/.+/',$argv[1]) ) {
  echo "ERROR:  You must provide a canonical path to the preference file.\n";
  return 1;
}

include $argv[1];
require_once(NSSDROPBOX_LIB_DIR."Smartyconf.php");
include_once(NSSDROPBOX_LIB_DIR."NSSDropoff.php");

if ( $theDropbox = new NSSDropbox($NSSDROPBOX_PREFS, FALSE, TRUE) ) {
  
  $username = strtolower($argv[2]);
  $password = $argv[3];
  $email    = $argv[4];
  $realname = $argv[5];
  $org      = $argv[6];
  $quota    = $argv[7];

  $result = $theDropbox->database->DBAddLocalUser($username, $password,
                                                  $email, $realname, $org, $quota);

  // To save newbies trouble, if they are using SQLite (any version)
  // then force the ownership of the SQLite database back to that of
  // the web server if it has become owned by root.
  // This happens when people create a new local user, before they
  // forced the web server to create the database file by displaying
  // the app's home page in a browser.
  if (preg_match('/^SQLite/', SqlBackend)) {
    $sqlite = $NSSDROPBOX_PREFS['SQLiteDatabase'];
    $oldowner = fileowner($sqlite);
    $oldgroup = filegroup($sqlite);
    if ($oldowner == 0 || $oldgroup == 0) {
      $newowner = fileowner($NSSDROPBOX_PREFS['dropboxDirectory']);
      $newgroup = filegroup($NSSDROPBOX_PREFS['dropboxDirectory']);
      chown($sqlite, $newowner);
      chgrp($sqlite, $newgroup);
    }
  }

  if ($result == '') {
    $passprint = 'secret';
    if ($password == '') {
      $passprint = 'WARNING: No password!';
    }
    printf("Created user:\n");
    printf("Username:     $username\n");
    printf("Password:     ($passprint)\n");
    printf("Email:        $email\n");
    printf("Real name:    $realname\n");
    printf("Organization: $org\n");
    if (preg_match('/^[yYtT1]/', MYZENDTO)) {
      printf("Quota:        $quota\n");
    }
    return 0;
  } else {
    printf("Failed: $result\n");
    return 1;
  }
}

?>
