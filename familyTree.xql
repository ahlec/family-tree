declare function local:getMaleAncestor($ofPerson as node(), $generation as xs:integer) as node()
{
    let $maleAncestor := if ($generation = 0 or not($ofPerson/parents) or not($ofPerson/parents/father))
        then(<ancestor generation="{$generation}">{$ofPerson}</ancestor>)
        else(local:getMaleAncestor(doc('/db/genealogy/genealogy.xml')//person[@id eq $ofPerson/parents/father/@pointer], $generation - 1))
    return $maleAncestor
};
declare function local:getPersonName($pointer as xs:string, $document as node()*) as xs:string {
    let $target := $document//person[@id eq $pointer]
    let $name := string-join((
        $target//firstName,
        if ($target//epithet) then(" “", $target//epithet, "”") else "",
        if ($target//patronymic) then (" ", $target//patronymic) else "",
        if ($target//christian) then (" ", $target//christian) else "",
        if (not($target/@origin eq "unknown" or $target/@origin eq "Rus'")) then 
            (" of ", $target/@origin) else ""
        ), "")
    return $name
};
declare function local:getFamily($person as node(), $generationsDown as xs:integer, $generationsUp) as node()*
{
    let $doc := doc('/db/genealogy/genealogy.xml')
    let $self := <entry absoluteGeneration="{$generationsDown}"
        generation="{$generationsDown - $generationsUp}"
        origin="{data($person/@origin)}"
        gender="{if ($doc//marriage[@female eq $person/@id or @male eq $person/@id]) then($doc//marriage[@female eq $person/@id or @male eq $person/@id][1]/@*[name() = ('female', 'male') and data(.) eq $person/@id]/name()) else('undetermined')}"
        type="self">{data($person/@id)}</entry>
    let $marriages := doc('/db/genealogy/genealogy.xml')//marriage[@female eq $person/@id or @male eq $person/@id]
    let $spouseHandles := $marriages/@*[name() = ('female', 'male') and not(. eq $person/@id)]
    let $spouses := for $handle in $spouseHandles return <entry
        absoluteGeneration="{$generationsDown}"
        generation="{$generationsDown - $generationsUp}"
        gender="{if ($doc//marriage[@female eq $handle or @male eq $handle]) then($doc//marriage[@female eq $handle or @male eq $handle][1]/@*[name() = ('female', 'male') and data(.) eq $handle]/name()) else('undetermined')}"
        origin="{data($doc//person[@id eq $handle]/@origin)}"
        type="spouse"
        to="{data($person/@id)}"
        marriageId="{data($marriages[@female eq $handle or @male eq $handle]/@id)}">{data($handle)}</entry>
    let $children := if ($generationsDown > 0) then (for $child in $marriages/children/child
        return <entry absoluteGeneration="{$generationsDown - 1}"
            generation="{$generationsDown - 1 - $generationsUp}"
            type="child"
            gender="{if ($doc//marriage[@female eq $child/@pointer or @male eq $child/@pointer]) then($doc//marriage[@female eq $child/@pointer or @male eq $child/@pointer][1]/@*[name() = ('female', 'male') and data(.) eq $child/@pointer]/name()) else('undetermined')}"
            origin="{data($doc//person[@id eq $child/@pointer]/@origin)}"
            toA="{data($person/@id)}"
            toB="{data($child/ancestor-or-self::marriage/@*[name() = ('female', 'male') and not(. eq $person/@id)])}"
            marriageId="{data($child/ancestor-or-self::marriage/@id)}">{data($child/@pointer)}</entry>) else()
    let $childFamilies := if ($generationsDown > 0) then (for $child in $children
        return local:getFamily(doc('/db/genealogy/genealogy.xml')//person[@id eq data($child)], $generationsDown - 1, $generationsUp)) else()
    return ($self, $spouses, $children, $childFamilies)
};
declare function local:constructFamily($familyEntries as node()*) as node()*
{
    let $doc := doc('/db/genealogy/genealogy.xml')
    let $family := for $handle in distinct-values(data($familyEntries))
        return <entry generation="{($familyEntries[data(.) eq $handle])[1]/@generation}"
            name="{local:getPersonName($handle, $doc)}"
            gender="{($familyEntries[data(.) eq $handle])[1]/@gender}"
            origin="{($familyEntries[data(.) eq $handle])[1]/@origin}"
            absoluteGeneration="{($familyEntries[data(.) eq $handle])[1]/@absoluteGeneration}"
            handle="{$handle}">{
                (for $relation in $familyEntries[(data(.) eq $handle or @to eq $handle) and @type eq 'spouse']
            return <relation to="{if (data($relation/@to) = $handle) then(data($relation)) else(data($relation/@to))}"
                             type="{data($relation/@type)}"
                             marriageId="{data($relation/@marriageId)}"/>
            ),
                (for $relation in $familyEntries[data(.) eq $handle and @type eq 'child']
                return <relation to="{data($doc//marriage[@id = $relation/@marriageId]/@male)}" type="child"
                    with="{data($doc//marriage[@id = $relation/@marriageId]/@female)}"
                    marriageId="{data($relation/@marriageId)}"/>
            )}</entry>
    return $family
};
let $person := request:get-parameter("person","sviatoslav1")
let $generationsUp := number(request:get-parameter("hi", 1))
let $generationsDown := number(request:get-parameter("lo", 2))
let $doTransform := request:get-parameter("doTransform", "no")
let $current := doc('/db/genealogy/genealogy.xml')//person[@id eq $person]
let $startPoint := local:getMaleAncestor($current, $generationsUp)
let $generationsUp := if ($startPoint/@generation > 0) then ($generationsUp - $startPoint/@generation) else ($generationsUp)
let $familyTree := local:getFamily($startPoint/person, $generationsUp + $generationsDown, $generationsUp) (: generations up and down, plus the focus generation :)
let $familyTree := <family><generations up="{$generationsUp}" down="{$generationsDown}" />{(local:constructFamily($familyTree))}</family>
let $familyTree := if ($doTransform = "yes")
    then (transform:transform($familyTree, "xmldb:exist:///db/genealogy/xquery/familyTreeGraphviz.xsl", ()))
    else ($familyTree)
return $familyTree