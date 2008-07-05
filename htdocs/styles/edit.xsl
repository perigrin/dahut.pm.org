<?xml version="1.0" encoding="iso-8859-1" ?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:output
            method="xml"
            media-type="text/html"
            omit-xml-declaration="no"
            indent="yes"
            doctype-public="-//W3C//DTD XHTML 1.1//EN"
            doctype-system="http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd"
/>

<xsl:template match="/page">
<html>
<head>
<title><xsl:value-of select="name/text()"/></title>
<link rel="stylesheet" type="text/css" href="/orlando/styles/web.css" media="screen" />
</head>
<body>
    <div id="header">
    <xsl:apply-templates select="name"/>
    </div>
    <form method="get">
        <xsl:apply-templates select="document/content" mode="edit"/>
        <input type="submit" name="mode" value="save"/>
        <input type="submit" name="mode" value="preview"/>
    </form>
    <div id="footer">
        <xsl:apply-templates select="document/last_modified"/>
    </div>
</body>
</html>
</xsl:template>

<xsl:template match="content" mode="edit">
    <xsl:element name='div'>
        <xsl:attribute name='class'>
            <xsl:value-of select="name()" />
        </xsl:attribute>
        <xsl:element name='textarea'>
            <xsl:attribute name='name'>
                <xsl:value-of select="name()" />
            </xsl:attribute>
            <xsl:value-of select="./text()"/>
        </xsl:element>
    </xsl:element>
    <xsl:apply-templates select="../checksum"/>
</xsl:template>

<xsl:template match="checksum">
    <xsl:element name="input">
        <xsl:attribute name="type">hidden</xsl:attribute>
        <xsl:attribute name="name">checksum</xsl:attribute>
        <xsl:attribute name="value"><xsl:value-of select="."/></xsl:attribute>
    </xsl:element>
</xsl:template>

<xsl:template match="name">
    <h1><xsl:value-of select="."/></h1>
</xsl:template>

<xsl:template match="last_modified">
    Last Modified: <xsl:value-of select="."/>
</xsl:template>

<xsl:template match="text()" />
<xsl:template match="version"/>
<xsl:template match="metadata"/>

</xsl:stylesheet>
