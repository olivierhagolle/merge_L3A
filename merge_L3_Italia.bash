#Download all L3A in EUrope in July from PEPS (mostly France so far)

#python /mnt/data/home/hagolleo/PROG/S2/theia_download/theia_download.py -l 'Europe' -d 2019-05-01 -f 2019-05-31 --level LEVEL3A -a /mnt/data/home/hagolleo/PROG/S2/theia_download/config_hagolle.cfg -w France201808

#Data are stored in France201808
cd France201909
#parallel -j8 unzip -o  ::: SENTINEL2?_201*.zip


#print the command lines when executed
set -x
echo $PWD
res=20 #Final resolution

#divide in 6 zones depending on the beginning of tilename
for UTM in T32S T32T T33S T33T T34S 
do
  # make a mosaic of each band
  parallel gdalbuildvrt It_{}.vrt  SENTINEL2?_201*_$UTM*/*{}*.tif ::: B2 B3 B4
  # stack the band mosaics
  gdalbuildvrt -separate It_${UTM}_B432.vrt It_B4.vrt It_B3.vrt It_B2.vrt
  # export as a RGB image at full resolution
  gdal_translate -r cubic -ot Byte -scale -50 2000 -tr $res $res It_${UTM}_B432.vrt It_${UTM}_B432_$res.tif
  # Optionally clip the image using the polygon of the Belgium borders
done


#We have 3 UTM zones over Italia. To merge them, we need to resample in common projection. We chose  UTM32
parallel  -j3 gdalwarp -overwrite -r cubic -t_srs "EPSG:32632" -tr $res $res  It_{}_B432_$res.tif It_{}_B432_U32_$res.tif ::: T32S T32T T33S T33T T34S

Now, we can merge
gdal_merge.py -n 0 It_T*_U32_$res.tif -o  Italia_U32_${res}.tif


#And we ccdan crop  to France borders. For that we need a vector mask of France contours
#I used, following Simon Gascoin 
# https://ec.europa.eu/eurostat/cache/GISCO/distribution/v2/countries/download/ref-countries-2016-03m.shp.zip
#necessity to clip as France has overseas territories
#ogr2ogr -f KML France.kml -where "NAME_ENGL='France'" Europe_shp/CNTR_RG_03M_2016_4326.shp -clipsrc -5.8 41 10 51.5

#with qgis, I aded a 2 km buffer along French coasts

# zoom levels defined here : https://wiki.openstreetmap.org/wiki/Zoom_levels
# 6=>444m, 12=> 38m  at equator


gdalwarp -overwrite -dstnodata 0  -cutline ../Italia_fusionne.shp -crop_to_cutline Italia_U32_${res}.tif Italia_U32_${res}_crop.tif

#and transform into tile
gdal2tiles.py -z 5-13 -r cubic Italia_U32_${res}_crop.tif Italia_Tiles_${res}


