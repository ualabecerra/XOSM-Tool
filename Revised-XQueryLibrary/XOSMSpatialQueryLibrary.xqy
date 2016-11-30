module namespace xosm_sp = "xosm_sp";

import module namespace geo = "http://expath.org/ns/geo";

import module namespace xosm_gml = "xosm_gml" at "XOSM2GmlQueryLibrary.xqy";
import module namespace xosm_rld = "xosm_rld" at "XOSMIndexingLibrary.xqy";


declare namespace gml='http://www.opengis.net/gml';

(:                           Query Pattterns                                :)
(: ************************************************************************ :)

declare function xosm_sp:booleanQuery($oneway1 as node(), $oneway2 as node(), $functionName as xs:string)
{
  
  if (empty($oneway1) or empty($oneway2)) then false()
  else  
  let $mutliLineString1 := 
              if ($oneway1[@type="area"])
              then   xosm_gml:_osm2GmlPolygon($oneway1)
              else if ($oneway1[@type="way"]) then
              xosm_gml:_osm2GmlLine($oneway1)
              else xosm_gml:_osm2GmlPoint(($oneway1/node/@lat)[1],($oneway1/node/@lon)[1]),
      $multiLineString2 := 
      
              if ($oneway2[@type="area"])
              then   xosm_gml:_osm2GmlPolygon($oneway2)
              else if ($oneway2[@type="way"]) then
              xosm_gml:_osm2GmlLine($oneway2)
              else xosm_gml:_osm2GmlPoint(($oneway2/node/@lat)[1],($oneway2/node/@lon)[1])
              
  let $spatialFunction := fn:function-lookup(xs:QName($functionName),2)
  return
    $spatialFunction($mutliLineString1,$multiLineString2)
};
 
(:                           Spatial Operators                              :)
(: ************************************************************************ :)

(: Returns true whenever a point (i.e. $lat and $lon) is in a way :)

declare function xosm_sp:wayIn($point as node(), $oneway as node())
{
  if (empty($point) or empty($oneway)) then false()
  else
  if ($point/way) then false()
  else
  let $p := xosm_gml:_osm2GmlPoint($point/node/@lat,$point/node/@lon) 
  let $l := xosm_gml:_osm2GmlLine($oneway)
  return geo:distance($l,$p)=0
};

(: Returns the ways in which a point (i.e. $lat and $lon) is :)

declare function xosm_sp:WaysOfaPoint($node as node(), $document as node()*)
{
  if (empty($node)) then ()
  else
  for $oneway in $document 
  where $oneway/@type="way"
  return     
      if (xosm_sp:wayIn($node,$oneway)) then $oneway
      else () 
};

(: Returns true whenever node1 and node2 are in the same street :)

declare function xosm_sp:waySame($node1 as node(), $node2 as node(), $document as node()*)
{
  if (empty($node1) or empty($node2)) then false()
  else
  let
      $oneway1 := xosm_sp:WaysOfaPoint($node1,$document), 
      $oneway2 := xosm_sp:WaysOfaPoint($node2,$document)
  return     
   some $x in $oneway1 satisfies (some $y in $oneway2 satisfies
    (let $line1 := xosm_gml:_osm2GmlLine($x), 
         $line2 := xosm_gml:_osm2GmlLine($y)
    return geo:equals($line1,$line2))) 
};          

  (: RETURNS ALL THE INTERSECTION POINTS EVENTUALLY REPEATED:)
 
declare function xosm_sp:intersectionPoints($oneway1 as node(), $oneway2 as node())
{      
      if (empty($oneway1) or empty($oneway2)) then ()
      else
      if ($oneway1/@type="point" or $oneway2/@type="point") then ()
      else
      for $p1 in $oneway1/way/nd
             where (some $p2 in $oneway2/way/nd satisfies $oneway1/node[@id=$p1/@ref]/@lat =
              $oneway2/node[@id=$p2/@ref]/@lat
             and $oneway1/node[@id=$p1/@ref]/@lon = $oneway2/node[@id=$p2/@ref]/@lon)
             return <oneway type="point">{($oneway1/node[@id=$p1/@ref])[1]}</oneway>  
}; 
 
(: Returns true whenever a way crosses another one :)

declare function xosm_sp:crossing($oneway1 as node(), $oneway2 as node())
{
 xosm_sp:booleanQuery($oneway1,$oneway2,"geo:crosses")               
};

(: Returns true whenever a way is not crossing to another one :)

declare function xosm_sp:nonCrossing($oneway1 as node(), $oneway2 as node())
{
 not(xosm_sp:booleanQuery($oneway1,$oneway2,"geo:crosses"))  
};

(: Returns true whenever a way is touching to another one :)

