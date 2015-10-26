module namespace xosm_rtj = "xosm_rtj";

import module namespace m = "rstar.Main";

declare function xosm_rtj:mbr($name,$element,$d)
{
let $document := db:open($name)
let $e := $document/osm/way[tag/@k="name" and tag/@v=$element]
return
      if (empty($e)) then
             let $e := $document/osm/node[tag/@k="name" and tag/@v=$element]
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
 
declare function xosm_rtj:ways($name)
{
let $document :=  db:open($name)
return
(for $value in distinct-values($document/osm/way/tag[@k="name"]/@v)
   let $street := xosm_rtj:getElementByName($name,$value)
      
return 
  <mbr name="{$street[1]/tag[@k="name"]/@v}" x="{min($street/node/@lon)}" y="{min($street/node/@lat)}" z="{max($street/node/@lon)}" t="{max($street/node/@lat)}">
  {$street}  
  </mbr>
)
};

declare function xosm_rtj:nodes($name)
{
let $document := db:open($name)
for $node in ($document/osm/node[tag/@k="name"]) 
return 
  <mbr name="{$node/tag[@k="name"]/@v}" x="{$node/@lon}" y="{$node/@lat}" z="{$node/@lon}" t="{$node/@lat}">
  <oneway>
   {$node}
   </oneway>
  </mbr>
};

declare function xosm_rtj:new_rtree($nw,$file,$blockLength,$cacheSize,$dimension)
{
let $rtree := m:rtree($file,$blockLength,$cacheSize,$dimension) 

let $loop := (for $i in 1 to count($nw)
              return m:insert($rtree,xs:string($i),
                xs:string($nw[$i]/@x),xs:string($nw[$i]/@y),
                xs:string($nw[$i]/@z),xs:string($nw[$i]/@t),$dimension)
)
return $rtree
};

declare function xosm_rtj:load_rtree($name,$cacheSize)
{
let $rtree := m:load_rtree($name,$cacheSize)  
return $rtree
};
 
declare function xosm_rtj:getLayerElement($nw,$rtree,$name,$street,$d)
{
let $ms := xosm_rtj:mbr($name,$street,$d)
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

declare function xosm_rtj:getLayerWays($name,$street,$d)
{
let $nw :=  xosm_rtj:ways($name)
let $rtree := xosm_rtj:new_rtree($nw,"rtree.txt","512","256","2")
return xosm_rtj:getLayerElement($nw,$rtree,$name,$street,$d)
};

declare function xosm_rtj:getLayerNodes($name,$street,$d)
{

let $nw := xosm_rtj:nodes($name)

let $rtree := xosm_rtj:new_rtree($nw,"rtree.txt","512","256","2")
return xosm_rtj:getLayerElement($nw,$rtree,$name,$street,$d)
};


declare function xosm_rtj:getLayerByName($name as xs:string,$street as xs:string,$distance as xs:float)
{
 (xosm_rtj:getLayerNodes($name,$street,$distance),xosm_rtj:getLayerWays($name,$street,$distance))
}; 

declare function xosm_rtj:getLayerByElement($name as xs:string,$oneway as node(),
 $distance as xs:float)
{
 let $nodes := xosm_rtj:getLayerNodes($name,data($oneway/@name),$distance), 
     $ways := xosm_rtj:getLayerWays($name,data($oneway/@name),$distance)
 return ($nodes,$ways)
};


declare function xosm_rtj:getElementByName($name as xs:string,$elementName as xs:string)
{
<oneway name = '{$elementName}'>
      {for $each in db:attribute($name,$elementName)/../..//tag[@k="name" and @v=$elementName]
      return $each/..}   
      { for $id in db:attribute($name,$elementName)/../..//nd/@ref 
      where $id/../..//tag[@k="name" and @v=$elementName] return
                                db:attribute($name, $id)/..[name()='node'] }                          
</oneway>
};

declare function xosm_rtj:getElementsByKeyword($name as xs:string, $keyword as xs:string)
{
for $each in db:attribute($name,$keyword)/../.. 
return  
 if ($each//tag[@k='name'])
              then xosm_rtj:getElementByName($name,$each//tag[@k='name']/@v)
              else xosm_rtj:getElementByName($name,$keyword) 
};