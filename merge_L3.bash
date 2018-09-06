#Download all L3A in EUrope in July from PEPS (mostly France so far)

#python theia_download.py -l 'Europe' -d 2018-07-01 -f 2018-07-31 --level LEVEL3A -a config_theia.cfg -w France201807

#Data are stored in France201807
#cd France201807
#parallel -j8 unzip -o ::: SENTINEL2X_201807*zip
#rm -rf SENTINEL2X_201807*zip
#cd -

#print the command lines when executed
set -x

res=20 #Final resolution

#divide in 6 zones depending on the beginning of tilename
for UTM in T30T T30U T31T T31U T32T T32U
do
  # make a mosaic of each band
  parallel gdalbuildvrt {}.vrt  France201807/SENTINEL2X_201807*_$UTM*/*{}*.tif ::: B2 B3 B4
  # stack the band mosaics
  gdalbuildvrt -separate ${UTM}_B432.vrt B4.vrt B3.vrt B2.vrt
  # export as a RGB image at full resolution
  gdal_translate -r cubic -ot Byte -scale 0 2000 -tr $res $res ${UTM}_B432.vrt ${UTM}_B432_$res.tif
  # Optionally clip the image using the polygon of the Belgium borders
done


#We have 3 UTM zones over France. To merge them, we need to resample in common projection. We chose the French standard projection Lambert 93, epsg=2154 
parallel  -j3 gdalwarp -overwrite -r cubic -t_srs "EPSG:2154" -tr $res $res  {}_B432_$res.tif {}_B432_L93_$res.tif ::: T30T T30U T31T T31U T32T T32U

#Now, we can merge
gdal_merge.py -n 0 T3*_L93_$res.tif -o  France_L93_${res}.tif


#And we can crop  to France borders. For that we need a vector mask of France contours
#I used, following Simon Gascoin 
# https://ec.europa.eu/eurostat/cache/GISCO/distribution/v2/countries/download/ref-countries-2016-03m.shp.zip
#necessity to clip as France has overseas territories
#ogr2ogr -f KML France.kml -where "NAME_ENGL='France'" Europe_shp/CNTR_RG_03M_2016_4326.shp -clipsrc -5.8 41 10 51.5

#with qgis, I aded a 2 km buffer along French coasts

# zoom levels defined here : https://wiki.openstreetmap.org/wiki/Zoom_levels
# 6=>444m, 12=> 38m  at equator


gdalwarp -overwrite -dstnodata 0  -cutline France_buffer.shp -crop_to_cutline France_L93_${res}.tif France_L93_${res}_crop.tif

#and transform into tile
gdal2tiles.py -z 5-13 -r cubic France_L93_${res}_crop.tif Tiles_${res}


