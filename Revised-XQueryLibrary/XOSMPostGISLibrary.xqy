module namespace xosm_pbd = "xosm_pbd";

import module namespace xosm_gml = 'xosm_gml' at '../repo/XOSM2GmlQueryLibrary.xqy';
import module namespace xosm_sp = 'xosm_sp' at '../repo/XOSMSpatialQueryLibrary.xqy';

declare function xosm_pbd:getElementByName($bbox1 as xs:decimal, $bbox2 as xs:decimal, $bbox3 as xs:decimal,
                 $bbox4 as xs:decimal, $name as xs:string)
{
 let $element := 
http:send-request(<http:request method='get' href='http://xosm.ual.es/xosmapi/internalGetElementByName/minLon/{$bbox1}/minLat/{$bbox2}/maxLon/{$bbox3}/maxLat/{$bbox4}/name/{web:encode-url($name)}'/>)[2]//oneway
 return 
 if ($element[@type = "way" or @type = "polygon"]) then $element[@type = "way" or @type = "polygon"][1]
 else $element[1]
};

declare function xosm_pbd:getLayerByElement($bbox1 as xs:decimal, $bbox2 as xs:decimal, $bbox3 as xs:decimal,
                 $bbox4 as xs:decimal, $oneway as node(), $distance as xs:integer)
{
 if (empty($oneway/@name))
 then
http:send-request(<http:request method='get' href='http://xosm.ual.es/xosmapi/internalGetLayerByElement/minLon/{$bbox1}/minLat/{$bbox2}/maxLon/{$bbox3}/maxLat/{$bbox4}/lon/{data($oneway/node[1]/@lon)}/lat/{data($oneway/node[1]/@lat)}/distance/{$distance}'/>)[2]//oneway
 else xosm_pbd:getLayerByName($bbox1, $bbox2,$bbox3,$bbox4,data($oneway/@name),$distance)
};

declare function xosm_pbd:getLayerByName($bbox1 as xs:decimal, $bbox2 as xs:decimal, $bbox3 as xs:decimal,
                 $bbox4 as xs:decimal, $name as xs:string, $distance as xs:integer)
{  
  http:send-request(<http:request method='get' href='http://xosm.ual.es/xosmapi/internalGetLayerByName/minLon/{$bbox1}/minLat/{$bbox2}/maxLon/{$bbox3}/maxLat/{$bbox4}/name/{web:encode-url($name)}/distance/{$distance}'/>)[2]//oneway 
};

declare function xosm_pbd:getElementsByKeyword($bbox1 as xs:decimal, $bbox2 as xs:decimal, $bbox3 as xs:decimal,
                 $bbox4 as xs:decimal, $keyword as xs:string)
{
http:send-request(<http:request method='get' href='http://xosm.ual.es/xosmapi/internalGetElementByKeyword/minLon/{$bbox1}/minLat/{$bbox2}/maxLon/{$bbox3}/maxLat/{$bbox4}/keyword/{$keyword}'/>)[2]//oneway
};

declare function xosm_pbd:getLayerByBB($bbox1 as xs:decimal, $bbox2 as xs:decimal, $bbox3 as xs:decimal, $bbox4 as xs:decimal)
{
http:send-request(<http:request method='get' href='http://xosm.ual.es/xosmapi/internalGetLayerByBB/minLon/{$bbox1}/minLat/{$bbox2}/maxLon/{$bbox3}/maxLat/{$bbox4}'/>)[2]//oneway
};

declare function xosm_pbd:getCenterFromBB($bbox1 as xs:decimal, $bbox2 as xs:decimal, 
   $bbox3 as xs:decimal, $bbox4 as xs:decimal){
   xosm_sp:centerOfBB($bbox1,$bbox2,$bbox3,$bbox4)
};