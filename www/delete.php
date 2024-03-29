<?PHP
//
// ZendTo
// Copyright (C) 2006 Jeffrey Frey, frey at udel dot edu
// Copyright (C) 2010 Julian Field, Jules at ZendTo dot com 
//
// Based on the original PERL dropbox written by Doke Scott.
// Developed by Julian Field.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
//
//

//
// Include the dropbox preferences -- we need this to have the
// dropbox filepaths setup for us, beyond simply needing our
// configuration!
//
require "../config/preferences.php";
require_once(NSSDROPBOX_LIB_DIR."Smartyconf.php");
require_once(NSSDROPBOX_LIB_DIR."NSSDropoff.php");

//
// This is pretty straightforward; depending upon the form data coming
// into this PHP session, creating a new dropoff object will either
// display the claimID-and-claimPasscode "dialog" (no form data or
// missing/invalid passcode); display the selected dropoff if the
// claimID and claimPasscode are valid OR the recipient matches the
// authenticate user -- it's all built-into the NSSDropoff class.
//

if ( $theDropbox = new NSSDropbox($NSSDROPBOX_PREFS) ) {
  $theDropbox->SetupPage();
  if ( $thePickup = new NSSDropoff($theDropbox) ) {

    $claimID = $thePickup->claimID();
    $smarty->assign('claimID', $claimID);

    // Check the claimPasscode matches too
    $success = FALSE;
    $formPasscode = isset($_POST['claimPasscode']) ? $_POST['claimPasscode'] : "";
    $formPasscode = preg_replace('/[^a-zA-Z0-9]/', '', $formPasscode);
    if ( $formPasscode !== "" && $formPasscode === $thePickup->claimPasscode() ) {
      $success = $thePickup->removeDropoff();
      $smarty->assign('success', $success);
      $smarty->assign('autoHome', TRUE);
    }
    
    if ( ! $success ) {
      NSSError("Unable to remove the dropoff.  Please contact the system administrator.",
               "Unable to remove ".$claimID." using passcode '".$formPasscode."'");
    }
  }
}

$smarty->display('delete.tpl');

?>
