# Merge_L3A

This script helps producing mosaics over large regions, using Theia's L3A products, available from https://theia.cnes.fr
An example of mosaic of France is avalable here: http://www.cesbio.ups-tlse.fr/multitemp/?p=14192

The script is written in bash.
It requires several components :
- [theia_download tool] (https://github.com/olivierhagolle/theia_download) 
- GDAL (at least V2.0).
- vector contours of countries. I used https://ec.europa.eu/eurostat/cache/GISCO/distribution/v2/countries/download/ref-countries-2016-03m.shp.zip
- I used QGIS to add a buffer to that contour to avoid missing sharp features of the coasts or borders




