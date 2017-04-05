{include file="email_header_html.tpl"}

This is an automated message sent to you by the {#ServiceTitle#} service.
<br>

{* Is it actually a reminder? If so, make it obvious *}
{if $isReminder}
<br><hr><br>
<b>This is a reminder about a drop-off sent to you, that no one has picked up.<br>
The drop-off will expire in {$timeLeft} after which it will be automatically deleted.</b>
<br><hr>
{/if}

<br>
{$senderName|escape}
{* All this escaping helps stop people auto-scraping email addresses *}
(<a href="mailto:{$senderEmail|escape:"hex"}">{$senderEmail|escape:"hexentity"}</a>)
has dropped-off {if $fileCount eq 1}a file{else}{$fileCount} files{/if} for you.<br>
<br>
<b>IF YOU TRUST THE SENDER</b> and are expecting to receive a file from them,
you may choose to retrieve the drop-off by clicking the following link
(or copying and pasting it into your web browser):<br>
<br>
<a href="{$zendToURL}pickup.php?claimID={$claimID|escape:'url'}&claimPasscode={$claimPasscode|escape:'url'}&emailAddr=__EMAILADDR__">{$zendToURL|escape}pickup.php?claimID={$claimID|escape}&claimPasscode={$claimPasscode|escape}&emailAddr=__EMAILADDR__</a><br>
<br>
You have {$timeLeft} to retrieve the drop-off; after that the link above will expire.
<br>
If you wish to contact the sender, just reply to this email.
<br><br>
{if $note ne ""}The sender has left you a note:<br>
<br>
{$note|escape|nl2br}
<br><br>
{/if}
Full information about the drop-off:
<br>
<table border="0" borderpadding="1">
<tr><td>Claim ID:</td><td>{$claimID|escape}</td></tr>
<tr><td>Claim Passcode:</td><td>{$claimPasscode|escape}</td></tr>
<tr><td>Date of Drop-Off:</td><td>{$now|escape}</td></tr>
</table>
<br>

<table border="0" borderpadding="1">
<tr><td colspan="2">&mdash; Sender &mdash;</td></tr>
<tr><td>Name:</td><td>{$senderName|escape}</td></tr>
<tr><td>Organisation:</td><td>{$senderOrg|escape}</td></tr>
<tr><td>Email Address:</td><td>{$senderEmail|escape}</td></tr>
<tr><td>IP Address:</td><td>{$senderIP|escape} {$senderHost|escape}</td></tr>
</table>
<br>

<table border="0" borderpadding="1">
<tr><td colspan="2">&mdash; File{if $fileCount ne 1}s{/if} &mdash;</td></tr>
{for $i=0; $i<$fileCount; $i++}{$f=$files[$i]}
<tr><td>Name:</td><td>{$f.name|escape}</td></tr>
<tr><td>Description:</td><td>{$f.description|escape}</td></tr>
<tr><td>Size:</td><td>{$f.size|escape}</td></tr>
<tr><td>Content Type:</td><td>{$f.type|escape}</td></tr>
<tr><td>&nbsp;</td><td>&nbsp;</td></tr>
{/for}
</table>

{include file="email_footer_html.tpl"}
