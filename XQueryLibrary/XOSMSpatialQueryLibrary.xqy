module namespace xosm_sp = "xosm_sp";

import module namespace geo = "http://expath.org/ns/geo";

import module namespace xosm_gml = "xosm_gml" at "XOSM2GmlQueryLibrary.xqy";

declare namespace gml='http://www.opengis.net/gml';

(:                           Query Pattterns                                :)
(: ************************************************************************ :)


declare function xosm_sp:booleanQuery($oneway1 as node(), $oneway2 as node(), $functionName as xs:string)
{
  let $mutliLineString1 := xosm_gml:_osm2GmlLine($oneway1), 
      $multiLineString2 := xosm_gml:_osm2GmlLine($oneway2)    
  let $spatialFunction := fn:function-lookup(xs:QName($functionName),2)
  return
    $spatialFunction($mutliLineString1,$multiLineString2)
};

declare function xosm_sp:unionQueryPattern($oneway as node(), $document as node()*, $operatorCollection as xs:string*)
{
   for $operatorValue in $operatorCollection
      let $spatialFunction := fn:function-lookup(xs:QName($operatorValue),2)
      return $spatialFunction($oneway,$document)
};

declare function xosm_sp:unionQuery($onewayResult1 as node()*, $onewayResult2 as node()*)
{
  $onewayResult1 union $onewayResult2
};

declare function xosm_sp:intersectionQuery($onewayResult1 as node()*, 
        $onewayResult2 as node()*)
{
 for $oneway in $onewayResult1
    let $name := $oneway/@name
    return
        for $oneway2 in $onewayResult2
        return
            if ($oneway2/@name = $name)
            then $oneway2
            else ()
 
(: intersect $onewayResult2 :)
};

declare function xosm_sp:exceptQuery($onewayResult1 as node()*, $onewayResult2 as node()*)
{
 $onewayResult1 except $onewayResult2
};

(:                           Spatial Operators                              :)
(: ************************************************************************ :)

(: Returns true whenever a point (i.e. $lat and $lon) is in a way :)

declare function xosm_sp:inWay($oneway-point as node(), $oneway as node())
{
  let $lat := $oneway-point/node/@lat, $lon := $oneway-point/node/@lon
  let $point := xosm_gml:_osm2GmlPoint($lat,$lon), $line := xosm_gml:_osm2GmlLine($oneway)
  return geo:contains($line,$point)
};

(: Returns the ways in which a point (i.e. $lat and $lon) is :)

declare function xosm_sp:WaysOfaPoint($node as node(), $document as node()*)
{
  let $lat := $node/@lat, $lon := $node/@lon
  let $point := xosm_gml:_osm2GmlPoint($lat,$lon) 
  for $oneway in $document//oneway
  return
     let $line := xosm_gml:_osm2GmlLine($oneway)
     return 
      if (geo:contains($line, $point)) then $oneway
      (: osm_file:_gml2Osm($oneway,$document) :)
       else () 
};

(: Returns true whenever node1 and node2 are in the same street :)

declare function xosm_sp:inSameWay($node1 as node(), $node2 as node(), $document as node()*)
{
  let $lat1 := $node1/@lat, $lon1 := $node1/@lon
  let $lat2 := $node2/@lat, $lon2 := $node2/@lon
  let
      $oneway1 := xosm_sp:WaysOfaPoint($node1,$document), 
      $oneway2 := xosm_sp:WaysOfaPoint($node2,$document)
  return     
   some $x in $oneway1 satisfies (some $y in $oneway2 satisfies
    (let $line1 := xosm_gml:_osm2GmlLine($x), 
         $line2 := xosm_gml:_osm2GmlLine($y)
    return geo:equals($line1,$line2))) 
};          
 
(: Returns true whenever a way crosses another one :)

declare function xosm_sp:isCrossing($oneway1 as node(), $oneway2 as node())
{
(: xosm_sp:booleanQuery($oneway1,$oneway2,"geo:crosses") :)
 if  (count($oneway1/way) = 1)
  then xosm_sp:booleanQuery($oneway1,$oneway2,"geo:crosses") 
  else
  (let $result := 
      (for $eachWay in $oneway1/way
       return 
       let $oneway1part:= <oneway>{$eachWay union 
           (for $nodeId in $eachWay/nd/@ref return $oneway1/node[@id=$nodeId][1])}
           </oneway>
       return 
      if (xosm_sp:booleanQuery($oneway1part,$oneway2,"geo:touches"))
       then data(1)  
      else data(0))
    return if (fn:sum($result) = 2) then true() else false()) 
};

