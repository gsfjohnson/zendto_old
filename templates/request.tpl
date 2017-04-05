{include file="header.tpl"}
<link rel="stylesheet" href="css/jquery-ui.min.css">
<script type="text/javascript" src="js/jquery-ui-1.11.4.min.js"></script>
<script type="text/javascript">
<!--
var addressbook = {$addressbook};
var addressnames = [];
var addressmails = [];
var fulladdressmails = [];
var fulladdressmap = [];
$.each(addressbook,function(i,item){
  var fullmail = item['name']+' <'+item['email'] + '>';
  if ($.inArray(item['name'],addressnames)==-1)  addressnames.push(item['name']);
  if ($.inArray(item['email'],addressmails)==-1) addressmails.push(item['email']);
  if ($.inArray(fullmail,fulladdressmails)==-1)  fulladdressmails.push(fullmail);fulladdressmap[fullmail]=item;
});

function addAddressBook () {
        $('#recipEmail').autocomplete({
                source:addressmails,
                appendTo:$('#recipEmail').parent()
        }).autocomplete('widget').css('text-align','left');
        $('#recipName').autocomplete({
                source:fulladdressmails,
                appendTo:$('#recipName').parent(),
                select: function(e,ui){
                        $('#recipName').val(fulladdressmap[ui.item.label].name);
                        $('#recipEmail').val(fulladdressmap[ui.item.label].email);
                        return false;
                }
        }).autocomplete('widget').css('text-align','left');
}
function validateForm()
{
  if ( document.req.recipName.value == "" ) {
    alert("Please enter the recipient's name first!");
    return false;
  }
  if ( document.req.recipEmail.value == "" ) {
    alert("Please enter the recipient's email address first!");
    return false;
  }
  return true;
}
$(document).ready(addAddressBook);
//-->
</script>

    <!-- Left-hand side with all the drop-off information -->
    <form name="req" id="req" method="post"
     action="{$zendToURL}req.php" enctype="multipart/form-data"
     onsubmit="return validateForm();">

<h1>Request a Drop-off</h1>

  <h5>This web page will allow you to send a request to one of more
  other people
  requesting that they send (upload) one or more files for you.
  The recipient will
  receive an automated email containing the information you enter below
  and instructions for uploading the file(s).</h5>

<div class="UILabel">From:</div> <br class="clear" />
<div id="fromHolder"><span id="fromName">{$senderName}</span> <span id="fromEmail">({$senderEmail})</span> <span id="fromOrg"><label for="senderOrg">Organisation:</label><input type="text" id="senderOrg" name="senderOrg" size="30" value="{$senderOrg}"/></span></div>

<br class="clear" />
<div class="UILabel">To:</div> <br class="clear" />
<div id="emailHolder"> <label for="recipName">Name:</label> <input type="text" id="recipName" name="recipName" size="30" value=""/> <label for="recipEmail">Email(s):</label> <input type="text" id="recipEmail" name="recipEmail" size="30" value=""/></div>

<div class="UILabel"><label for="subject">Subject:</label></div> <br class="clear" />
<input type="text" id="subject" name="subject" size="60" value=""/>

<br class="clear" /><br class="clear" />

<label for="note">Note: This will be sent to the recipient. It will also be included in the resulting drop-off sent to you.</label><br/><textarea name="note" id="note" wrap="soft" style="width: 425px; height: 100px"></textarea>

<table border="0"><tr valign="top">
  <td>

      <input type="hidden" name="Action" value="send"/>
      <table border="0" cellpadding="4">

        <tr class="footer">
          <td width="100%" align="center">
            <script type="text/javascript">
              function submitform() {
                if (validateForm()) {
                  document.req.submit();
                }
              }
            </script>
            {call name=button relative=FALSE href="javascript:submitform();" text="Send the Request"}
          </td>
        </tr>
      </table>
  </td>
</tr></table>

</form>

{include file="footer.tpl"}
