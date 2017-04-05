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
require_once("ayah.php");
require "autoload.php";
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

  // If they are an authorised user, just display the normal pickup page.
  if ($theDropbox->authorizedUser() ||
      !$theDropbox->humanDownloads() ||
      (($theDropbox->captcha() == 'google' || $theDropbox->captcha() == '') &&
       $theDropbox->recaptchaPrivateKey() == 'disabled') ||
      $theDropbox->captcha() == 'disabled') {
    $theDropbox->SetupPage();

    // 2-line addition by Francois Conil to fix problems with no CAPTCHA
    // and anonymous users who don't have a link to click on.
    $auth = $theDropbox->WriteAuthData(getClientIP(), '', '');
    $smarty->assign('auth', $auth);

    if ( $thePickup = new NSSDropoff($theDropbox) ) {
      //
      // Start the page and add some Javascript for automatically
      // filling-in the download form and submitting it when the
      // user clicks on a file in the displayed dropoff.
      //
      $theDropbox->SetupPage($thePickup->HTMLOnLoadJavascript());
      $output = $thePickup->HTMLWrite();
    }
    $smarty->display($output?$output:'error.tpl');
    exit(0);
  }

  //
  // They are not an authorised user.
  //

  // Start by checking their passed in auth key. If they have auth'ed
  // successfully, then we don't need to do the captcha again, we just
  // present whatever we were going to present.

  $authSuccess = FALSE;
  if (isset($_POST['auth']) && $_POST['auth']) {
    $auth = $_POST['auth'];
    // Sanitise the auth data
    $auth = preg_replace('/[^a-zA-Z0-9]/', '', $auth);
    $authIP = '';
    $authEmail = '';
    $authOrganization = '';
    $authExpiry = 0;
    $result = $theDropbox->ReadAuthData($auth, $authIP,
                                        $authEmail, $authOrganization,
                                        $authExpiry);
    if (! $result) {
      $theDropbox->SetupPage();
      NSSError($smarty->getConfigVariable('ErrorDownloadAuth'),"Authentication Failure");
    }
    if ( $authExpiry > time() && $authIP == getClientIP() ) {
      $authSuccess = TRUE;
    }
    // Everything succeeded, so let them through.
  }

  $ayah = new AYAH();
  $captcha = $theDropbox->captcha();

  // Check their recaptcha result. If they passed, then write an AuthData
  // record with their IP in the Name field. This is then used by download.php.
  // If they failed, re-present the pickup page as if they just went there
  // again, but with an error message at the top telling them they were wrong.
  if ( $authSuccess ||
       ( isset($_POST['Action']) && $_POST['Action'] == "Pickup" )
     ) {
    $resp = FALSE;
    if (!$authSuccess) {
      if ($captcha == 'areyouahuman') {
        $resp = $ayah->scoreResult();
      } elseif ($captcha == 'disabled') {
        $resp = TRUE;
      } else {
        // Using Google or an old version without this set
        $reCaptchaPrivateKey = $theDropbox->recaptchaPrivateKey();
        if ($reCaptchaPrivateKey == 'disabled') {
          $resp = TRUE;
        } else {
          // Old version 1 code.
          // $resp = recaptcha_check_answer($reCaptchaPrivateKey,
          //                                getClientIP(),
          //                                $_POST["g-recaptcha-response"]);
          $recaptcha = new \ReCaptcha\ReCaptcha($reCaptchaPrivateKey);
          $rcresponse = $recaptcha->verify($_POST["g-recaptcha-response"],
                                           getClientIP());
          if ($rcresponse->isSuccess()) {
            $resp = TRUE;
          }
          if (!$resp) {
            foreach ($rcresponse->getErrorCodes() as $code) {
              if ($code == "missing-input-response") {
                $code = "I do not think you are a real person.";
              }
              NSSError($code, "Are you a real person?");
            }
          }
        }
      }
    }

    if ($authSuccess || $resp) {
      // They have passed the CAPTCHA so write an AuthData record for them.
      if (!$authSuccess) {
        // But only if they haven't already been auth-ed once.
        $auth = $theDropbox->WriteAuthData(getClientIP(), '', '');
      }
      if ( $auth == '') {
        // Write failed.
        NSSError("Database failure writing authentication key. Please contact your system administrator.","Internal Error");
        displayPickupCheck($theDropbox, $smarty, $ayah, $auth);
        exit(0);
      }
    } else {
      // The CAPTCHA response was wrong, so re-present the page with an error
      NSSError($smarty->getConfigVariable('ErrorNotPerson'),"Test failed");
      displayPickupCheck($theDropbox, $smarty, $ayah, $auth);
      exit(0);
    }

    // They have passed the test and we have written their AuthData record.

    $theDropbox->SetupPage();
    $smarty->assign('auth', $auth); // And save their auth key!

    if ( $thePickup = new NSSDropoff($theDropbox) ) {
      //
      // Start the page and add some Javascript for automatically
      // filling-in the download form and submitting it when the
      // user clicks on a file in the displayed dropoff.
      //
      $theDropbox->SetupPage($thePickup->HTMLOnLoadJavascript());
      $smarty->display($thePickup->HTMLWrite());
    } else {
      $smarty->display('error.tpl');
    }
  } else {
    // It's not a pickup attempt, it's going to display the CAPTCHA form
    // instead which will pass us back to me again.
    displayPickupCheck($theDropbox, $smarty, $ayah, '');
  }
} else {
  $smarty->display('error.tpl');
}

function displayPickupCheck($theDropbox, $smarty, $ayah, $auth) {
    $theDropbox->SetupPage();
    $claimID = isset($_POST['claimID'])?$_POST['claimID']:(isset($_GET['claimID'])?$_GET['claimID']:NULL);
    $claimPasscode = isset($_POST['claimPasscode'])?$_POST['claimPasscode']:(isset($_GET['claimPasscode'])?$_GET['claimPasscode']:NULL);
    $emailAddr = isset($_POST['emailAddr'])?$_POST['emailAddr']:(isset($_GET['emailAddr'])?$_GET['emailAddr']:NULL);

    $auth = preg_replace('/[^a-zA-Z0-9]/', '', $auth);
    $claimID = preg_replace('/[^a-zA-Z0-9]/', '', $claimID);
    $claimPasscode = preg_replace('/[^a-zA-Z0-9]/', '', $claimPasscode);
    if ( isset($emailAddr) && ! preg_match($theDropbox->validEmailRegexp(),$emailAddr) ) {
      $emailAddr = 'INVALID';
    }

    $smarty->assign('claimID', $claimID);
    $smarty->assign('claimPasscode', $claimPasscode);
    $smarty->assign('emailAddr', $emailAddr);
    $smarty->assign('auth', $auth);

    if ($theDropbox->captcha() == 'areyouahuman') {
      $smarty->assign('recaptchaHTML', $ayah->getPublisherHTML());
    } else {
      // It's the Google reCAPTCHA
      // Set the reCAPTCHA language correctly (default = US English)
      $lang = $theDropbox->recaptchaLanguage();
      $smarty->assign('recaptchaLang', $lang);
      $reCaptchaPublicKey = $theDropbox->recaptchaPublicKey();
      $invisible = $theDropbox->recaptchaInvisible();
      $smarty->assign('recaptchaHTML',
                      recaptcha_get_html($reCaptchaPublicKey,
                                         $invisible));
      $smarty->assign('invisibleCaptcha', $invisible);
    }
    $smarty->display('pickupcheck.tpl');
}
?>
