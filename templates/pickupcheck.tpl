{include file="header.tpl"}

<script type="text/javascript">
<!--
function submitform() {
  return document.submitform.submit();
}
//-->
</script>

  <form name="submitform" method="post" action="{$zendToURL}pickup.php">
      <input type="hidden" name="Action" value="Pickup"/>
      <input type="hidden" name="claimID" value="{$claimID}"/>
      <input type="hidden" name="claimPasscode" value="{$claimPasscode}"/>
      <input type="hidden" name="emailAddr" value="{$emailAddr}"/>
      <input type="hidden" name="auth" value="{$auth}"/>

      <table border="0" cellpadding="4">

{if ! $invisibleCaptcha}
            <tr class="UD_form_header"><td colspan="2">
              <h4>Please prove you are a person</h4>
            </td></tr>

            <tr>
              <td colspan="2" align="center">
                To confirm that you are a <i>real</i> person (and not a computer), please complete the quick challenge below then click "Pickup Files":<br />&nbsp;<br />
                {$recaptchaHTML}
                <br />
              </td>
            </tr>
{/if}

            <tr class="footer"><td colspan="2" align="center">

{if $invisibleCaptcha}
              <table class="UD_textbutton">
                <tr valign="middle">
                  <td class="UD_textbutton_left"><a class="UD_textbuttonedge" href="javascript:submitform();">&nbsp;</a></td>
                  <td class="UD_textbutton_content" align="center"><button {$recaptchaHTML}>Pickup Files</button></td>
                  <td class="UD_textbutton_right"><a class="UD_textbuttonedge" href="javascript:submitform();">&nbsp;</a></td>
                </tr>
              </table>
{else}
              {call name=button href="javascript:submitform();" width="100%" text="Pickup Files"}
{/if}
            </tr>

      </table>
  </form>

{include file="footer.tpl"}
