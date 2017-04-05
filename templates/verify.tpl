{include file="header.tpl"}

<script type="text/javascript">
<!--

function validateForm()
{
{if $allowUploads}
  if ( document.dropoff.req.value != "" ) {
    return true;
  }
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
  
  return true;
{else}
  if ( document.dropoff.req.value == "" ) {
    alert("Please enter your request code before submitting.");
    document.dropoff.req.focus();
    return false;
  }
  return true;
{/if}
}

//-->
</script>
  <form name="dropoff" id="dropoff" method="post"
      action="{$zendToURL}verify.php"
      enctype="multipart/form-data" onsubmit="return validateForm();">
      <input type="hidden" name="Action" value="verify"/>
      <table border="0" cellpadding="4">

        <tr><td width="100%">
          <table class="UD_form" width="100%" cellpadding="4">
            <tr class="UD_form_header"><td colspan="2">
{if $allowUploads}
              <h4>Information about the Sender</h4>
{else}
              <h4>Your Request Code</h4>
{/if}
            </td></tr>

{if $verifyFailed}
  {if $allowUploads}
            <tr><td colspan="2"><b>You did not complete the form, or you failed the "Am I A Real Person?" test.</b></td></tr>
  {/if}
{/if}

{if $allowUploads}
            <tr><td colspan="2">If you have been given a "<b>Request Code</b>" then just enter it here and click the button at the bottom of this form.</td></tr>
{else}
            <td><td colspan="2">Please enter the "<b>Request Code</b>" you have been given.</td></tr>
{/if}
            <tr>
              <td align="right"><label for="req">Request Code:</label></td>
              <td width="60%"><input type="text" id="req" name="req" size="45" value="" class="UITextBox" /></td>
            </tr>
{if $allowUploads}
            <tr><td colspan="2"><hr style="width: 80%;"/></td></tr>
            <tr><td colspan="2">If you do not have a "Request Code" then please complete the rest of this form:</td></tr>

            <tr>
              <td align="right"><label for="senderName">Your name:</label></td>
{if $isAuthorizedUser}
              <td width="60%"><input type="hidden" id="senderName" name="senderName" value="{$senderName}">{$senderName}</td>
{else}
              <td width="60%"><input type="text" id="senderName" name="senderName" size="45" value="{$senderName}" class="UITextBox" /><font style="font-size:9px">(required)</font></td>
{/if}
            </tr>

            <tr>
              <td align="right"><label for="senderOrganization">Your organisation:</label></td>
              <td width="60%"><input type="text" id="senderOrganization" name="senderOrganization" size="45" value="{$senderOrg}"/><font style="font-size:9px">(required)</font></td>
            </tr>
            <tr>
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
  {else}
              {call name=button relative=FALSE href="javascript:submitform();" text="Send confirmation"}
  {/if}
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

{/if}
{else} {* allowUploads = FALSE *}
            <tr class="footer"><td colspan="2" align="center">
              <script type="text/javascript">
                function submitform() {
                  if (validateForm()) { document.dropoff.submit(); }
                }
              </script>
              {call name=button relative=FALSE href="javascript:submitform();" text="Next"}
            </tr>

{/if}

          </table>
        </td></tr>

      </table>
</form>

{* if they are allowed to upload, accelerate the form filling *}
<script type="text/javascript">
<!--
{if $allowUploads}
  {if $isAuthorizedUser}
    // Set the focus to the organization, and let them
    // click Next by pressing Return.
    $(document).ready(function() {
      $('#senderOrganization').focus();
    });
    $('#senderOrganization').keypress(function (e) {
      var key = e.which;
      if (key == 13) { // Return
        e.preventDefault();
        if (validateForm()) { document.dropoff.submit(); }
        return false;
      }
    });
  {else}
    // Set focus the their name (1st field)
    $(document).ready(function() {
      $('#senderName').focus();
    });
  {/if}
{else} {* only the request code box is visible *}
  // Set focus to the request code (only field)
  $(document).ready(function() {
    $('#req').focus();
  });
{/if}
-->
</script>

{include file="footer.tpl"}