declare function xosm_sp:touching($oneway1 as node(), $oneway2 as node())
{
 xosm_sp:booleanQuery($oneway1,$oneway2,"geo:touches")                
};

(: Returns true whenever a way is not touching to another one :)

declare function xosm_sp:nonTouching($oneway1 as node(), $oneway2 as node())
{
 not(xosm_sp:booleanQuery($oneway1,$oneway2,"geo:touches")) 
};

(: Returns true whenever a way is intersecting to another one :)

declare function xosm_sp:intersecting($oneway1 as node(), $oneway2 as node())
{
 xosm_sp:booleanQuery($oneway1,$oneway2,"geo:intersects")            
};

(: Returns true whenever a way is not intersecting to another one :)

declare function xosm_sp:nonIntersecting($oneway1 as node(), $oneway2 as node())
{
 not(xosm_sp:booleanQuery($oneway1,$oneway2,"geo:intersects")) 
};

(: Returns true whenever a way is containing to another one :)

declare function xosm_sp:containing($oneway1 as node(), $oneway2 as node())
{
 xosm_sp:booleanQuery($oneway1,$oneway2,"geo:contains")                
};

(: Returns true whenever a way is not containing to another one :)

declare function xosm_sp:nonContaining($oneway1 as node(), $oneway2 as node())
{
 not(xosm_sp:booleanQuery($oneway1,$oneway2,"geo:contains"))  
};

(: Returns true whenever a way is within another one :)

declare function xosm_sp:within($oneway1 as node(), $oneway2 as node())
{
 xosm_sp:booleanQuery($oneway1,$oneway2,"geo:within")               
};

(: Returns true whenever a way is not within to another one :)

declare function xosm_sp:nonWithin($oneway1 as node(), $oneway2 as node())
{
 not(xosm_sp:booleanQuery($oneway1,$oneway2,"geo:within"))  
};

(: Returns true whenever a way is overlapping another one :)

declare function xosm_sp:overlapping($oneway1 as node(), $oneway2 as node())
{
 xosm_sp:booleanQuery($oneway1,$oneway2,"geo:overlaps")               
};

(: Returns true whenever a way is not overlapping another one :)

declare function xosm_sp:nonOverlapping($oneway1 as node(), $oneway2 as node())
{
 not(xosm_sp:booleanQuery($oneway1,$oneway2,"geo:overlaps"))  
};

(: Function in order to determinate if second node is northernmost than first one. Using latitudes by considering points in noth and south hemispheres :)
           
declare function xosm_sp:furtherNorthPoints($oneway1 as node(), $oneway2 as node())
{
   if (empty($oneway1) or empty($oneway2)) then false() 
 else
  if (not ($oneway1/way or $oneway2/way)) then
  let $lat1 := $oneway1/node/@lat, $lat2 := $oneway2/node/@lat
  return
  (: Case 1:  both nodes in positive Ecuador hemisphere :)
    if ($lat1 > 0 and $lat2 > 0) then 
        if (($lat2 - $lat1) > 0) then true()
                                 else false() 
    else 
  (: Case 2: both nodes in negative Ecuador hemisphere :)  
      if ($lat1 < 0  and $lat2 < 0) then      
      if (((-$lat2) - (-$lat1)) < 0) then true()
                                      else false()
      else
  (: Case 3: First node in positive Ecuador hemisphere, Second node in negative Ecuador hemisphere:)
     if ($lat1 > 0 and $lat2 < 0) then false()
  (: Case 4: First node in negative Ecuador hemisphere, Second node in positive Ecuador hemisphere :)
                                 else true()
   else false()
};                              

(: Function in order to determinate if second node is further south than first one. furtherNorth negation :)

declare function xosm_sp:furtherSouthPoints($node1 as node(), $node2 as node())
{
  
 if (empty($node1) or empty($node2)) then false() 
 else
  if (not ($node1/way or $node2/way)) then
  not(xosm_sp:furtherNorthPoints($node1,$node2))
  else false()
};

(: Function in order to determinate if second node is further east than first node. Using latitudes by considering nodes in west and east hemispheres :)
           
declare function xosm_sp:furtherEastPoints($oneway1 as node(), $oneway2 as node())
{
 if (empty($oneway1) or empty($oneway2)) then false() 
 else
  if (not ($oneway1/way or $oneway2/way)) then
  let $lon1 := $oneway1/node/@lon, $lon2 := $oneway2/node/@lon
  return 
  (: Case 1:  both nodes in positive Greenwich meridian :)
    if ($lon1 > 0 and $lon2 > 0) then 
        if (($lon2 - $lon1) > 0) then true()
                                 else false() 
    else 
  (: Case 2: both nodes in negative Greenwich meridian :)  
      if ($lon1 < 0  and $lon2 < 0) then      
      if (((-$lon2) - (-$lon1)) < 0) then true()
                                      else false()
      else
  (: Case 3: First node in positive Greenwich meridian, Second node in negative Greenwich meridian :)
     if ($lon1 > 0 and $lon2 < 0) then false()
  (: Case 4: First node in negative Greenwich meridian, Second node in positive Greenwich meridian :)
                                  else true()                                  
   else false()
};                              

