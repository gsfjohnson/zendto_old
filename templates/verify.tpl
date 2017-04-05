{include file="header.tpl"}

<script type="text/javascript">
<!--

var $fullFormTextVisible = true;

function validateForm()
{
{if $allowUploads}
  if ( ! $fullFormTextVisible ) {
    // Only request code visible
    if ( document.dropoff.req.value == "" ) {
      alert("Please enter your Request Code before submitting.");
      document.dropoff.req.focus();
      return false;
    }
  } else {
    // Full form visible
    if ( document.dropoff.senderName.value == "" ) {
      alert("Please enter your name before submitting.");
      document.dropoff.senderName.focus();
      return false;
    }
    if ( document.dropoff.senderOrganization.value == "" ) {
      document.dropoff.senderOrganization.value = "-";
      // alert("Please enter your organisation before submitting.");
      // document.dropoff.senderOrganization.focus();
      // return false;
    }
    if ( document.dropoff.senderEmail.value == "" ) {
      alert("Please enter your email address before submitting.");
      document.dropoff.senderEmail.focus();
      return false;
    }
  }
{else}
  if ( document.dropoff.req.value == "" ) {
    alert("Please enter your request code before submitting.");
    document.dropoff.req.focus();
    return false;
  }
{/if}
  // If not caught by now, allow submission
  return true;
}

function whichForm(b)
{
  if (b == "yes") {
    // They have a request code
    $(".fullFormText").css("display", "none");
    $(".reqFormText").css("display", "");
    $('#req').focus();
    $("#yes").addClass("UD_buttonchosen");
    $("#no").removeClass("UD_buttonchosen");
    $fullFormTextVisible = false;
  } else {
    // Show them the main form
    $(".reqFormText").css("display", "none");
    $(".fullFormText").css("display", "");
{if $isAuthorizedUser}
    $('#senderOrganization').focus();
{else}
    $('#senderName').focus();
{/if}
    $("#yes").removeClass("UD_buttonchosen");
    $("#no").addClass("UD_buttonchosen");
    // Wipe the req field
    $("#req").val("");
    $fullFormTextVisible = true;
  }
}




