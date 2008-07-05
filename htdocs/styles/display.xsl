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


<xsl:param name="template">templates/main.html</xsl:param>
<xsl:param name="output">display</xsl:param>

<xsl:variable name="page" select="/page" />

<xsl:template match="/">
        <xsl:copy>
                <xsl:apply-templates select="document($template, /)/html"/>
        </xsl:copy>
</xsl:template>

<xsl:template match="html/head/title/text()">
    <xsl:value-of select="$page/name"/>
</xsl:template>

<xsl:template match="html/body//div[@id='preview']">
        <xsl:copy>
        <xsl:copy-of select="@*"/>
            <xsl:copy-of select="$page//preview"/>
        </xsl:copy>
</xsl:template>

<xsl:template match="html/body//ul[@name='node_list']">
    <xsl:copy>
        <xsl:copy-of select="@*" />
        <xsl:for-each select="$page//revision">
             <xsl:element name='li'>
                <xsl:text>Version: </xsl:text>
                <xsl:value-of select="./version" />
                <xsl:text> </xsl:text>
                <a href="index.cgi?node={$page/name};version={./version}">View</a>
                <xsl:text> | </xsl:text>
                <a href="index.cgi?action=diff;node={$page/name};version={./version};diffversion={$page/document/revision[1]/version}">Diff</a>

                <xsl:text> ... </xsl:text>
                <xsl:value-of select="./modified" />

                <xsl:if test="./username/text()">
                    <xsl:text> by </xsl:text>
                    <a href="index.cgi?node={./username}"><xsl:value-of select="./username"/></a>
                </xsl:if>
                <xsl:if test="./comment/text()">
                    <xsl:text> </xsl:text>
                    <span class="comment"><xsl:value-of select="./comment"/></span>
                </xsl:if>
             </xsl:element>
        </xsl:for-each>
    </xsl:copy>
</xsl:template>

<xsl:template match="html/body//ul[@name='links']">
    <xsl:copy>
        <xsl:copy-of select="@*" />
        <xsl:for-each select="$page//link">
             <xsl:element name='li'>
             <a href="index.cgi?node={./url}"><xsl:value-of select="./title"/></a>
             </xsl:element>
        </xsl:for-each>
    </xsl:copy>
</xsl:template>

<xsl:template match="html//input[@name='checksum']">
        <xsl:copy>
        <xsl:copy-of select="@*[not(@value)]"/>
        <xsl:attribute name="value">
                <xsl:value-of select="$page//checksum"/>
        </xsl:attribute>
        </xsl:copy>
</xsl:template>

<xsl:template match="html//input[@name='node']">
        <xsl:copy>
        <xsl:copy-of select="@*[not(@value)]"/>
        <xsl:attribute name="value">
                <xsl:value-of select="$page//name"/>
        </xsl:attribute>
        </xsl:copy>
</xsl:template>

<xsl:template match="html//input[@name='action']">
        <xsl:copy>
        <xsl:copy-of select="@*[not(@value)]"/>
        </xsl:copy>
</xsl:template>


<xsl:template match="html//div[@name = 'node_links']//a[@name]">
        <xsl:copy>
        <xsl:copy-of select="@*"/>
        <xsl:attribute name="href">
                <xsl:text>?action=</xsl:text>
                <xsl:value-of select="@name"/>
                <xsl:text>;node=</xsl:text>
                <xsl:value-of select="$page//name"/>
        </xsl:attribute>
        <xsl:apply-templates />
        </xsl:copy>
</xsl:template>

<xsl:template match="html/body//*[@id or @name]">

    <xsl:param name="param">
        <xsl:choose>
            <xsl:when test="@id">
                <xsl:value-of select="@id"/>
            </xsl:when>
            <xsl:when test="@name">
                <xsl:value-of select="@name"/>
            </xsl:when>
        </xsl:choose>
    </xsl:param>

    <xsl:choose>
        <xsl:when test="$output = 'edit'">
            <xsl:call-template name="edit">
                <xsl:with-param name="name" select="$param"/>
            </xsl:call-template>
        </xsl:when>
        <xsl:when test="$output = 'preview'">
            <xsl:call-template name="edit">
                <xsl:with-param name="name" select="$param"/>
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <xsl:call-template name="display">
                <xsl:with-param name="name" select="$param"/>
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>

</xsl:template>

<xsl:template name="display">
    <xsl:param name="name" />
    <xsl:choose>
        <xsl:when test="$page//*[name() = $name]">
            <xsl:variable name="node" select="$page//*[name() = $name]" />
            <xsl:copy>
                 <xsl:copy-of select="@*"/>
                 <xsl:copy-of select="$node/* | $node/text()"/>
            </xsl:copy>
        </xsl:when>
        <xsl:otherwise>
            <xsl:call-template name="default_node" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template name="edit">
    <xsl:param name="name" />
    <xsl:choose>
        <xsl:when test="$page//*[name() = $name]">
            <xsl:copy>
                <xsl:copy-of select="@*"/>
                <xsl:apply-templates select="$page//*[name() = $name]/descendant-or-self::*" mode="edit"/>
            </xsl:copy>
        </xsl:when>
        <xsl:otherwise>
            <xsl:call-template name="default_node" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="*" name="default_node">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates />
        </xsl:copy>
</xsl:template>

<xsl:template match="text()">
        <xsl:copy-of select="."/>
</xsl:template>

<xsl:template match="*" mode="page">
     <xsl:apply-templates mode="page"/>
</xsl:template>

<xsl:template match="text()|@*" mode="page">
    <xsl:value-of select="."/>
</xsl:template>

</xsl:stylesheet>
