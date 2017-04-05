{include file="email_header_html.tpl"}

This is an automated message sent to you by the {#ServiceTitle#} service.
<br>

<br>
The drop-off you made (claim ID: {$claimID|escape}) has been picked-up.<br>
<br>
The file "<tt>{$filename|escape}</tt>" was picked up.<br>
<br>
{$whoWasIt|escape} made the pick-up from {if $hostname eq $remoteAddr}{$remoteAddr|escape}{else}{$hostname|escape} ({$remoteAddr|escape}){/if}.<br>
<br>
Note: You will not be notified about any further pick-ups of files in this drop-off by this recipient.

{include file="email_footer_html.tpl"}