//-->
</script>
  <form name="dropoff" id="dropoff" method="post"
      action="{$zendToURL}verify.php"
      enctype="multipart/form-data" onsubmit="return validateForm();">
      <input type="hidden" name="Action" value="verify"/>
      <table border="0" cellpadding="4">

        <tr><td width="100%">
          <table class="UD_form" border="0" width="100%" cellpadding="4">
            <tr class="UD_form_header"><td colspan="2">
{if ! $allowUploads}
              <h4>Your Request Code</h4>
            </td></tr>
            <tr>
              <td align="right"><label for="req">Request Code:</label></td>
              <td width="60%"><input type="text" id="req" name="req" size="45" value="" class="UITextBox" /></td>
            </tr>
            <tr class="footer"><td colspan="2" align="center">
              <script type="text/javascript">
                function submitform() {
                  if (validateForm()) { document.dropoff.submit(); }
                }
              </script>
              {call name=button relative=FALSE href="javascript:submitform();" text="Next"}
            </tr>
{else} {* $allowUploads *}
              <h4>Information about the Sender</h4>
            </td></tr>
  {if $verifyFailed}
            <tr><td colspan="2"><b>You did not complete the form, or you failed the "Am I A Real Person?" test.</b></td></tr>
  {/if}
            <tr><td colspan="2">Have you been given a "<b>Request Code</b>"?&nbsp;&nbsp; 
              <a class="UD_textbutton_content UD_textbutton" style="float:none" id="yes" href="javascript:whichForm('yes');">Yes</a>
              <a class="UD_textbutton_content UD_textbutton" style="float:none" id="no" href="javascript:whichForm('no');">No</a>
            </td></tr>
            <tr><td colspan="2"><hr style="width: 80%;"/></td></tr>
            <tr class="reqFormText">
              <td align="right"><label for="req">Request Code:</label></td>
              <td width="60%"><input type="text" id="req" name="req" size="45" value="" class="UITextBox" /></td>
            </tr>

            <tr class="fullFormText">
              <td align="right"><label for="senderName">Your name:</label></td>
  {if $isAuthorizedUser}
              <td width="60%"><input type="hidden" id="senderName" name="senderName" value="{$senderName}">{$senderName}</td>
  {else}
              <td width="60%"><input type="text" id="senderName" name="senderName" size="45" value="{$senderName}" class="UITextBox" /><font style="font-size:9px">(required)</font></td>
  {/if}
            </tr>

            <tr class="fullFormText">
              <td align="right"><label for="senderOrganization">Your organisation:</label></td>
              <td width="60%"><input type="text" id="senderOrganization" name="senderOrganization" size="45" value="{$senderOrg}"/><font style="font-size:9px">(required)</font></td>
            </tr>
            <tr class="fullFormText">
              <td align="right"><label for="senderEmail">Your email address:</label></td>
  {if $isAuthorizedUser}
              <td width="60%"><input type="hidden" id="senderEmail" name="senderEmail" value="{$senderEmail}">{$senderEmail}</td>
  {else}
              <td width="60%"><input type="text" id="senderEmail" name="senderEmail" size="45" value="{$senderEmail}" class="UITextBox" /><font style="font-size:9px">(required)</font></td>
  {/if}
            </tr>

  {if ! $isAuthorizedUser}
            <tr>
              <td colspan="2" align="center">
    {if ! $recaptchaDisabled && ! $invisibleCaptcha}
                To confirm that you are a <i>real</i> person (and not a computer), please complete the quick challenge below:<br />&nbsp;<br />
                {$recaptchaHTML}
                <br />
    {/if}
                I now need to send you a confirmation email.<br />
                When you get it in a minute or two, click on
                the link in it.
              </td>
            </tr>

            <tr class="footer"><td colspan="2" align="center">
              <script type="text/javascript">
                function submitform() {
                  if (validateForm()) { document.dropoff.submit(); }
                }
              </script>
    {if $invisibleCaptcha}
              <table class="UD_textbutton">
                <tr valign="middle">
                  <td class="UD_textbutton_left"><a class="UD_textbuttonedge" href="javascript:submitform();">&nbsp;</a></td>
                  <td class="UD_textbutton_content" align="center"><button {$recaptchaHTML}>Send confirmation</button></td>
                  <td class="UD_textbutton_right"><a class="UD_textbuttonedge" href="javascript:submitform();">&nbsp;</a></td>
                </tr>
              </table>
    {else} {* Visible captcha *}
              {call name=button relative=FALSE href="javascript:submitform();" text="Send confirmation"}
    {/if} {* $invisibleCaptcha *}
            </tr>
  {else} {* they are an authorised user, so no captcha *}
            <tr class="footer"><td colspan="2" align="center">
              <script type="text/javascript">
                function submitform() {
                  if (validateForm()) { document.dropoff.submit(); }
                }
              </script>
              {call name=button relative=FALSE href="javascript:submitform();" text="Next"}
            </tr>

  {/if} {* $isAuthorizedUser *}
{/if} {* $allowUploads *}

          </table>
        </td></tr>

      </table>
</form>

{* if they are allowed to upload, accelerate the form filling *}
<script type="text/javascript">
<!--
{if $allowUploads}
  // Set the focus to the organization, and let them
  // click Next by pressing Return.
  $(document).ready(function() {
    whichForm('no'); // assume no request code by default
  // If logged in, submit if Return pressed in Org field
  // If not logged in, submit if Return pressed in Email field
  {if $isAuthorizedUser}
    $('#senderOrganization').keypress(function (e) {
  {else}
    $('#senderEmail').keypress(function (e) {
  {/if}
      var key = e.which;
      if (key == 13) { // Return
        e.preventDefault();
        if (validateForm()) { document.dropoff.submit(); }
        return false;
      }
    });
  });
{else} {* only the request code box is visible *}
  // Set focus to the request code (only field)
  $(document).ready(function() {
    $('#req').focus();
  });
{/if}
-->
</script>

{include file="footer.tpl"}
