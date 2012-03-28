<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">
    <xsl:output method="text"/>
    <xsl:variable name="baseUrl" select="'http://genealogy.obdurodon.org'"/>
    <xsl:variable name="countryColors">
        <color country="Rus'">red</color>
        <color country="Bohemia">darkslateblue</color>
        <color country="Byzantium">purple</color>
        <color country="the German Empire">green</color>
        <color country="Scandinavia">lightblue</color>
        <color country="Sweden">slategray</color>
        <color country="Norway">seagreen</color>
        <color country="Wendland">magenta</color>
        <color country="Hungary">orangered</color>
        <color country="Poland">lavender</color>
        <color country="England">darkred</color>
        <color country="France">navy</color>
        <color country="Denmark">orange</color>
        <color country="Polovtsy">olive</color>
        <color country="Ossetia">peru</color>
        <color country="Abkhaz">chocolate</color>
        <color country="Pomerania">greenyellow</color>
        <color country="Scotland">saddlebrown</color>
        <color country="Serbia">yellowgreen</color>
        <color country="Croatia">mediumpurple</color>
        <default>yellow</default>
    </xsl:variable>
    <xsl:template match="/">
        <xsl:variable name="family" select="."/>
        <xsl:text>digraph familyTree
{
    bgcolor="transparent";
    center = true;</xsl:text>
        <xsl:for-each-group group-by="@absoluteGeneration" select="//entry" xml:space="default">
            <xsl:sort order="descending" select="current-grouping-key()"/>

    subgraph Generation<xsl:value-of select="current-grouping-key()"/>
    {
        rank = same;
            
        /*  Create nodes for this level */
            <xsl:for-each select="current-group()" xml:space="default">
                <xsl:variable name="origin" select="@origin"/>
                <xsl:variable name="nodeColor" select="if ($countryColors//color[@country eq $origin]) then(data($countryColors//color[@country eq $origin])) else(data($countryColors//default))"/>
                <xsl:value-of select="translate(@handle, '-', '')"/> [shape = box, URL = "<xsl:value-of select="$baseUrl"/>/findPerson.php?person=<xsl:value-of select="@handle"/>", label = "<xsl:value-of select="@name"/>", color = "<xsl:value-of select="$nodeColor"/>", fillcolor = white, style = filled, target = _parent];
            </xsl:for-each>
            <xsl:text>&#xA;</xsl:text>
        /* Mark marriages between members of this generation */
            <xsl:for-each select="current-group()[@gender = 'male' and count(relation[@type = 'spouse']) &gt; 0]">
                <xsl:variable name="male" select="@handle"/>
                <xsl:variable name="numberMarriages" select="count(relation[@type = 'spouse'])"/>
                <xsl:variable name="marriages" select="current()//relation[@type = 'spouse']"/>
            // Marriages concerning "<xsl:value-of select="@handle"/>"
                <xsl:for-each select="$marriages" xml:space="default">
                    <xsl:variable name="female" select="@to"/>
                    <xsl:variable name="haveChildren" select="count($family//relation[@type = 'child' and @to = $male and @with = $female]) &gt; 0"/>
                    <xsl:choose>
                        <xsl:when test="$haveChildren and $numberMarriages eq 1">
                <xsl:value-of select="translate(ancestor-or-self::entry/@handle, '-', '')"/>AND<xsl:value-of select="translate(@to, '-', '')"/> [shape = point, width = 0, height = 0];
                <xsl:value-of select="translate(ancestor-or-self::entry/@handle, '-', '')"/> -&gt; <xsl:value-of select="translate(ancestor-or-self::entry/@handle, '-', '')"/>AND<xsl:value-of select="translate(@to, '-', '')"/> [dir = none, style = dashed];
                <xsl:value-of select="translate(ancestor-or-self::entry/@handle, '-', '')"/>AND<xsl:value-of select="translate(@to, '-', '')"/> -&gt; <xsl:value-of select="translate(@to, '-', '')"/> [dir = none, style = dashed];
                        </xsl:when>
                        <xsl:when test="not($haveChildren) and $numberMarriages eq 1">
                            <xsl:value-of select="translate(ancestor-or-self::entry/@handle, '-', '')"/> -&gt; <xsl:value-of select="translate(@to, '-', '')"/> [dir = none, style = dashed]
                        </xsl:when>
                        <xsl:when test="$numberMarriages mod 2 = 0 and position() lt ($numberMarriages div 2)">
                            <xsl:value-of select="translate(@to, '-', '')"/> -&gt; <xsl:value-of select="translate((following-sibling::relation)[1]/@to, '-', '')"/> [dir = none, style = dashed]
                        </xsl:when>
                        <xsl:when test="$numberMarriages mod 2 = 0 and position() eq ($numberMarriages div 2)">
                <xsl:value-of select="translate(@to, '-', '')"/> -&gt; <xsl:value-of select="translate(ancestor-or-self::entry/@handle, '-', '')"/> [dir = none, style = dashed];<xsl:text>&#xA;</xsl:text>
                        </xsl:when>
                        <xsl:when test="$numberMarriages mod 2 = 0 and position() eq ($numberMarriages div 2) + 1">
                            <xsl:text>                </xsl:text><xsl:value-of select="translate(ancestor-or-self::entry/@handle, '-', '')"/> -&gt; <xsl:value-of select="translate(@to, '-', '')"/> [dir = none, style = dashed];
                        </xsl:when>
                        <xsl:when test="$numberMarriages mod 2 = 0 and position() gt ($numberMarriages div 2) + 1">
                            <xsl:value-of select="translate((preceding-sibling::relation)[last()]/@to, '-', '')"/> -&gt; <xsl:value-of select="translate(@to, '-', '')"/> [dir = none, style = dashed]
                        </xsl:when>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:for-each>
        /* Connect the last member of one family on this generation to the first of the following family */
        /*      This is a fix to force the graph to keep the order we want it to.                        */
<xsl:for-each select="distinct-values(current-group()//relation[@type = 'child']/@marriageId)">
                <xsl:if test="position() &lt; last()">
                    <xsl:variable name="marriageA" select="current()"/>
                    <xsl:variable name="position" select="position()"/>
                    <xsl:variable name="marriageB" select="distinct-values(current-group()//relation[@type = 'child']/@marriageId)[$position + 1]"/>
                    <xsl:variable name="lastMemberA">
                        <xsl:choose>
                            <xsl:when test="count((current-group()[relation[@type = 'child' and @marriageId = $marriageA]])[last()]/relation[@type = 'spouse']) &gt; 0">
                                <xsl:value-of select="((current-group()[relation[@type = 'child' and @marriageId = $marriageA]])[last()]/relation[@type = 'spouse'])[last()]/@to"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="(current-group()[relation[@type = 'child' and @marriageId = $marriageA]])[last()]/@handle"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:variable name="firstMemberB">
                        <xsl:choose>
                            <xsl:when test="count((current-group()[relation[@type = 'child' and @marriageId = $marriageB]])[1]/relation[@type = 'spouse']) &gt; 0">
                                <xsl:value-of select="((current-group()[relation[@type = 'child' and @marriageId = $marriageB]])[1]/relation[@type = 'spouse'])[1]/@to"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="(current-group()[relation[@type = 'child' and @marriageId = $marriageB]])[1]/@handle"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
<xsl:text>            </xsl:text><xsl:value-of select="translate($lastMemberA, '-', '')"/> -&gt; <xsl:value-of select="translate($firstMemberB, '-', '')"/> [style = invis];
</xsl:if>
            </xsl:for-each>
    }       /* End of subgraph Generation<xsl:value-of select="current-grouping-key()"/> */
            <xsl:for-each select="current-group()[count(relation[@type = 'child']) &gt; 0]">
                <xsl:variable name="marriageHandle" select="(relation[@type = 'child'])[1]/@marriageId"/>
                <xsl:variable name="fatherHandle" select="(relation[@type = 'child'])[1]/@to"/>
                <xsl:variable name="father" select="($family//entry[@handle eq $fatherHandle])[1]"/>
                <xsl:choose>
                    <xsl:when test="count($family//entry[relation[@type = 'child' and @marriageId = $marriageHandle]]) &gt; 1">
                        <xsl:variable name="topNode" select="concat(translate(@handle, '-', ''), 'Son')"/>
                        <xsl:value-of select="$topNode"/> -&gt; <xsl:value-of select="translate(@handle, '-', '')"/> [dir = none, weight = 50];
                        <xsl:for-each select="relation[@type = 'spouse']">
                            <xsl:value-of select="$topNode"/> -&gt; <xsl:value-of select="translate(@to, '-', '')"/> [dir = none, style = invis];
                        </xsl:for-each>
                    </xsl:when>
                    <xsl:when test="count($father//relation[@type = 'spouse']) eq 1">
                        <xsl:variable name="topNode" select="concat(translate((relation[@type = 'child'])[1]/@to, '-', ''), 'AND', translate((relation[@type = 'child'])[1]/@with, '-', ''))"/>
                        <xsl:value-of select="$topNode"/> -&gt; <xsl:value-of select="translate(@handle, '-', '')"/> [dir = none, weight = 50];
                        <xsl:for-each select="relation[@type = 'spouse']">
                            <xsl:value-of select="$topNode"/> -&gt; <xsl:value-of select="translate(@to, '-', '')"/> [dir = none, style = invis];
                        </xsl:for-each>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:variable name="topNode" select="translate((relation[@type = 'child'])[1]/@with, '-', '')"/>
                        <xsl:value-of select="$topNode"/> -&gt; <xsl:value-of select="translate(@handle, '-', '')"/> [dir = none, weight = 50];
                        <xsl:for-each select="relation[@type = 'spouse']">
                            <xsl:value-of select="$topNode"/> -&gt; <xsl:value-of select="translate(@to, '-', '')"/> [dir = none, style = invis];
                        </xsl:for-each>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
            <xsl:variable name="generationHandles" select="current-group()/@handle"/>
            <xsl:variable name="absoluteGeneration" select="current-grouping-key()"/>
            <xsl:variable name="currentGenMarriageHandlesForMarriagesWithChildren" select="distinct-values($family//relation[@type = 'child' and (@to = $generationHandles or @width = $generationHandles)]/@marriageId)"/>
            <xsl:if test="count($family//relation[@type = 'child' and @to = $generationHandles]) &gt; 0">
    subgraph Generation<xsl:value-of select="$absoluteGeneration"/>Sons
    {
        rank = same;
                <xsl:for-each select="$family//entry[count(relation[@type = 'child' and @to = $generationHandles]) &gt; 0]">
                    <xsl:variable name="marriageHandle" select="(relation[@type = 'child'])[1]/@marriageId"/>
                    <xsl:if test="count($family//entry[relation[@type = 'child' and @marriageId = $marriageHandle]]) &gt; 1">
                        <xsl:value-of select="translate(@handle, '-', '')"/>Son [shape = rect, width = 0, height = 0, fixedsize = true, label = ""];
                    </xsl:if>
                </xsl:for-each>
                <xsl:for-each select="$currentGenMarriageHandlesForMarriagesWithChildren">
                    <xsl:variable name="marriageId" select="current()"/>
                    <xsl:variable name="marriageChildren" select="$family//entry[count(relation[@type = 'child' and @marriageId = $marriageId]) &gt; 0]"/>
                    <xsl:if test="count($marriageChildren) &gt; 1">
                        <xsl:for-each select="$marriageChildren">
                            <xsl:variable name="position" select="position()"/>
                            <xsl:if test="count($marriageChildren) mod 2 = 0">
                                <xsl:choose>
                                    <xsl:when test="count($marriageChildren) div 2 = $position">
                                        <xsl:value-of select="translate(($marriageChildren//relation[@type = 'child' and @marriageId = $marriageId])[1]/@to, '-', '')"/>AND<xsl:value-of select="translate(($marriageChildren//relation[@type = 'child' and @marriageId = $marriageId])[1]/@with, '-', '')"/>Son [shape = point, width = 0, height = 0];
                                        <xsl:value-of select="translate(@handle, '-', '')"/>Son -&gt; <xsl:value-of select="translate(($marriageChildren//relation[@type = 'child' and @marriageId = $marriageId])[1]/@to, '-', '')"/>AND<xsl:value-of select="translate(($marriageChildren//relation[@type = 'child' and @marriageId = $marriageId])[1]/@with, '-', '')"/>Son [dir = none];
                                        <xsl:value-of select="translate(($marriageChildren//relation[@type = 'child' and @marriageId = $marriageId])[1]/@to, '-', '')"/>AND<xsl:value-of select="translate(($marriageChildren//relation[@type = 'child' and @marriageId = $marriageId])[1]/@with, '-', '')"/>Son -&gt; <xsl:value-of select="translate($marriageChildren[$position + 1]/@handle, '-', '')"/>Son [dir = none];
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:if test="$position &lt; count($marriageChildren)">
                                            <xsl:value-of select="translate(@handle, '-', '')"/>Son -&gt; <xsl:value-of select="translate($marriageChildren[$position + 1]/@handle, '-', '')"/>Son [dir = none];
                                        </xsl:if>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:if>
                            <xsl:if test="not(count($marriageChildren) mod 2 = 0)">
                                <xsl:if test="position() &lt; last()">
                                    <xsl:value-of select="translate(@handle, '-', '')"/>Son -&gt; <xsl:value-of select="translate($marriageChildren[$position + 1]/@handle, '-', '')"/>Son [dir = none];
                                </xsl:if>
                            </xsl:if>
                        </xsl:for-each>
                    </xsl:if>
                </xsl:for-each>
                }
                <xsl:for-each select="$currentGenMarriageHandlesForMarriagesWithChildren">
                    <xsl:variable name="marriageId" select="current()"/>
                    <xsl:variable name="father" select="($family//entry[@gender='male' and count(relation[@type = 'spouse' and @marriageId = $marriageId]) gt 0])[1]"/>
                    <xsl:variable name="marriageChildren" select="$family//entry[count(relation[@type = 'child' and @marriageId = $marriageId]) &gt; 0]"/>
                    <xsl:if test="count($marriageChildren) &gt; 1">
                        <xsl:for-each select="$marriageChildren">
                            <xsl:choose>
                                <xsl:when test="count($father/relation[@type = 'spouse']) = 1 and count($marriageChildren) mod 2 = 1 and position() = ceiling(count($marriageChildren) div 2)">
                                    <xsl:value-of select="translate(($marriageChildren//relation[@type = 'child' and @marriageId = $marriageId])[1]/@to, '-', '')"/>AND<xsl:value-of select="translate(($marriageChildren//relation[@type = 'child' and @marriageId = $marriageId])[1]/@with, '-', '')"/> -&gt; <xsl:value-of select="translate(@handle, '-', '')"/>Son [dir = none, weight = 50];
                                </xsl:when>
                                <xsl:when test="count($father/relation[@type = 'spouse']) = 1">
                                    <xsl:value-of select="translate(($marriageChildren//relation[@type = 'child' and @marriageId = $marriageId])[1]/@to, '-', '')"/>AND<xsl:value-of select="translate(($marriageChildren//relation[@type = 'child' and @marriageId = $marriageId])[1]/@with, '-', '')"/> -&gt; <xsl:value-of select="translate(@handle, '-', '')"/>Son [dir = none, style = invis];
                                </xsl:when>
                                <xsl:when test="count($marriageChildren) mod 2 = 1 and position() = ceiling(count($marriageChildren) div 2)">
                                    <xsl:value-of select="translate(($marriageChildren//relation[@type = 'child' and @marriageId = $marriageId])[1]/@with, '-', '')"/> -&gt; <xsl:value-of select="translate(@handle, '-', '')"/>Son [dir = none, weight = 50];
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="translate(($marriageChildren//relation[@type = 'child' and @marriageId = $marriageId])[1]/@with, '-', '')"/> -&gt; <xsl:value-of select="translate(@handle, '-', '')"/>Son [dir = none, style = invis];
                                </xsl:otherwise>
                            </xsl:choose>
                            <xsl:if test="count($marriageChildren) mod 2 = 0 and count($marriageChildren) div 2 = position()">
                                <xsl:choose>
                                    <xsl:when test="count($father/relation[@type = 'spouse']) = 1">
                                        <xsl:value-of select="translate(($marriageChildren//relation[@type = 'child' and @marriageId = $marriageId])[1]/@to, '-', '')"/>AND<xsl:value-of select="translate(($marriageChildren//relation[@type = 'child' and @marriageId = $marriageId])[1]/@with, '-', '')"/> -&gt; <xsl:value-of select="translate(($marriageChildren//relation[@type = 'child' and @marriageId = $marriageId])[1]/@to, '-', '')"/>AND<xsl:value-of select="translate(($marriageChildren//relation[@type = 'child' and @marriageId = $marriageId])[1]/@with, '-', '')"/>Son [dir = none];
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="translate(($marriageChildren//relation[@type = 'child' and @marriageId = $marriageId])[1]/@with, '-', '')"/> -&gt; <xsl:value-of select="translate(($marriageChildren//relation[@type = 'child' and @marriageId = $marriageId])[1]/@to, '-', '')"/>AND<xsl:value-of select="translate(($marriageChildren//relation[@type = 'child' and @marriageId = $marriageId])[1]/@with, '-', '')"/>Son [dir = none, weight = 50];
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:if>
                        </xsl:for-each>
                    </xsl:if>
                </xsl:for-each>
            </xsl:if>
        </xsl:for-each-group>
        }
    </xsl:template>
</xsl:stylesheet>