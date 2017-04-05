{include file="email_header_html.tpl"}

This is an automated message sent to you by the {#ServiceTitle#} service.
<br>
<br>

<table border="0" borderpadding="1">
<tr><td>Name:</td><td>{$senderName|escape}</td></tr>
<tr><td>Organization:</td><td>{$senderOrg|escape}</td></tr>
<tr><td>Email:</td><td>{$senderEmail|escape}</td></tr>
</table>

<br>
You have asked us to send you this message so that you can drop-off some files for someone.<br>
<br>
<b>IGNORE THIS MESSAGE IF YOU WERE NOT IMMEDIATELY EXPECTING IT!</b><br>
<br>
Otherwise, continue the process by clicking the following link (or copying and pasting it into your web browser):<br>
<br>
<a href="{$URL}"><b>{$URL|escape}</b></a>

{include file="email_footer_html.tpl"}
