# XOSM: A Tool for Geospatial Queries on Open Street Map

## Abstract
Volunteered geographic information (VGI) makes available a very large resource of geographic data. The exploitation of data coming from such resources requires an additional effort in the form of tools and effective processing techniques. One of the most stablished VGI is Open Street Map (OSM) offering data of urban and rural maps from the earth. In this paper we present a tool, called XOSM, for the processing of geospatial queries on OSM. The tool is equipped with a rich query language based on a set of operators defined for OSM which have been implemented as a library of the XML query language XQuery. The library provides a rich repertoire of spatial, keyword and aggregation based functions, which act on the XML representation of an OSM layer. The use of the higher order facilities of XQuery makes possible the definition of complex geospatial queries involving spatial relations, keyword searching and aggregation functions. XOSM indexes OSM data enabling efficient retrieval of answers.

 ![Alt text](http://indalog.ual.es/osm/Querying_Open_Street_Map_with_XQuery/Welcome_files/shapeimage_2.png)

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

![Alt text](https://raw.githubusercontent.com/ualabecerra/XOSM-Tool/master/Figures/XOSM/XOSM.001.png)

## OSM Indexing
In order to handle large city maps, in which the layer can include many objects, an R\*-tree structure to index objects is used. The R\*-tree structure is based, as usual, on MBRs to hierarchically organize the content of an OSM map. Moreover, they are also used to enclose the nodes and ways of OSM in leaves of such structure. Figure shows a visual 
representation of the R\*-tree of a OSM layer for Almería (Spain) city map. These ways have been highlighted in different colors (red and green)
and MBRs are represented by light green rectangles.

The R-tree structure has been implemented as an XML document. That is, the tag based structure of XML is
used for representing the R\*-tree with two main tags called *node* and *leaf*. A node tag represents the 
MBR enclosing the children nodes, while leaf tag contains the MBR of OSM ways and nodes. The tag *mbr* is used to represent MBRs.

![Alt text](https://raw.githubusercontent.com/ualabecerra/OSMXQuery/master/ConferenceBetaDeveloper/GISTAM2015/ExampleFigures/FigureIndexNew.png)

## Examples
* Example 1. Retrieve the street to the north of the street *Calle Calzada de Castro*:

```
let $street := xosm_rtj:getElementByName(.,"Calle Calzada de Castro"),
$layer := xosm_rtj:getLayerByName(.,"Calle Calzada de Castro",0.001)
return
fn:filter(fn:filter($layer,xosm_sp:furtherNorthWays($street,?)),xosm_kw(?,"highway"))
```
![Alt text](https://raw.githubusercontent.com/ualabecerra/XOSM-Tool/master/Figures/FigureExample1.png)

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
fn:filter(fn:for-each($ending,xosm_rtj:getLayerByElement(.,?,0.001)), xosm_kw:searchKeyword(?,"school"))
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
fn:for-each($intpoints, xosm_rtj:getLayerByElement(.,?,0.001)),xosm_kw:searchKeyword(?,"building"))
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



## Benchmarks
Now we would like to show the benchmarks obtained from the previous examples, for datasets of different sizes.

We have used the *BaseX Query* processor in a Mac Core 2 Duo 2.4 GHz. All benchmarking proofs have been tested using a virtual machine running Windows 7 since the *JTS Topology Suite* is not available for *Mac OS* *BaseX* version. Benchmarks are shown in milliseconds in the next Figure.

We have tested Examples 1 to 5 with sizes ranging from two hundred to fourteen thousand objects, corresponding to: from a zoom to *Calzada de Castro* street to the whole Almería city map (around 10 square kilometers). From the benchmarks, we can conclude that increasing the map size, does not increase, in a remarkable way, the answer time.

![Alt text](https://raw.githubusercontent.com/ualabecerra/OSMXQuery/master/ConferenceBetaDeveloper/GISTAM2015/ExampleFigures/benchmarking1.png)


## Conclusions and Future Work
We have presented an XQuery library for querying OSM. We have defined a set of OSM Operators suitable for querying points and streets from OSM. We have shown how higher order facilities of XQuery enable the definition of complex queries over OSM involving composition and keyword searching. We have provided some benchmarks using our library that take 
profit from the R-tree structure used to index OSM. As future work firstly, we would like to extend our library to handle closed ways of OSM, in order to query about buildings, parks, etc. 
Secondly, we would like to enrich the repertoire of OSM operators for points and streets: distance based queries, ranked queries, etc.

Finally, we would like to develop a JOSM plugin, as well as a Web site, with the aim to execute and
to show results of queries directly in OSM maps.