(: Function in order to determinate if second node is further weast than first node. furtherEast negation :)

declare function xosm_sp:furtherWestPoints($node1 as node(), $node2 as node())
{
   if (empty($node1) or empty($node2)) then false() 
 else
  if (not ($node1/way or $node2/way)) then
  not(xosm_sp:furtherEastPoints($node1,$node2))
  else false()
};

declare function xosm_sp:furtherNorthWays($oneway1 as node(), $oneway2 as node())
{
 if (empty($oneway1) or empty($oneway2)) then false() 
 else
  if ($oneway2/way) then
  (every $node1 in $oneway1/node 
   satisfies    
   (every $node2 in $oneway2/node satisfies (xosm_sp:furtherNorthPoints(<oneway type="point">{$node1}</oneway>,
   <oneway type="point">{$node2}</oneway>))))
  else false() 
};

declare function xosm_sp:furtherSouthWays($oneway1 as node(), $oneway2 as node())
{
 if ($oneway2/way) then 
(every $node1 in $oneway1/node 
   satisfies    
   (every $node2 in $oneway2/node satisfies (xosm_sp:furtherSouthPoints(<oneway type="point">{$node1}</oneway>,
   <oneway type="point">{$node2}</oneway>))))
 else false()
};

declare function xosm_sp:furtherEastWays($oneway1 as node(), $oneway2 as node())
{
   if (empty($oneway1) or empty($oneway2)) then false() 
 else
  if ($oneway2/way) then
  (every $node1 in $oneway1/node 
   satisfies    
   (every $node2 in $oneway2/node satisfies (xosm_sp:furtherEastPoints(<oneway type="point">{$node1}</oneway>,
   <oneway type="point">{$node2}</oneway>))))
  else false()
};

declare function xosm_sp:furtherWestWays($oneway1 as node(), $oneway2 as node())
{
 if (empty($oneway1) or empty($oneway2)) then false() 
 else  
 if ($oneway2/way) then
(every $node1 in $oneway1/node 
   satisfies    
   (every $node2 in $oneway2/node satisfies (xosm_sp:furtherWestPoints(<oneway type="point">{$node1}</oneway>,
   <oneway type="point">{$node2}</oneway>))))
  else false()
};

declare function xosm_sp:DWithIn($oneway1 as node(), $oneway2 as node(), $d as xs:float)
{
 let $distance := xosm_sp:getDistance($oneway1, $oneway2) 
 return  $distance <= $d 
};

declare function xosm_sp:centerOfBB($bbox1 as xs:decimal, $bbox2 as xs:decimal, $bbox3 as xs:decimal, $bbox4 as xs:decimal){
  <oneway name = 'centroide' type="point">
<node id = '-1' action = 'modify' visible = 'true' lat = '{($bbox2 + $bbox4) div 2}' lon = '{($bbox1 + $bbox3) div 2}'>
<tag k ='name' v = 'BoundingBoxCenter'/>
</node>
</oneway>
};

(: Returns true whenever a way is disjoint to another one :)

declare function xosm_sp:disjoint($oneway1 as node(), $oneway2 as node())
{
 xosm_sp:booleanQuery($oneway1,$oneway2,"geo:disjoint")                
};

(: Returns true whenever a way is not disjoint to another one :)

declare function xosm_sp:nonDisjoint($oneway1 as node(), $oneway2 as node())
{
 not(xosm_sp:booleanQuery($oneway1,$oneway2,"geo:disjoint")) 
};


declare function xosm_sp:getDistance($oneway1 as node(), $oneway2 as node())
{
    
  let $line1 := (if ($oneway1[@type="area"]) then 
  xosm_gml:_osm2GmlPolygon($oneway1)
  else if ($oneway1[@type="way"]) then
  xosm_gml:_osm2GmlLine($oneway1) else if ($oneway1[@type="point"]) then
   xosm_gml:_osm2GmlPoint($oneway1/node/@lat,$oneway1/node/@lon) else ())
  let $line2 :=  (if ($oneway2[@type="area"]) then 
  xosm_gml:_osm2GmlPolygon($oneway2)
  else if ($oneway2[@type="way"]) then
  xosm_gml:_osm2GmlLine($oneway2) else if
  ($oneway2[@type="point"]) then xosm_gml:_osm2GmlPoint($oneway2/node/@lat,$oneway2/node/@lon) else ())
  return (: if (not(empty($line1)) and not(empty($line2))) then :)
  geo:distance($line1,$line2)* ((math:pi() div 180) * 6378137) 
}; 

