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

if ( $theDropbox = new NSSDropbox($NSSDROPBOX_PREFS) ) {
  //
  // This page handles the listing of dropoffs made by an
  // authenticated user.  If the user is NOT authenticated,
  // then an error is presented.
  //
  $theDropbox->SetupPage();

  if ( $theDropbox->authorizedUser() ) {
    //
    // Returns an array of all NSSDropoff instances belonging to
    // this user.
    //
    $allDropoffs = NSSDropoff::dropoffsFromCurrentUser($theDropbox);
    //
    // Start the web page and add some Javascript to automatically
    // fill-in and submit a pickup form when a dropoff on the page
    // is clicked.
    //
    $iMax = count($allDropoffs);
    $totalsize = 0;
    $smarty->assign('countDropoffs', $iMax);

    if ( $allDropoffs && $iMax>0 ) {
      $outputDropoffs = array();
      $i = 0;
      foreach($allDropoffs as $dropoff) {
        $outputDropoffs[$i] = array();
        $outputDropoffs[$i]['claimID'] = $dropoff->claimID();
        $outputDropoffs[$i]['senderName'] = $dropoff->senderName();
        $outputDropoffs[$i]['senderOrg']  = htmlspecialchars($dropoff->senderOrganization());
        $outputDropoffs[$i]['senderEmail'] = $dropoff->senderEmail();
        $outputDropoffs[$i]['createdDate'] = timeForDate($dropoff->created());
        $outputDropoffs[$i]['formattedBytes'] = $dropoff->formattedBytes();
        $outputDropoffs[$i]['Bytes'] = $dropoff->Bytes();
        $totalsize += $theDropbox->database()->DBBytesOfDropoff($dropoff->dropoffID());

        $recipients = $allDropoffs[$i]->recipients();
        $j = 0;
        $outputDropoffs[$i]['recipients'] = array();
        foreach ( $dropoff->recipients() as $recipient ) {
          $outputDropoffs[$i]['recipients'][$j] = array();
          $outputDropoffs[$i]['recipients'][$j]['name'] = htmlentities($recipient[0]);
          $outputDropoffs[$i]['recipients'][$j]['email'] = htmlentities($recipient[1]);
          $j++;
        }

        $i++;
      }
      $smarty->assignByRef('dropoffs', $outputDropoffs);
      $smarty->assign('formattedTotalBytes', NSSFormattedMemSize($totalsize));
    }
  } else {
    NSSError($smarty->getConfigVars('ErrorNotLoggedIn'),"Access Denied");
  }

  $smarty->display('dropoff_list.tpl');
}

?>