(: Returns true whenever a ways is parallel to another one :)

declare function xosm_sp:isNotCrossing($oneway1 as node(), $oneway2 as node())
{
(:  not(xosm_sp:isCrossing($oneway1,$oneway2)) :)
 xosm_sp:booleanQuery($oneway1,$oneway2,"geo:disjoint")
};

(: Returns true whenever a ways ends to another one :)

declare function xosm_sp:isEnding($oneway1 as node(), $oneway2 as node())
{
 let $result := 
 (for $eachWay in $oneway1/way
 return 
  let $oneway1part:= <oneway>{$eachWay union 
 (for $nodeId in $eachWay/nd/@ref return $oneway1/node[@id=$nodeId][1])}</oneway>
 return 
  if (xosm_sp:booleanQuery($oneway1part,$oneway2,"geo:touches"))
 then
    let $mutliLineString1 := xosm_gml:_osm2GmlLine($oneway1part), 
        $multiLineString2 := xosm_gml:_osm2GmlLine($oneway2),
        $intersection_point := geo:intersection($mutliLineString1,$multiLineString2), 
        $start_point := geo:start-point($mutliLineString1/*),
        $end_point := geo:end-point($mutliLineString1/*)
    return 
           if (geo:equals($intersection_point/*,$start_point/*) or 
            geo:equals($intersection_point/*,$end_point/*)) then data(1) else data(0)
           else data(0))
   return if (fn:sum($result) = 1) then true() else false()  
};

declare function xosm_sp:isEndingFrom($oneway1 as node(), $oneway2 as node())
{
 xosm_sp:isEnding($oneway2,$oneway1)
};

declare function xosm_sp:isNotEndingFrom($oneway1 as node(), $oneway2 as node())
{
 not(xosm_sp:isEndingFrom($oneway1,$oneway2))
};

declare function xosm_sp:isEndingTo($oneway1 as node(), $oneway2 as node())
{
 xosm_sp:isEnding($oneway1,$oneway2)
};

declare function xosm_sp:isNotEndingTo($oneway1 as node(), $oneway2 as node())
{
 not(xosm_sp:isEndingTo($oneway1,$oneway2))
};

declare function xosm_sp:isContinuationOf($oneway1 as node(), $oneway2 as node())
{
 if (xosm_sp:booleanQuery($oneway1,$oneway2,"geo:touches"))
 then
    let $mutliLineString1 := xosm_gml:_osm2GmlLine($oneway1), 
        $multiLineString2 := xosm_gml:_osm2GmlLine($oneway2),
        $start_point := geo:start-point($mutliLineString1/*),
        $end_point := geo:end-point($multiLineString2/*)
    return (geo:equals($start_point/*,$end_point/*))
    else false()  
};

declare function xosm_sp:isNotContinuationOf($oneway1 as node(), $oneway2 as node())
{
  not(xosm_sp:isContinuationOf($oneway1,$oneway2))
};

declare function xosm_sp:intersectionPoint($oneway1 as node(), $oneway2 as node())
{
  let $mutliLineString1 := xosm_gml:_osm2GmlLine($oneway1), 
        $multiLineString2 := xosm_gml:_osm2GmlLine($oneway2)
    return
     if (xosm_sp:isCrossing($oneway1,$oneway2))
     then      
      let $intersectionPoint := geo:intersection($mutliLineString1,$multiLineString2)
         let $values :=  data($intersectionPoint/*/*[1])
     return
      if ($intersectionPoint//gml:LineString)
       then
         let $values2 := fn:substring-after($values,' ')
         return  
         <oneway name = "{$oneway2/@name}">
         <node visible = "true" lat = "{fn:substring-before($values2,',')}" 
         lon = "{fn:substring-after($values2,',')}">
         <tag k="name" v="{$oneway1/@name}/{$oneway2/@name}"/>
         </node>
       </oneway>
       else
         <oneway name = "{$oneway2/@name}">
         <node visible = "true" lat = "{fn:substring-before($values,',')}" 
         lon = "{fn:substring-after($values,',')}">
                  <tag k="name" v="{$oneway1/@name}/{$oneway2/@name}"/>
         </node>
       </oneway>
   else ()
};

(: Function in order to determinate if second node is northernmost than first one. Using latitudes by considering points in noth and south hemispheres :)
           
declare function xosm_sp:furtherNorthPoints($node1 as node(), $node2 as node())
{
  let $lat1 := $node1/@lat, $lat2 := $node2/@lat
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
};                              

(: Function in order to determinate if second node is further south than first one. furtherNorth negation :)

declare function xosm_sp:furtherSouthPoints($node1 as node(), $node2 as node())
{
  not(xosm_sp:furtherNorthPoints($node1,$node2))
};

(: Function in order to determinate if second node is further east than first node. Using latitudes by considering nodes in west and east hemispheres :)
           
declare function xosm_sp:furtherEastPoints($node1 as node(), $node2 as node())
{
  let $lon1 := $node1/@lon, $lon2 := $node2/@lon
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
};                              

(: Function in order to determinate if second node is further weast than first node. furtherEast negation :)

declare function xosm_sp:furtherWestPoints($node1 as node(), $node2 as node())
{
  not(xosm_sp:furtherEastPoints($node1,$node2))
};

declare function xosm_sp:furtherNorthWays($oneway1 as node(), $oneway2 as node())
{
  if ($oneway2/way) then
  (every $node1 in $oneway1/node 
   satisfies    
   (every $node2 in $oneway2/node satisfies (xosm_sp:furtherNorthPoints($node1,$node2))))
  else false() 
};

declare function xosm_sp:furtherSouthWays($oneway1 as node(), $oneway2 as node())
{
 if ($oneway2/way) then 
(every $node1 in $oneway1/node 
   satisfies    
   (every $node2 in $oneway2/node satisfies (xosm_sp:furtherSouthPoints($node1,$node2))))
 else false()
};

declare function xosm_sp:furtherEastWays($oneway1 as node(), $oneway2 as node())
{
  if ($oneway2/way) then
  (every $node1 in $oneway1/node 
   satisfies    
   (every $node2 in $oneway2/node satisfies (xosm_sp:furtherEastPoints($node1,$node2))))
  else false()
};

declare function xosm_sp:furtherWestWays($oneway1 as node(), $oneway2 as node())
{
 if ($oneway2/way) then
(every $node1 in $oneway1/node 
   satisfies    
   (every $node2 in $oneway2/node satisfies (xosm_sp:furtherWestPoints($node1,$node2))))
  else false()
};

(: Returns the shortest distance between two ways, 
   where that distance is the distance between a point on each of the geometries :)
   
declare function xosm_sp:getDistance($oneway1 as node(), $oneway2 as node())
{
  let $mutliLineString1 := xosm_gml:_osm2GmlLine($oneway1), 
      $multiLineString2 := xosm_gml:_osm2GmlLine($oneway2)
  return
    geo:distance($mutliLineString1,$multiLineString2)
};

declare function xosm_sp:getDistanceMbr($x1 as xs:float, $y1 as xs:float, 
                                    $s1 as xs:float, $t1 as xs:float,
                                    $x2 as xs:float, $y2 as xs:float, 
                                    $s2 as xs:float, $t2 as xs:float)
{
  let $oneway1 := <oneway name = "node">
                  <way name = "way"/>
                  <node visible="true" lat = "{$x1}" lon = "{$y1}" />
                  <node visible="true" lat = "{$s1}" lon = "{$y1}" />
                  <node visible="true" lat = "{$s1}" lon = "{$t1}" />
                  <node visible="true" lat = "{$x1}" lon = "{$t1}" />
                  <node visible="true" lat = "{$x1}" lon = "{$y1}" />
                  </oneway>
  
  let $oneway2 := <oneway name = "node">
                  <way name = "way"/>
                  <node visible="true" lat = "{$x2}" lon = "{$y2}" />
                  <node visible="true" lat = "{$s2}" lon = "{$y2}" />
                  <node visible="true" lat = "{$s2}" lon = "{$t2}" />
                  <node visible="true" lat = "{$x2}" lon = "{$t2}" />
                  <node visible="true" lat = "{$x2}" lon = "{$y2}" />
                  </oneway> 
                  
  let $mutliLineString1 := xosm_gml:_osm2GmlLine($oneway1), 
      $multiLineString2 := xosm_gml:_osm2GmlLine($oneway2)
  return
      geo:distance($mutliLineString1,$multiLineString2) 
};
 
declare function xosm_sp:isIn($oneway1 as node(), $oneway2 as node())
{
 let $distance := xosm_sp:getDistance($oneway1, $oneway2)
 return ($distance < 0.0001)
};

declare function xosm_sp:isNext($oneway1 as node(), $oneway2 as node())
{
 let $distance := xosm_sp:getDistance($oneway1, $oneway2)
 return ($distance < 0.001)
};

declare function xosm_sp:isAway($oneway1 as node(), $oneway2 as node())
{
 let $distance := xosm_sp:getDistance($oneway1,$oneway2)
 return ($distance < 0.01)
};

