<html>
<head>
  <meta content="text/html; charset=utf-8" http-equiv="Content-Type">
  <style>
    {fetch file="../www/css/{#CSSTheme#}.css"}
    {fetch file="../www/css/local.css"}
    {* Plus stuff we want to override for the emails *}
    {fetch file="../www/images/{#CSSTheme#}/background.png" assign='background'}
    body {
      background-image: url(data:image/png;base64,{$background|base64_encode});
    }
    .content {
      width: auto;
      margin-top: 15px;
    }
    #container {
      min-height: 0px;
    }
  </style>
</head>
<body>
<div class="content">
<div id="logo"><a href="{$zendToURL}">{include "email_logo_html.tpl"}</a></div>
<div id="container">

