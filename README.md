# XOSM: A Web Site for Processing GeoSpatial Queries on OpenStreetMap

## Abstract
Volunteered Geographic Information (VGI) describes geographic in- formation systems based on crowdsourcing, in which users collaborate to collect spatial data of urban and rural areas on the earth. One of the most established VGI is OpenStreetMap (OSM) offering data of urban and rural maps from the earth. In this paper a Web tool, called XOSM (XQuery for OpenStreetMap), for the processing of geospatial queries on OSM is presented. The tool is equipped with a rich query language based on a set of operators defined for OSM which have been implemented as a library of the XML query language XQuery. The library provides a rich repertoire of spatial, keyword and aggregation based functions, which act on the XML representation of an OSM layer. The use of the higher order facilities of XQuery makes possible the definition of complex geospatial queries involving spa- tial relations, keyword searching and aggregation functions. XOSM indexes OSM data enabling efficient retrieval of answers. The XOSM library also enables the definition of queries combining OSM layers and layers created from Linked Open Data resources (KML, GeoJSON, CSV and RDF). The tool also provides an API to execute XQuery queries using the library.

![Alt text](https://raw.githubusercontent.com/ualabecerra/XOSM-Tool/master/Figures/XOSM/xosm-pic.png)

### TEAM:

* Jesús M. Almendros-Jiménez
* Antonio Becerra-Terón
* Manuel Torres

* Universidad de Almería
* Dpto. Informática
* Crta. Sacramento S/N
* 04120 Almerí­a

### CONTACT:

* [jalmen@ual.es](mailto:jalmen@ual.es)
* [abecerra@ual.es](mailto:abecerra@ual.es)
* [mtorres@ual.es](mailto:mtorres@ual.es)

## XOSM Tool Architecture

![Alt text](https://raw.githubusercontent.com/ualabecerra/XOSM-Tool/master/Figures/XOSM/structure.png)

## XOSM Indexing
he indexing process is made following two strategies: R∗-tree on the fly indexing with live data (RLD) and PostGIS indexing with backup data (PBD).Tables 2 and 3 show the functions to retrieve elements from OSM maps. getElementByName retrieves an OSM element by name, that is, it returns, given an OSM map m = (S,K), the OSM element s ∈ S such as name(s) = n. get- LayerByName(m,n,d) obtains given the name n of an OSM element, the OSM elements of the OSM map m = (S,K) at distance d of n. The same can be said for getLayerByElement(m,e,d), but here an OSM element e is passed as argu- ment. In RLD, the OSM map are organized in a R∗-tree, and thus getLayerBy- Name and getLayerByElement return the elements at MBR distance d, while in case of PBD, getLayerByName and getLayerByElement return the elements from a given distance d. getElementsByKeyword(m,k) retrieves OSM elements of the OSM map m = (S, K) by keyword k. The keyword can be either the key function or the value. Finally, getLayerByBB(m,mlat,Mlat,mlon,Mlon) retrieves the OSM elements in a certain area of the OSM map m = (S, K) given by a bounding box (mlat,Mlat,mlon,Mlon).Our proposed query language mainly uses getLayerByName, i.e., queries have to be focused on a certain area of interest, given by the name of a node (park, pharmacy, etc.,), or by the name of a way (street, building, etc.,). Once the layer from the area of interest is retrieved, the repertoire of OSM operators in combina- tion with higher order functions can be applied to produce complex queries. The answer of a query is an OSM layer including OSM elements of the area of interest. Nevertheless, getElementsByKeyword can be also used to retrieve OSM elements by keyword in a certain area. And also getLayerByBB can be used to retrieve all the elements enclosed by an area defined by a bounding box. In all the cases, the area is selected by the user (manually or using the search text field in the Web tool).

## Examples
* Example 1. Retrieve the streets in London intersecting *Haymarket* and touching *Trafalgar Square*:

```
let $layer := xosm_rld:getLayerByName(.,"Haymarket",0)let $s := xosm_rld:getElementByName(.,"Haymarket")let $ts := xosm_rld:getElementByName(.,"Trafalgar Square") return fn:filter(fn:filter($layer,xosm_sp:intersecting(?,$s)),xosm_sp:touching(?,$ts))
```
![Alt text](https://raw.githubusercontent.com/ualabecerra/XOSM-Tool/master/Figures/Example-1-v2.png)

* Example 2. Retrieve the streets crossing *Calzada de Castro* and
ending to *Avenida Montserrat* street:

```
let $s1 := xosm_rtj:getElementByName(., "Calle Calzada de Castro"),
$s2 := xosm_rtj:getElementByName(.,"Avenida Nuestra Senora de Montserrat"),
$layer := xosm_rtj:getLayerByName(.,"Calle Calzada de Castro",0),
$cross := fn:filter($layer,xosm_sp:isCrossing(?,$s1))
return fn:filter($cross,xosm_sp:isEndingTo(?,$s2)) 
```

![Alt text](https://raw.githubusercontent.com/ualabecerra/XOSM-Tool/master/Figures/FigureExample2.png)

* Example 3. Retrieve the schools close to a street, wherein the street *Calzada de Castro* ends. 

```
let $street := xosm_rtj:getElementByName(., "Calle Calzada de Castro"),
$layer := xosm_rtj:getLayerByName(.,"Calle Calzada de Castro", 0),
$ending := fn:filter($layer,xosm_sp:isEndingTo($street,?))
return
fn:filter(fn:for-each($ending,xosm_rtj:getLayerByElement(.,?,0.001)), 
xosm_kw:searchKeyword(?,"school"))
```
![Alt text](https://raw.githubusercontent.com/ualabecerra/XOSM-Tool/master/Figures/FigureExample3.png)

* Example 4. Retrieve the buildings in the intersections of *Calzada de Castro*
```
let $street := xosm_rtj:getElementByName(., "Calle Calzada de Castro"),
$layer := xosm_rtj:getLayerByName(.,"Calle Calzada de Castro",0),
$crossing := fn:filter($layer,xosm_sp:isCrossing(?, $street)),
$intpoints := fn:for-each($crossing, xosm_sp:intersectionPoint(?,$street))
return 
fn:filter(
fn:for-each($intpoints, xosm_rtj:getLayerByElement(.,?,0.001)),
xosm_kw:searchKeyword(?,"building"))
```
![Alt text](https://raw.githubusercontent.com/ualabecerra/XOSM-Tool/master/Figures/FigureExample5.png)

* Example 5. Retrieve schools and high schools close to the street *Calzada de Castro*

```
for $layer in xosm_rtj:getLayerByName(.,"Calle Calzada de Castro",0.001)
where xosm_kw:searchKeywordSet($layer,("high school","school"))
return $layer
```
![Alt text](https://raw.githubusercontent.com/ualabecerra/XOSM-Tool/master/Figures/FigureExample6.png)

* Example 6. Retrieve the areas of the city in which there is a pharmacy
```
for $pharmacies in xosm_rtj:getElementsByKeyword(.,"pharmacy")
return xosm_rtj:getLayerByElement(.,$pharmacies,0.001)
```
![Alt text](https://raw.githubusercontent.com/ualabecerra/XOSM-Tool/master/Figures/FigureExample7.png)

* Example 7. Retrieve the food areas close to hotels of the city
```
for $hotels in xosm_rtj:getElementsByKeyword(.,"hotel") 
let $layer := xosm_rtj:getLayerByElement(.,$hotels,0.002) 
where count(fn:filter($layer, xosm_kw:searchKeywordSet(?,("bar","restaurant")))) >= 3
return $layer
```
![Alt text](https://raw.githubusercontent.com/ualabecerra/XOSM-Tool/master/Figures/FigureExample8.png)

* Example 8.  Retrieve the hotel with the greatest number of churches around
```
let $hotels := xosm_rtj:getElementsByKeyword(.,"hotel")
let $f := function($hotel) 
{-(count(fn:filter(xosm_rtj:getLayerByElement(.,$hotel,0.001),
xosm_kw:searchKeyword(?,"church"))))}
return fn:sort($hotels,$f)[1]
```
![Alt text](https://raw.githubusercontent.com/ualabecerra/XOSM-Tool/master/Figures/FigureExample9.png)

* Example 9. Requests the size of park areas close 
to the street *Paseo de Almeria* The query is expressed as follows:
```
let $layer := xosm_rtj:getLayerByName(.,"Paseo de Almeria",0.003),
$parkAreas := fn:filter($layer,xosm_kw:searchKeyword(?,"park"))          
return 
	xosm_ag:metricSum($parkAreas,"area")
```
![Alt text](https://raw.githubusercontent.com/ualabecerra/XOSM-Tool/master/Figures/FigureExample10.png)

* Example 10. Requests the most frequent star rating of hotels close to *Paseo de Almeria* and it is expressed as follows:
```
let $layer := xosm_rtj:getLayerByName(.,"Paseo de Almeria",0.003),
    $hotels := fn:filter($layer,xosm_kw:searchKeyword(?,"hotel"))                  
return 
	xosm_ag:metricMode($hotels,"stars")
```
![Alt text](https://raw.githubusercontent.com/ualabecerra/XOSM-Tool/master/Figures/FigureExample11.png)

* Example 11. Requests the biggest hotels of top star ratings close to *Paseo de Almeria*
```
let $layer := xosm_rtj:getLayerByName(.,"Paseo de Almeria",0.003),
$hotels := fn:filter($layer,xosm_kw:searchKeyword(?,"hotel"))                  
return
xosm_ag:metricMax(xosm_ag:metricMax($hotels,"stars"), "area")
```
![Alt text](https://raw.githubusercontent.com/ualabecerra/XOSM-Tool/master/Figures/FigureExample12.png)

* Example 12. Requests the closest 
restaurant to *Paseo de Almeria* having
the most typical cuisine
```
let $street := xosm_rtj:getElementByName(.,"Paseo de Almeria"),
$layer := xosm_rtj:getLayerByName(.,"Paseo de Almeria",0.003),
$restaurants := fn:filter($layer,xosm_kw:searchKeyword(?,"restaurant")),                 
return 
xosm_ag:minDistance(xosm_ag:metricMode($restaurants,"cuisine"),
$street)
```
![Alt text](https://raw.githubusercontent.com/ualabecerra/XOSM-Tool/master/Figures/FigureExample13.png)

## Benchmarks
we show the benchmarks of the proposed library.
We have used the *BaseX Query* processor in a HP Proliant (two 
processors and 16 MB RAM Memory) with Windows Server 2008 R2. The goal of these benchmarks is to show the required response time for the library functions involving  
the spatial (R\*-tree) and textual (BaseX) index, as well to evaluate the time
required to answer queries. With this aim, we have tested 
maps of several cities: *Almeria*, *Alexandria*, *Santa Barbara*, *Alburquerque*, *Cusco*, *Cork*, *Waterloo*
and, finally, *Brisbane*

![Alt text](https://raw.githubusercontent.com/ualabecerra/XOSM-Tool/master/Figures/agg-1.png)

![Alt text](https://raw.githubusercontent.com/ualabecerra/XOSM-Tool/master/Figures/agg-2.png)

![Alt text](https://raw.githubusercontent.com/ualabecerra/XOSM-Tool/master/Figures/agg-3.png)

## PotGis Comparative
PostGreSQL is a well-known RDBMS with a spatial extension called PostGIS. PostGIS adds datatypes and spatial
operators to PostGreSQL. Indexing of spatial data is carried out by R-Tree-over-GiST scheme.
Open Street Map can be handled by PostGIS with the following tools: (1) Osmosis: a Java-based library for OSM loading, writing and ordering; (2) Osm2pgsql on top of osmosis, to transform OSM; 
(3) Imposm a Python-based tool to import OSM in XML and PBF *Protocolbuffer Binary Format* formats. Although PostGIS could be adopted in our framework for storing/indexing OSM geometries, we have decided to provide a pure XQuery implementation instead of mapping XQuery to another query language.  We have compared our approach with PostGIS,
in particular, the performance of (a) retrieval of a layer by name (i.e. spatial index
or *getLayerByName*) and (b) retrieval of elements represented by a keyword (i.e. textual index or *getElementsByKeyword*).

![Alt text](https://raw.githubusercontent.com/ualabecerra/XOSM-Tool/master/Figures/PostGISXQuery-1.png)

![Alt text](https://raw.githubusercontent.com/ualabecerra/XOSM-Tool/master/Figures/PostGISXQuery-2.png)

![Alt text](https://raw.githubusercontent.com/ualabecerra/XOSM-Tool/master/Figures/PostGISXQuery-3.png)

![Alt text](https://raw.githubusercontent.com/ualabecerra/XOSM-Tool/master/Figures/PostGISXQuery-4.png)
