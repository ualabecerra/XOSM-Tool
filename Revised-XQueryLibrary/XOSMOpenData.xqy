module namespace xosm_open = "xosm_open";

import module namespace xosm_rld = "xosm_rld" at "XOSMIndexingLibrary.xqy";

declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace rdfs="http://www.w3.org/2000/01/rdf-schema#";
declare namespace owl="http://www.w3.org/2002/07/owl#";
declare namespace dct="http://purl.org/dc/terms/";
declare namespace dbo="http://dbpedia.org/ontology/";
declare namespace geo="http://www.w3.org/2003/01/geo/wgs84_pos#";
declare namespace foaf="http://xmlns.com/foaf/0.1/";
declare namespace prov="http://www.w3.org/ns/prov#";
declare namespace georss="http://www.georss.org/georss/";

declare function xosm_open:map($a,$b)
{
  if ($a >= $b) then $a * $a + $a + $b 
  else $a + $b * $b
};


declare function xosm_open:json($url,$name,$key1,$value1,$key2,$value2)
{
let $text := fetch:text($url)
let $json := json:parse($text)
return
(: <osm version='0.6' upload='true' generator='JOSM'>
{ :)
let $features :=$json/json/features/_
for $i in 1 to count($features)
return

if ($features[$i]/geometry/type="Point") then
<oneway name="{{$features[$i]/properties/*[name(.)=$name]/text()}}" type="point">
<node version="{$i}" visible='true' id="{$i}" 
  lat="{($features[$i]/geometry/coordinates/_)[2]}" 
  lon="{($features[$i]/geometry/coordinates/_)[1]}">
{
(for $p in  $features[$i]/properties/*
return
<tag k='{name($p)}' v='{$p/text()}' />)
union
<tag k="name" v="{$features[$i]/properties/*[name(.)=$name]/text()}"/>
union
<tag k="{$key1}" v="{$value1}" />
}
</node>
</oneway>
else 

 if ($features[$i]/geometry/type="LineString") then
<oneway name="{$features[$i]/properties/*[name(.)=$name]/text()}" type="way">
{
( let $count := count($features[$i]/geometry/coordinates/_)
  for $j in  1 to $count return
  
  <node version="{$i}" id="{xosm_open:map($i,$j)}" visible='true' 
    lat="{(($features[$i]/geometry/coordinates/_)[$j]/_)[2]}" 
    lon="{(($features[$i]/geometry/coordinates/_)[$j]/_)[1]}"/>
),
 <node version="{$i}" id="{xosm_open:map($i,1)}" visible='true' 
    lat="{(($features[$i]/geometry/coordinates/_)[1]/_)[2]}" 
    lon="{(($features[$i]/geometry/coordinates/_)[1]/_)[1]}"/>
  union
  <way version="{$i}" visible='true' id="{$i}">
  {
    (let $count := count($features[$i]/geometry/coordinates/_)
      for $j in  1 to $count return
      <nd version="{$i}" ref='{xosm_open:map($i,$j)}'/>)
      union
      (for $p in  $features[$i]/properties/*
      return
      <tag k='{name($p)}' v='{$p/text()}' />)
      union
      <tag k="name" v="{$features[$i]/properties/*[name(.)=$name]/text()}"/>
      union
      <tag k="{$key2}" v="{$value2}" />
}
</way>
}
</oneway>
else

 if ($features[$i]/geometry/type="Polygon") then
 <oneway name="{$features[$i]/properties/*[name(.)=$name]/text()}" type="area">
 {
    (let $count := count($features[$i]/geometry/coordinates/_/_)
      for $j in  1 to $count - 1 return
      <node version="{$i}" id="{xosm_open:map($i,$j)}" visible='true' 
        lat="{(($features[$i]/geometry/coordinates/_/_)[$j]/_)[2]}" 
        lon="{(($features[$i]/geometry/coordinates/_/_)[$j]/_)[1]}"/>),  
        
     <node version="{$i}" id="{xosm_open:map($i,1)}" visible='true' 
        lat="{(($features[$i]/geometry/coordinates/_/_)[1]/_)[2]}" 
        lon="{(($features[$i]/geometry/coordinates/_/_)[1]/_)[1]}"/>
     
        union
        <way version="{$i}" visible='true' id="{$i}" >
          {
          (let $count := count($features[$i]/geometry/coordinates/_/_)
           for $j in  1 to $count - 1 return
              <nd version="{$i}" ref='{xosm_open:map($i,$j)}'/>)
              ,
              <nd version="{$i}" ref='{xosm_open:map($i,1)}'/>
              union
              (for $p in  $features[$i]/properties/*
              return
              
              <tag k='{name($p)}' v='{$p/text()}' />)
              union
              <tag k="name" v="{$features[$i]/properties/*[name(.)=$name]/text()}"/>
              union
              <tag k="area" v="yes"/>
              union
              <tag k="{$key2}" v="{$value2}" />
              }
            </way>
}</oneway>
else ()
};

declare function xosm_open:kml($url,$name,$key1,$value1,$key2,$value2)
{
let $kml := doc($url)
return
(:
<osm version='0.6' upload='true' generator='JOSM'>
{:)
    let $pm := $kml//*[name(.)="Placemark"]
    let $pc := count($pm)
        for $i in 1 to $pc
        return
          if ($pm[$i]/*[name(.)="Point"]) then
            let $tok := tokenize($pm[$i]/*[name(.)="Point"]/*[name(.)="coordinates"],',')
            return
            <oneway name="{$pm[$i]/*[name(.)="ExtendedData"]/*[name(.)="SchemaData"]/*[name(.)="SimpleData" and @name=$name]/text()}" type="point">
            <node version="{$i}" visible='true' id="{$i}" 
                lat="{$tok[2]}" 
                lon="{$tok[1]}">
            {
            (for $p in  $pm[$i]/*[name(.)="ExtendedData"]/*[name(.)="SchemaData"]/*[name(.)="SimpleData"]
              return
              <tag k='{$p/@name}' v='{$p/text()}' />)
              union
              <tag k="name" v="{$pm[$i]/*[name(.)="ExtendedData"]/*[name(.)="SchemaData"]/*[name(.)="SimpleData" and @name=$name]/text()}"/>
              union
              <tag k="{$key1}" v="{$value1}" />
             }
            </node>
            </oneway>
            else 
              if ($pm[$i]/*[name(.)="LineString"]) then
              <oneway name="{$pm[$i]/*[name(.)="ExtendedData"]/*[name(.)="SchemaData"]/*[name(.)="SimpleData" and @name=$name]/text()}" type="way">{
              (let $tok := tokenize($pm[$i]/*[name(.)="LineString"]/*[name(.)="coordinates"],' ')
              let $npoints := count($tok)
              return
              for $j in 1 to $npoints
              let $point := tokenize($tok[$j],',')
              return
              <node version="{$i}" visible='true' id="{xosm_open:map($i,$j)}" 
                lat="{$point[2]}" 
                lon="{$point[1]}"/>),
              (let $tok := tokenize($pm[$i]/*[name(.)="LineString"]/*[name(.)="coordinates"],' ')  
              let $point := tokenize($tok[1],',')
              return
              <node version="{$i}" visible='true' id="{xosm_open:map($i,1)}" 
                lat="{$point[2]}" 
                lon="{$point[1]}"/>)
               
              union
              <way version="{$i}" visible='true' id="{$i}"> 
                {
                    (for $p in  $pm[$i]/*[name(.)="ExtendedData"]/*[name(.)=
                    "SchemaData"]/*[name(.)="SimpleData"]
                    return
                    <tag k='{$p/@name}' v='{$p/text()}' />)
                    
                    union
                    <tag k="name" v="{$pm[$i]/*[name(.)="ExtendedData"]/*[name(.)="SchemaData"]/*[name(.)="SimpleData" and @name=$name]/text()}"/>
                    union
                    <tag k="{$key1}" v="{$value1}" />
                    union
                    (let $tok := tokenize($pm[$i]/*[name(.)="LineString"]/*[name(.)="coordinates"],' ')
                     let $npoints :=count($tok)
                     for $j in 1 to $npoints
                     return
                     <nd version="{$i}" ref="{xosm_open:map($i,$j)}"/>)
                     
                     }
                    </way>}</oneway>
else 
      if ($pm[$i]/*[name(.)="Polygon"]) then
      <oneway name="{$pm[$i]/*[name(.)="ExtendedData"]/*[name(.)="SchemaData"]/*[name(.)="SimpleData" and @name=$name]/text()}" type="area">{
      (let $tok := tokenize($pm[$i]/*[name(.)="Polygon"]/*[name(.)=
      "outerBoundaryIs"]/*[name(.)="LinearRing"]/*[name(.)="coordinates"],' ')
              let $npoints := count($tok)
              return
              for $j in 1 to $npoints - 1
              let $point := tokenize($tok[$j],',')
              return
              <node version="{$i}" visible='true' id="{xosm_open:map($i,$j)}" 
                lat="{$point[2]}" 
                lon="{$point[1]}"/>),
              (let $tok := tokenize($pm[$i]/*[name(.)="Polygon"]/*[name(.)=
      "outerBoundaryIs"]/*[name(.)="LinearRing"]/*[name(.)="coordinates"],' ')
       let $point := tokenize($tok[1],',')
       return
      <node version="{$i}" visible='true' id="{xosm_open:map($i,1)}" 
                lat="{$point[2]}" 
                lon="{$point[1]}"/>)
              union
              <way version="{$i}" visible='true' id="{$i}"> 
                {
                    (for $p in  
                    $pm[$i]/*[name(.)="ExtendedData"]/*[name(.)="SchemaData"]/*[name(.)="SimpleData"]
                    return
                    <tag k='{$p/@name}' v='{$p/text()}' />)
                    union
                    <tag k="name" v="{$pm[$i]/*[name(.)="ExtendedData"]/*[name(.)="SchemaData"]/*[name(.)="SimpleData" and @name=$name]/text()}"/>
                    union
                    <tag k="area" v="yes"/>
                    union
                    <tag k="{$key1}" v="{$value1}" />
                    union
                    (let $tok := tokenize($pm[$i]/*[name(.)="Polygon"]/*[name(.)=
                          "outerBoundaryIs"]/*[name(.)="LinearRing"]/*[name(.)="coordinates"],' ')
                     let $npoints := count($tok)
                     for $j in 1 to $npoints - 1
                     return
                     <nd version="{$i}" ref="{xosm_open:map($i,$j)}"/>),
                     <nd version="{$i}" ref="{xosm_open:map($i,1)}"/>
                     }
                    </way>
    }</oneway>
else () 
};

declare function xosm_open:csv($file,$name,$lat,$lon)
{
let $text := fetch:text($file)
let $csv := csv:parse($text, map { 'header': true() })

let $count := count($csv/csv/record)
for $rec in 1 to $count
let $reca := $csv/csv/record[$rec]
return
<oneway name="{$reca/*[name(.)=$name]/text()}" type="point">
<node id="{$rec}" version="1" visible='true' lat="{$reca/*[name(.)=$lat]/text()}" 
lon="{$reca/*[name(.)=$lon]/text()}">
{
  <tag k="name" v="{$reca/*[name(.)=$name]/text()}"/>,
  (for $t in $reca/*
  return
  <tag k="{name($t)}" v="{$t/text()}"   />) 
}
</node>
</oneway>

};

declare function xosm_open:wiki_element($node)
{
  if ($node/way) then 
  xosm_open:dbpedia(($node/node)[1]/@lat,($node/node)[1]/@lon)
  else
  xosm_open:dbpedia($node/node/@lat,$node/node/@lon)
};

declare function xosm_open:wiki_coordinates($lon,$lat)
{
  xosm_open:dbpedia($lon,$lat)
};

declare function xosm_open:wiki_name($spatialIndex,$name)
{
  let  $s1 :=  xosm_rld:getElementByName ($spatialIndex, $name)
return xosm_open:dbpedia(($s1/node)[1]/@lat,($s1/node)[1]/@lon)
};

declare function xosm_open:rdf_osm($rdf)
{
  for $des in $rdf//rdf:Description[some $x in * satisfies name($x)="dbo:wikiPageID"]
  return 
   <oneway name="{($des/*[name(.)="rdfs:label"])[1]/text()}" type="point">
  <node version='1' upload='true' generator='JOSM' id="{$des/*[name(.)="dbo:wikiPageID"]/text()}" lat="{$des/*[name(.)="geo:lat"]/text()}" 
  lon="{$des/*[name(.)="geo:long"]/text()}">
  {
  
  <tag k="place" v="*"/>,
  <tag k="name" v="{($des/*[name(.)="rdfs:label"])[1]/text()}"/>,
  for $p in $des/* return
  if ($p/@rdf:resource) then
  <tag k="{name($p)}" v="{data($p/@rdf:resource)}"/>
  else
  <tag k="{name($p)}" v="{$p/text()}"/>
  
}
  </node>
  </oneway>
};

declare function xosm_open:dbpedia($lat,$lon)
{
let $url := concat(concat(concat(concat(
  "http://api.geonames.org/findNearbyWikipedia?lat=",$lat),"&amp;lng="),$lon),"&amp;username=myapp")
return
for $wp in  doc($url)/geonames/entry/wikipediaUrl
let $st := concat(concat("http://dbpedia.org/data/",substring-after($wp,"http://en.wikipedia.org/wiki/")),".rdf")
return xosm_open:rdf_osm(doc($st))
};

declare function xosm_open:tixik_coordinates($lat,$lon)
{
  let $doc := doc(concat(concat(concat(concat("http://www.tixik.com/api/nearby?lat=",$lat),"&amp;lng="),$lon),"&amp;limit=50&amp;key=demo"))
  for $item in $doc/*[name(.)="tixik"]/*[name(.)="items"]/*[name(.)="item"]
  return 
  
  <oneway name="{$item/name/text()}" type="point">
  <node version='1' upload='true' generator='JOSM' id="{$item/id/text()}" lat="{$item/gps_x/text()}"
  lon= "{$item/gps_y/text()}">
  <tag k="name" v="{$item/name/text()}"/>
  </node>
  </oneway>  
};

declare function xosm_open:tixik_name($spatialIndex,$name)
{
  let  $s1 :=  xosm_rld:getElementByName ($spatialIndex, $name)
return xosm_open:tixik_coordinates(($s1/node)[1]/@lat,($s1/node)[1]/@lon)
};

declare function xosm_open:tixik_element($node)
{
  if ($node/way) then 
  xosm_open:tixik_coordinates(($node/node)[1]/@lat,($node/node)[1]/@lon)
  else
  xosm_open:tixik_coordinates($node/node/@lat,$node/node/@lon)
};