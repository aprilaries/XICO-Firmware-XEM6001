cd /home/brownlab/Documents/Spencer/DDS_Spencer/blah
if { [ catch { xload xmp blah.xmp } result ] } {
  exit 10
}
xset intstyle default
save proj
exit 0
