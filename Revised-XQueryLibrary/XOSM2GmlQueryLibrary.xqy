module namespace xosm_gml = "xosm_gml";

import module namespace geo = "http://expath.org/ns/geo";

declare namespace gml='http://www.opengis.net/gml';

(: Auxiliary Functions in order to transform OSM geometry into GML geometry :)
(: ************************************************************************ :)


declare function xosm_gml:multipoint2Osm($multi)
{
  let $points := $multi/gml:MultiPoint/gml:pointMember/gml:Point/gml:coordinates
  let $count := count($points)
  return
  <oneway type="area">
  <way version="1" visible='true'>
  {
  
  (for $c in 1 to $count
  return
  <nd ref="{$c}"/>)
  }
  </way>
  {
  for $c in 1 to $count
  return
  <node id="{$c}" lat="{tokenize($points[$c]/text(),',')[1]}" lon ="{tokenize($points[$c]/text(),',')[2]}"/>
  }
  </oneway>
};

declare function xosm_gml:_gml2OsmPolygon($polygon)
{
let $tokens := tokenize(replace($polygon/gml:Polygon/gml:outerBoundaryIs/gml:LinearRing/gml:coordinates/text(),"&#xA;",""),' ')
 let $tok := count($tokens)
 return
 <oneway type="area"><way version="1" visible='true'>
 {
 (for $i in 1 to $tok
  where not($tokens[$i]="") 
 return
 <nd ref="{$i}"/>)
}</way>
{
for $i in 1 to $tok
 where not($tokens[$i]="")  
 return
 <node id="{$i}" lat="{tokenize($tokens[$i],',')[1]}" lon="{tokenize($tokens[$i],',')[2]}"/>
}
</oneway>
};

declare function xosm_gml:_gml2OsmLine($line)
{
 let $tokens := tokenize(replace($line/gml:LineString/gml:coordinates/text(),"&#xA;",""),' ')
 let $tok := count($tokens)
 return
 <oneway type="way"><way version="1" visible='true'>
 {
 (for $i in 1 to $tok
  where not($tokens[$i]="") 
 return
 <nd ref="{$i}"/>)
}
 </way>
 {for $i in 1 to $tok
 where not($tokens[$i]="") 
 return
 <node id="{$i}" lat="{tokenize($tokens[$i],',')[1]}" lon="{tokenize($tokens[$i],',')[2]}"/>

}
 </oneway>
};

declare function xosm_gml:_gml2OsmPoint($point)
{
 let $tokens := tokenize($point/gml:Point/gml:coordinates/text(),',')

 return
 <oneway type="point">
 <node version="1" visible='true' lat="{$tokens[1]}" lon="{$tokens[2]}"/>
 </oneway>
};

(: Conversor from OSM to GML for Polygons :)

declare function xosm_gml:_osm2GmlPolygon($oneway as node())
{
  (: if ($oneway/way) then :)
  if (($oneway/node/@id)[1]=($oneway/node/@id)[last()])
  then
  
  <gml:Polygon>
  <gml:LinearRing>
  <gml:coordinates>
  {
   for $node in $oneway/node
   return 
   (concat(concat(data($node/@lat),','),data($node/@lon))) 
  } 
  </gml:coordinates>
  </gml:LinearRing>
  </gml:Polygon> 
  
  else xosm_gml:_osm2GmlLine($oneway)
};

(: Conversor from OSM to GML for Lines :)

declare function xosm_gml:_osm2GmlLine($oneway as node())
{
  
     if ($oneway/way) then
     
       <gml:MultiLineString>
      {
      <gml:LineString>
      <gml:coordinates>
      {
       for $node in $oneway/node
       return 
         (concat(concat(data($node/@lat),','),data($node/@lon))) 
      } 
      </gml:coordinates>
      </gml:LineString>
      }
    </gml:MultiLineString> 
    
    else xosm_gml:_osm2GmlPoint($oneway/node/@lat,$oneway/node/@lon)    
};

(: Conversor from OSM to GML for Points :)

declare function xosm_gml:_osm2GmlPoint($lat as xs:decimal, $lon as xs:decimal)
{
  <gml:Point>
  <gml:coordinates>
  {
  (concat(concat(data($lat),','),data($lon)))
  }
  </gml:coordinates>
  </gml:Point>  
};

declare function xosm_gml:_result2Osm($document)
{
 if ($document instance of xs:string) then
    $document 
 else
  if ($document instance of xs:double) then $document 
  else

 if ($document[1][name(.) = 'oneway'])
 then 
 <osm version='0.6' upload='true' generator='JOSM'>
 {
  let $document1 := $document
  return 
   if (exists($document1[name(.) = 'osm']))
    then ($document[name(.) = 'node']) union (($document//way) union ($document//node)) 
    else  ($document//way)  union ($document//node) 
 }
 </osm> 
 else if ($document[1][name(.) = 'node']) 
      then <osm version='0.6' upload='true' generator='JOSM'>
      { $document }
           </osm> 
      else "No Result"  
};

declare function xosm_gml:_result2Oneway($document)
{
  if ($document instance of xs:string) then
    $document 
 else
  if ($document instance of xs:double) then $document 
  else
 if ($document[1][name(.) = 'oneway'])
 then 
 <xosm>
 {
  $document
 }
 </xosm> 
 else if (empty($document)) then "No Result" else  if ($document[1][name(.) = 'node']) 
      then <xosm><oneway name = '{if ($document[1]//tag[@k = "name"]/@v) then $document[1]//tag[@k = "name"]/@v else "" }'
       type = 'point'>
      { $document }
      </oneway>
      </xosm> 
      else "No Result"
};

declare function xosm_gml:_osm2Oneway($document as node()*){
for $x in $document/*[not(name(.)="relation") and tag/@k="name"]
let $y := $x/tag[@k="name"]/@v
group by $y

return
if ($x/tag/@k="highway" and $x/nd) then
<oneway name="{$y[1]}" type="way">
{$x union
(for $nd in $x/nd
return ($document/*[@id=$nd/@ref])[1])
}</oneway>
 else 
if (not($x/tag/@k="highway") and $x/nd)
then
<oneway name="{$y}" type="{if  (($x/nd/@ref)[1]=($x/nd/@ref)[last()]) then "area" else "way"}"> 
{$x union
((for $nd in $x/nd
return ($document/*[@id=$nd/@ref])[1]),
<a>{
(if (($x/nd/@ref)[1]=($x/nd/@ref)[last()]) then 
($document/*[@id=($x/nd/@ref)[last()]])[1] else ())
}</a>/*
)
}
</oneway>
else
if (empty($x)) then ()
else
<oneway name="{$y}" type="point">{$x[1]}</oneway>
 
};