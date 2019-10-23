#Download all L3A in EUrope in July from PEPS (mostly France so far)

#python /mnt/data/home/hagolleo/PROG/S2/theia_download/theia_download.py -l 'Europe' -d 2019-05-01 -f 2019-05-31 --level LEVEL3A -a /mnt/data/home/hagolleo/PROG/S2/theia_download/config_hagolle.cfg -w France201808

#Data are stored in France201808
cd $1
#parallel -j8 unzip -o  ::: SENTINEL2?_201*.zip


#print the command lines when executed
set -x
echo $PWD
res=$2 #Final resolution

#divide in 6 zones depending on the beginning of tilename
for UTM in T29S T29T T30S T30T T31S T31T 
do
  # make a mosaic of each band
  parallel gdalbuildvrt Ib_{}.vrt  SENTINEL2?_201*_$UTM*/*{}*.tif ::: B2 B3 B4
  # stack the band mosaics
  gdalbuildvrt -separate Ib_${UTM}_B432.vrt Ib_B4.vrt Ib_B3.vrt Ib_B2.vrt
  # export as a RGB image at full resolution
  gdal_translate -r cubic -ot Byte -scale -100 3000 -tr $res $res Ib_${UTM}_B432.vrt Ib_${UTM}_B432_$res.tif
  # Optionally clip the image using the polygon of the Belgium borders
done


#We have 3 UTM zones over Iberia. To merge them, we need to resample in common projection. We chose the French standard projection UTM30
parallel  -j3 gdalwarp -overwrite -r cubic -t_srs "EPSG:32630" -tr $res $res  Ib_{}_B432_$res.tif Ib_{}_B432_U30_$res.tif ::: T31S T31T T30S T30T T29S T29T

#Now, we can merge
gdal_merge.py -n 0 Ib_T31*_U30_$res.tif  Ib_T30*_U30_$res.tif  Ib_T29*_U30_$res.tif -o  Iberia_U30_${res}.tif


#And we ccdan crop  to France borders. For that we need a vector mask of France contours
#I used, following Simon Gascoin 
# https://ec.europa.eu/eurostat/cache/GISCO/distribution/v2/countries/download/ref-countries-2016-03m.shp.zip
#necessity to clip as France has overseas territories
#ogr2ogr -f KML France.kml -where "NAME_ENGL='France'" Europe_shp/CNTR_RG_03M_2016_4326.shp -clipsrc -5.8 41 10 51.5

#with qgis, I aded a 2 km buffer along French coasts

# zoom levels defined here : https://wiki.openstreetmap.org/wiki/Zoom_levels
# 6=>444m, 12=> 38m  at equator


gdalwarp -overwrite -dstnodata 0  -cutline ../Iberia_buffer.shp -crop_to_cutline Iberia_U30_${res}.tif Iberia_U30_${res}_crop.tif

#and transform into tile
gdal2tiles.py -z 5-13 -r cubic Iberia_U30_${res}_crop.tif Iberia_Tiles_${res}


