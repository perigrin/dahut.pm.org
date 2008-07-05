<?xml version="1.0" encoding="iso-8859-1" ?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:foaf="http://xmlns.com/foaf/0.1/"
    xmlns:pim="http://www.w3.org/2000/10/swap/pim/contact#"
    xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#"
    xmlns:pm="http://www.pm.org/rdf/0.1/"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
>
<xsl:output indent="yes"/>
<xsl:namespace-alias stylesheet-prefix = "foaf" result-prefix = "foaf" />
<xsl:namespace-alias stylesheet-prefix = "pim" result-prefix = "pim" />
<xsl:namespace-alias stylesheet-prefix = "geo" result-prefix = "geo" />
<xsl:namespace-alias stylesheet-prefix = "pm" result-prefix = "pm" />
<xsl:namespace-alias stylesheet-prefix = "rdf" result-prefix = "rdf" />


<xsl:template match="perl_mongers">
<rdf:RDF>
        <xsl:apply-templates />
</rdf:RDF>	
</xsl:template>

<xsl:template match="group">
    <foaf:Group pm:id="{@id}" pm:status="{@status}">
        <xsl:apply-templates />
    </foaf:Group>
</xsl:template>


<xsl:template match="name">
    <foaf:name><xsl:apply-templates /></foaf:name>
</xsl:template>

<xsl:template match="location">
        <xsl:apply-templates />
</xsl:template>

<xsl:template match="city">
    <pm:city><xsl:apply-templates /></pm:city>
</xsl:template>

<xsl:template match="state">
    <pm:state><xsl:apply-templates /></pm:state>
</xsl:template>

<xsl:template match="region">
    <pm:region><xsl:apply-templates /></pm:region>
</xsl:template>

<xsl:template match="country">
    <pm:country><xsl:apply-templates /></pm:country>
</xsl:template>

<xsl:template match="continent">
    <pm:continent><xsl:apply-templates /></pm:continent>
</xsl:template>

<xsl:template match="longitude">
    <geo:long><xsl:apply-templates /></geo:long>
</xsl:template>

<xsl:template match="latitude">
    <geo:lat><xsl:apply-templates /></geo:lat>
</xsl:template>

<xsl:template match="tsar">    
    <foaf:Person rdf:parseType="Resource">
		<pm:type>tsar</pm:type>
        <xsl:apply-templates/>
    </foaf:Person>
</xsl:template>

<xsl:template match="email">
	<xsl:if test="./text()">
    <foaf:mbox pm:type="{@type}" rdf:resource="mailto:{./text()}" />
	</xsl:if>
</xsl:template>

<xsl:template match="web">
<foaf:homepage rdf:resource="{./text()}" />
</xsl:template>

<xsl:template match="mailing_list">
    <pm:mailing-list rdf:parseType="Resource">
        <xsl:apply-templates />
    </pm:mailing-list>
</xsl:template>

<xsl:template match="mailing-list">
    <pm:mailing-list rdf:parseType="Resource">
        <xsl:apply-templates />
    </pm:mailing-list>
</xsl:template>

<xsl:template match="subscribe">
	<xsl:if test="./text()">
    <foaf:mbox pm:type="subscribe" rdf:resource="mailto:{./text()}" />
	</xsl:if>
</xsl:template>

<xsl:template match="unsubscribe">
	<xsl:if test="./text()">
    <foaf:mbox pm:type="unsubscribe" rdf:resource="mailto:{./text()}" />
	</xsl:if>
</xsl:template>


<xsl:template match="date">
    <pm:inception-date><xsl:apply-templates /></pm:inception-date>
</xsl:template>

</xsl:stylesheet>