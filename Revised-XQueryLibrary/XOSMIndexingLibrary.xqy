module namespace xosm_rld = "xosm_rld";

import module namespace m = "rstar.Main";

import module namespace xosm_gml = 'xosm_gml' at '../repo/XOSM2GmlQueryLibrary.xqy';
import module namespace xosm_sp = 'xosm_sp' at '../repo/XOSMSpatialQueryLibrary.xqy';

declare function xosm_rld:mbr($name,$element,$d)
{
let $document := db:open($name)
let $e := $document/osm/way[tag/@k="name" and tag/@v=$element]
return
      if (empty($e)) then
             let $e := ($document/osm/node[tag/@k="name" and tag/@v=$element])[1] 
             return 
             if (empty($e)) then ()
             else
             <mbr name="{$e/tag[@k="name"]/@v}" x="{$e/@lon - $d}" y="{$e/@lat - $d}" z="{$e/@lon + $d}" t="{$e/@lat + $d}"/>
      else
      let $node := for $each in $e/nd return $document/osm/node[@id=$each/@ref]
      return
      <mbr name="{$e/tag[@k="name"]/@v}" 
              x="{min($node/@lon) - $d}" y="{min($node/@lat) - $d}" z="{max($node/@lon) + $d}" t="{max($node/@lat) + $d}"/>
};
 
declare function xosm_rld:ways($name)
{
let $document :=  db:open($name)
return
(for $value in distinct-values($document/osm/way/tag[@k="name"]/@v)
   let $street := xosm_rld:getElementByName($name,$value)      
return 
  <mbr name="{$street[1]/tag[@k="name"]/@v}" x="{min($street/node/@lon)}" y="{min($street/node/@lat)}" z="{max($street/node/@lon)}" t="{max($street/node/@lat)}">
  {$street}  
  </mbr>
)
};

declare function xosm_rld:nodes($name)
{
let $document := db:open($name)
for $node in ($document/osm/node[tag/@k="name"]) 
return 
  <mbr name="{$node/tag[@k="name"]/@v}" x="{$node/@lon}" y="{$node/@lat}" z="{$node/@lon}" t="{$node/@lat}">
  <oneway name="{$node/tag[@k="name"]/@v}" type="point">
   {$node}
   </oneway>
  </mbr>
};

declare function xosm_rld:new_rtree($nw,$file,$blockLength,$cacheSize,$dimension)
{
let $rtree := m:rtree($file,$blockLength,$cacheSize,$dimension) 

let $loop := (for $i in 1 to count($nw)
              return m:insert($rtree,xs:string($i),
                xs:string($nw[$i]/@x),xs:string($nw[$i]/@y),
                xs:string($nw[$i]/@z),xs:string($nw[$i]/@t),$dimension)
)
return $rtree
};

declare function xosm_rld:load_rtree($name,$cacheSize)
{
let $rtree := m:load_rtree($name,$cacheSize)  
return $rtree
};
 
declare function xosm_rld:getLayerElement($nw,$rtree,$name,$street,$d)
{
let $ms := xosm_rld:mbr($name,$street,$d)
return
if (empty($ms)) then ()
else
let $layer := m:getLayer($rtree,data($ms/@x),data($ms/@y),data($ms/@z),data($ms/@t))
let $delete := m:remove($rtree)  
let $num := m:get_num($layer)
let $ids := m:get_ids($layer)
for $i in 1 to $num
return $nw[position()=xs:integer($ids[$i])]/*
};

declare function xosm_rld:getLayerWays($name,$street,$d)
{
let $nw :=  xosm_rld:ways($name)
let $rtree := xosm_rld:new_rtree($nw,"rtree.txt","512","256","2")
return xosm_rld:getLayerElement($nw,$rtree,$name,$street,$d)
};

declare function xosm_rld:getLayerNodes($name,$street,$d)
{
let $nw := xosm_rld:nodes($name)
let $rtree := xosm_rld:new_rtree($nw,"rtree.txt","512","256","2")
return xosm_rld:getLayerElement($nw,$rtree,$name,$street,$d)
};

declare function xosm_rld:getLayerByName($name as xs:string,$street as xs:string,$distance as xs:float)
{
 (xosm_rld:getLayerNodes($name,$street,$distance div  ((math:pi() div 180) * 6378137)),xosm_rld:getLayerWays($name,$street,($distance div ((math:pi() div 180) * 6378137))))
}; 


declare function xosm_rld:getLayerByElement($name as xs:string,$oneway as node(),
 $distance as xs:float)
{
 let $nodes := xosm_rld:getLayerNodes($name,data($oneway/@name),$distance div ((math:pi() div 180) * 6378137)), 
     $ways := xosm_rld:getLayerWays($name,data($oneway/@name),$distance div ((math:pi() div 180) * 6378137))
 return ($nodes,$ways)
};

declare function xosm_rld:getElementByName($name as xs:string,$elementName as xs:string)
{ 
if (db:attribute($name,$elementName)/..[@k="name" and @v=$elementName]/..[tag/@k="highway" and nd])
then
<oneway name = '{$elementName}' type="way">
      {
      for $each in db:attribute($name,$elementName)/..[@k="name" and @v=$elementName]/..[tag/@k="highway" and nd]
      return ($each,  
      for $id in $each/nd/@ref
       return db:attribute($name, $id)/..[name()='node'])
     }                        
</oneway>
else
if (db:attribute($name,$elementName)/..[@k="name" and @v=$elementName]/..[not(tag/@k="highway") and nd])
then
for $each in db:attribute($name,$elementName)/..[@k="name" and @v=$elementName]/..[not(tag/@k="highway") and nd]return
<oneway name = '{$elementName}' type="{if ($each/nd/@ref[1]=$each/nd/@ref[last()]) then "area" else "way"}">
{$each}
 { for $id in  $each/nd/@ref 
      return db:attribute($name, $id)/..[name()='node'] } 
</oneway>
else 
if (empty(db:attribute($name,$elementName)/..[@k="name" and @v=$elementName]/..)) then ()
else
<oneway name = '{$elementName}' type="point">
{db:attribute($name,$elementName)/..[@k="name" and @v=$elementName]/..}
</oneway>
};
                              
declare function xosm_rld:getElementsByKeyword($name as xs:string, $keyword as xs:string)
{
for $each in db:attribute($name,$keyword)/../..
return  
 if ($each/tag[@k='name'])
              then xosm_rld:getElementByName($name,$each/tag[@k='name']/@v)
              else xosm_rld:getElementByName($name,$keyword) 
}; 

declare function xosm_rld:getLayerByBB($name as xs:string)
{
 xosm_gml:_osm2Oneway(db:open($name)/*)
};

declare function xosm_rld:getCenterFromBB($bbox1 as xs:decimal, $bbox2 as xs:decimal, 
   $bbox3 as xs:decimal, $bbox4 as xs:decimal){
   xosm_sp:centerOfBB($bbox1,$bbox2,$bbox3,$bbox4)
};