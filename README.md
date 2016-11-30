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

![Alt text](https://raw.githubusercontent.com/ualabecerra/XOSM-Tool/master/Figures/XOSM/structure.key/preview.jpg)

## XOSM Indexing
he indexing process is made following two strategies: R∗-tree on the fly indexing with live data (RLD) and PostGIS indexing with backup data (PBD).Tables 2 and 3 show the functions to retrieve elements from OSM maps. getElementByName retrieves an OSM element by name, that is, it returns, given an OSM map m = (S,K), the OSM element s ∈ S such as name(s) = n. get- LayerByName(m,n,d) obtains given the name n of an OSM element, the OSM elements of the OSM map m = (S,K) at distance d of n. The same can be said for getLayerByElement(m,e,d), but here an OSM element e is passed as argu- ment. In RLD, the OSM map are organized in a R∗-tree, and thus getLayerBy- Name and getLayerByElement return the elements at MBR distance d, while in case of PBD, getLayerByName and getLayerByElement return the elements from a given distance d. getElementsByKeyword(m,k) retrieves OSM elements of the OSM map m = (S, K) by keyword k. The keyword can be either the key function or the value. Finally, getLayerByBB(m,mlat,Mlat,mlon,Mlon) retrieves the OSM elements in a certain area of the OSM map m = (S, K) given by a bounding box (mlat,Mlat,mlon,Mlon).Our proposed query language mainly uses getLayerByName, i.e., queries have to be focused on a certain area of interest, given by the name of a node (park, pharmacy, etc.,), or by the name of a way (street, building, etc.,). Once the layer from the area of interest is retrieved, the repertoire of OSM operators in combina- tion with higher order functions can be applied to produce complex queries. The answer of a query is an OSM layer including OSM elements of the area of interest. Nevertheless, getElementsByKeyword can be also used to retrieve OSM elements by keyword in a certain area. And also getLayerByBB can be used to retrieve all the elements enclosed by an area defined by a bounding box. In all the cases, the area is selected by the user (manually or using the search text field in the Web tool).

## Examples
* Example 1. Retrieve the streets in London intersecting *Haymarket* and touching *Trafalgar Square*:

```
let $layer := xosm_rld:getLayerByName(.,"Haymarket",0)let $s := xosm_rld:getElementByName(.,"Haymarket")let $ts := xosm_rld:getElementByName(.,"Trafalgar Square") return fn:filter(fn:filter($layer,xosm_sp:intersecting(?,$s)),xosm_sp:touching(?,$ts))
```
![Alt text](https://raw.githubusercontent.com/ualabecerra/XOSM-Tool/master/Figures/Example-1-v2.png)

* Example 2. Retrieve the restaurants in Rome further north to *Picasso* hotel:

```
let $layer := xosm_rld:getLayerByBB(.)let $hotel := xosm_rld:getElementByName(.,"Picasso")return fn:filter(fn:filter($layer,xosm_kw:searchKeyword(?,"restaurant")),xosm_sp:furtherNorthPoints($hotel ,?))
```

![Alt text](https://raw.githubusercontent.com/ualabecerra/XOSM-Tool/master/Figures/Example-2-v2.png)

* Example 3. Retrieve the hotels in *Vienna* close to food venues:

```
for $hotel inxosm_rld:getElementsByKeyword(.,"hotel")[@type="point" or @type="area"]let $layer := xosm_rld:getLayerByElement(.,$hotel ,200) where count(fn:filter($layer ,xosm_kw:searchKeywordSet(?,("bar","restaurant")))) >= 30 return $hotel
```
![Alt text](https://raw.githubusercontent.com/ualabecerra/XOSM-Tool/master/Figures/Example-3-v2.png)

* Example 4. Retrieve the hotels in *Munich* with the greatest number of churches nearby:

```
let $hotel := xosm_rld:getElementsByKeyword(.,"hotel") let $f := function($hotel){
-(count(fn:filter(xosm_rld:getLayerByElement(.,$hotel ,100), xosm_kw:searchKeyword(?,"church"))))}return fn:sort($hotel ,$f)[1]
```
![Alt text](https://raw.githubusercontent.com/ualabecerra/XOSM-Tool/master/Figures/Example-4-v2.png)

* Example 5. Retrieve the size of park areas close to *Karl-LiebknetchtStrasse* in Berlin:

```
let $layer := xosm_rld:getLayerByName(.,"Karl-Liebknecht-Strasse" ,350) let $parkAreas := fn:filter($layer ,xosm_kw:searchKeyword (?,"park")) return xosm_ag:metricSum($parkAreas ,"area")
```
![Alt text](https://raw.githubusercontent.com/ualabecerra/XOSM-Tool/master/Figures/Example-5-v2.png)

* Example 6. Retrieve the top-start rating biggest hotels close to *Via Dante* in Milan:

```
let $layer := xosm_rld:getLayerByName(.,"Via Dante" ,350)let $hotels := fn:filter($layer,xosm_kw:searchKeyword(?,"hotel")) return xosm_ag:metricMax(xosm_ag:metricMax($hotels ,"stars"), "area")
```
![Alt text](https://raw.githubusercontent.com/ualabecerra/XOSM-Tool/master/Figures/Example-6-v2.png)

* Example 7. Retrieve taxi stops close to *Carrousel du Louvre* in Paris. Taxi stops are retrieved from LOD Service of Paris:

```
let $taxis := xosm_open:json("https://opendata.paris.fr/explore/dataset/ paris_taxis_stations/download/?format=geojson&amp;timezone=Europe/Berlin" ,"address","amenity","taxi","highway","*")let $building := xosm_rld:getElementByName (.,"Carrousel du Louvre") return fn:filter($taxis,xosm_sp:DWithIn($building,?,500))
```
![Alt text](https://raw.githubusercontent.com/ualabecerra/XOSM-Tool/master/Figures/Example7-v2.png)

* Example 8. Retrieves free events of Madrid. The events are retrieved from the LOD ARCGIS site:

```
let $events := xosm_open:json("https://data2.esrism.opendata.arcgis.com/datasets/51900577e33a4ba4ab59a691247aeee9_0.geojson","EVENTO","place","*","area","yes") return fn:filter($events ,function($p){not(empty($p/node/tag[@k="GRATUITO" and @v="Si"]))})
```
![Alt text](https://raw.githubusercontent.com/ualabecerra/XOSM-Tool/master/Figures/Example-8-v2.png)

* Example 9. This query uses the function wiki element to retrieve Wikipedia information about places nearby to the intersection point of *Calle Mayor* and *Calle de Esparteros* in Madrid:

```
et $x := xosm_rld:getElementByName(.,"Calle Mayor")let $y := xosm_rld:getElementByName(.,"Calle de Esparteros") return for $i in xosm_sp:intersectionPoints($x,$y)
       return xosm_open:wiki_element($i)
```
![Alt text](https://raw.githubusercontent.com/ualabecerra/XOSM-Tool/master/Figures/Example-9-v2.png)

* Example 10. Retrieve the information provided by tixik.com around *Picadilly* in London:

```
let $x := xosm_rld:getElementByName(.,"Piccadilly") return xosm_open:tixik_element($x)
```
![Alt text](https://raw.githubusercontent.com/ualabecerra/XOSM-Tool/master/Figures/Example-10-v2.png)

## Benchmarks
In this section, we show the benchmarks of the proposed tool. We analyze the following cases:* Layer Retrieval for XOSM RLD strategy. We analyze the response time for the retrieval of layers using distances and keywords (i.e., getLayerByName and getElementsByKeyword).
* Comparison of XOSM RLD and PBD strategies. We compare the re- sponse time for query answering of the examples.
* Comparison of XOSM PBD strategy and PostGIS. We compare the response time on spatial and keyword queries.For this benchmarking, we have used a HP Proliant (one quad core and 12GB RAM Memory) with Ubuntu Server (version 16.10). For the implementation, we have used the BaseX XQuery processor (version 8.3) and the PostGIS system over PostgreSQL (version 9.5).

![Alt text](https://raw.githubusercontent.com/ualabecerra/XOSM-Tool/master/Figures/getlayer.pdf)

![Alt text](https://raw.githubusercontent.com/ualabecerra/XOSM-Tool/master/Figures/park-hotel.pdf)

![Alt text](https://raw.githubusercontent.com/ualabecerra/XOSM-Tool/master/Figures/examples-rldpbd.png)

![Alt text](https://raw.githubusercontent.com/ualabecerra/XOSM-Tool/master/Figures/BenchmarkingPBD-RLD.png)

![Alt text](https://raw.githubusercontent.com/ualabecerra/XOSM-Tool/master/Figures/BenchmarkingPostGIS-BaseX-1.png)

![Alt text](https://raw.githubusercontent.com/ualabecerra/XOSM-Tool/master/Figures/BenchmarkingPostGIS-BaseX-2.png)