declare function xosm_sp:convex-hull($oneway as node())
{
  if ($oneway[@type="area"]) then 
  xosm_gml:_gml2OsmPolygon(geo:convex-hull(xosm_gml:_osm2GmlPolygon($oneway)))
  else if ($oneway[@type="way"]) then 
  xosm_gml:_gml2OsmPolygon(geo:convex-hull(xosm_gml:_osm2GmlLine($oneway)))
  else  xosm_gml:_gml2OsmPoint(geo:convex-hull(xosm_gml:_osm2GmlPoint($oneway/node/@lat,$oneway/node/@lon)))  
};

declare function xosm_sp:boundary($oneway as node())
{
  if ($oneway[@type="area"]) then 
  xosm_gml:_gml2OsmLine(geo:boundary(xosm_gml:_osm2GmlPolygon($oneway)))
  else if ($oneway[@type="way"]) then 
 xosm_gml:multipoint2Osm(geo:boundary(xosm_gml:_osm2GmlLine($oneway)))
  else ()  
};

declare function xosm_sp:buffer($oneway as node(),$distance)
{
  let $distance1 := xs:double($distance / ((math:pi() div 180) * 6378137))
  return 
  if ($oneway[@type="area"]) then 
  xosm_gml:_gml2OsmPolygon(geo:buffer(xosm_gml:_osm2GmlPolygon($oneway),$distance1))
  else if  ($oneway[@type="way"]) then
 xosm_gml:_gml2OsmPolygon(geo:buffer(xosm_gml:_osm2GmlLine($oneway),$distance1))
  else  xosm_gml:_gml2OsmPolygon(geo:buffer(xosm_gml:_osm2GmlPoint($oneway/node/@lat,$oneway/node/@lon),$distance1))  
};


declare function xosm_sp:path($layer,$name1,$name2,$distance,$dlayer)
{
  if ($name1=$name2) then <a>{"You are already here"}</a>/text()
  else
  let $e1 := xosm_rld:getElementByName($layer,$name1)
  let $e2 := xosm_rld:getElementByName($layer,$name2)
  return
  if (empty($e1)) then <a>{concat(concat("The street ",$name1)," is out of this layer")}</a>/text()
  else if (empty($e2)) then <a>{concat(concat("The street ",$name2)," is out of this layer")}</a>/text()
  else
  let $layere1 := xosm_rld:getLayerByName($layer,$name1,$dlayer)[@type="way"]
  return 
  xosm_sp:write_path(xosm_sp:path_aux($layere1,$e1,$e2,$distance,$e1))/text()
};

declare function xosm_sp:path_aux($layer,$e1,$e2,$distance,$path)
{
  
  if (empty($layer)) then ()
  else  
  if (xosm_sp:getDistance($e1,$e2) <= $distance) 
  then ($path,$e2)
  else let $can := filter($layer,xosm_sp:DWithIn(?,$e1,$distance))
       return xosm_sp:loop_path($can,$layer,$e2,$distance,$path)          
};

declare function xosm_sp:write_path($path)
{
 if (empty($path)) then <a>"No ways are possible"</a>
 else 
  let $count := count($path)
  let $last := $path[$count]
  return
  <a>
  {
  for $i in 1 to $count  return 
  concat(
  (if ($i>1) then
  if (xosm_sp:furtherNorthWays($path[$i -1],$path[$i])) then 
  "follow to the north and "
  else if (xosm_sp:furtherSouthWays($path[$i -1],$path[$i])) then
  "follow to the south and "
  else if (xosm_sp:furtherWestWays($path[$i -1],$path[$i])) then
  "follow to the west and "
  else
  "follow to the east and "
  else ""),
  if ($path[$i]/@name=$last/@name) then concat("you get the destination in ",$path[$i]/@name)
  else concat(concat(concat("take ",$path[$i]/@name),"&#10;")," and after"))}
  </a>
};

declare function xosm_sp:loop_path($can,$layer,$e2,$distance,$path)
{
  if (empty($can)) then ()
  else
  let $c := head($can)
       let $p := xosm_sp:path_aux($layer[every $name in data(($path,$c)/@name) satisfies not($name=data(@name))],$c,$e2,$distance,($path,$c))
       return if  (empty($p))
       then xosm_sp:loop_path(tail($can),$layer,$e2,$distance,$path)
       else $p
};