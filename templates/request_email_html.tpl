{include file="email_header_html.tpl"}

{$toName|escape}<br>
<br>
This is a request from {$fromName|escape}{if $fromOrg} of {$fromOrg|escape}{/if}.<br>
<br>
Please click on the link below and drop off the file or files I have requested.<br>
{if $note}More information is in the note below.<br>{/if}
<br>
<a href="{$URL}"><b>{$URL|escape}</b></a><br>
<br>
If you wish to contact {$fromName|escape}, just reply to this email.<br>
<br>
{if $note}<b>&mdash; Note &mdash;</b><br>
{$note|escape|nl2br}<br>
<br>
{/if}
--&nbsp;<br>
{$fromName|escape}<br>
{$fromEmail|escape}<br>
{$fromOrg|escape}

{include file="email_footer_html.tpl"}
