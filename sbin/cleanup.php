#!/usr/bin/php
<?PHP

if (@$_ENV['ZENDTOPREFS']) {
  array_splice($argv, 1, 0, $_ENV['ZENDTOPREFS']);
}

if ( count($argv) < 2 ) {
  printf("
  usage:
  
   %s <ZendTo preferences.php file>
  
   The ZendTo preferences.php file path should be canonical, not relative.
   Alternatively, do
     export ZENDTOPREFS=<full file path of preferences.php>
     %s

",$argv[0],$argv[0]);
  return 0;
}

if ( ! preg_match('/^\/.+/',$argv[1]) ) {
  echo "ERROR:  You must provide a canonical path to the preference file.\n";
  return 1;
}

include $argv[1];
include_once(NSSDROPBOX_LIB_DIR."Smartyconf.php");
include_once(NSSDROPBOX_LIB_DIR."NSSDropoff.php");

//// Sort out the root URL as we need it to send the reminder emails.
// Now worked out at top of NSSDropbox.php.
//// This is my best guess if you haven't set it. http and the hostname.
//// You never know, it might work!
//$NSSDROPBOX_URL = 'http://'.php_uname('n').'/';
//// If it is set in the preferences.php, and they have changed it
//// from the default (zendto.soton.ac.uk which doesn't exist)
//// then use that instead.
//if ( array_key_exists('serverRoot', $NSSDROPBOX_PREFS) &&
//     $NSSDROPBOX_PREFS['serverRoot'] !== '' &&
//     !preg_match('/zendto\.soton\.ac\.uk/', $NSSDROPBOX_PREFS['serverRoot']) ) {
//  $NSSDROPBOX_URL = @$NSSDROPBOX_PREFS['serverRoot'];
//}

if ( $theDropbox = new NSSDropbox($NSSDROPBOX_PREFS) ) {
  
  //
  // Get all drop-offs; they come back sorted according to their
  // creation date:
  //
  printf("\nNSSDropbox Cleanup of zendto for preference file:\n  %s\n\n",$argv[1]);
  printf("Gathering dropoffs with creation timestamps before: %s\n",
    timestampForTime( time() - $theDropbox->retainDays() * 24 * 60 * 60 ));
  $oldDropoffs = NSSDropoff::dropoffsOutsideRetentionTime($theDropbox);
  if ( $oldDropoffs && ($iMax = count($oldDropoffs)) ) {
    $i = 0;
    while ( $i < $iMax ) {
      printf("- Removing [%s] %s <%s>\n",
        $oldDropoffs[$i]->claimID(),
        $oldDropoffs[$i]->senderName(),
        $oldDropoffs[$i]->senderEmail()
      );
      $oldDropoffs[$i]->removeDropoff();
      $i++;
    }
  } else {
    print "No dropoffs have expired.\n\n";
  }
  
  //
  // Now nag daily about dropoffs near to their retention limit,
  // that haven't been picked up by anyone.
  //
  printf("\nNSSDropbox Nag recipients about dropoffs close to expiry.\n");
  $oldDropoffs = NSSDropoff::dropoffsNearRetentionTime($theDropbox);
  if ( $oldDropoffs && ($iMax = count($oldDropoffs)) ) {
    $i = 0;
    while ( $i < $iMax ) {
      // Have there been any pickups of this dropoff?
      $pickups = $theDropbox->database->DBPickupsForDropoff($oldDropoffs[$i]->dropoffID());
      if ( count($pickups) == 0 ) {
        printf("- Nagging about [%s] %s <%s>\n",
          $oldDropoffs[$i]->claimID(),
          $oldDropoffs[$i]->senderName(),
          $oldDropoffs[$i]->senderEmail()
        );
        // The 0 tells it not to reset the expiry timer.
        $oldDropoffs[$i]->resendDropoff(FALSE);
      }
      $i++;
    }
  } else {
    print "No dropoffs near expiry.\n\n";
  }
  
  //
  // Do a orphan purge, too:
  //
  printf("Purging orphaned dropoffs:\n");
  NSSDropoff::cleanupOrphans($theDropbox);

  //
  // Now prune the auth table of old keys
  //
  printf("Purging old sender verification data:\n");
  $theDropbox->PruneAuthData();

  //
  // Now prune the req table of old keys
  //
  printf("Purging old request data:\n");
  $theDropbox->PruneReqData();
}

?>
