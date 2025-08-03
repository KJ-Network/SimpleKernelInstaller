# Simple Kernel Installer
# By KeJia

# Load utility functions
. $MODPATH/tools/util_functions.sh

# Get Kernel Name and print
name=$(grep '^name=' $MODPATH/config.conf | cut -d '=' -f 2)

ui_print " "
ui_print "- $name Installer"
ui_print " "

# Get codename and check
codename=$(grep '^codename=' $MODPATH/config.conf | cut -d '=' -f 2)

if test -z "$(grep $codename /system/build.prop)"; then 
    ui_print "- Device is not ' $codename ' , cannot install this kernel."
    exit 1
fi

# Get boot partition name
if [ ! -e /dev/block/bootdevice/by-name/boot* ]; then
    ui_print "- Unsupport Environment!"
    exit 1
elif test -z "$(getprop ro.boot.slot_suffix)"; then
    export boot="/dev/block/bootdevice/by-name/boot"
else
    export boot="/dev/block/bootdevice/by-name/boot$(getprop ro.boot.slot_suffix)"
fi

# Install Kernel
chmod +x $MODPATH/tools/*
export PATH="$MODPATH/tools:$PATH"

ui_print "- Extracting 'Boot' Image..."
dd if=$boot of=$MODPATH/boot.img
ui_print "- Unpacking 'Boot' Image..."
magiskboot unpack $MODPATH/boot.img
ui_print "- Spliting The Kernel Package And Uploading The Kernel..."
if [ -e $MODPATH/Image.gz-dtb ]; then
    magiskboot split $MODPATH/Image.gz-dtb
elif [ -e $MODPATH/Image-dtb ]; then
    magiskboot split $MODPATH/Image-dtb
elif [ -e $MODPATH/Image.gz ]; then
    magiskboot decompress $MODPATH/Image.gz kernel
elif [ -e $MODPATH/Image ]; then
    mv $MODPATH/Image kernel
else
    ui_print "- No kernel Image detected! Install failed!"
    exit 1
fi
if [ -e $MODPATH/*.dtb ]; then
    ui_print "- DTB detected! Please select:"
    ui_print "- Volume Up: Install DTB (Recommended)"
    ui_print "- Volume Down: Skip install DTB"
    user_choice=$(Key_monitoring)
    if [ $user_choice == "volume_up" ]; then
        mv $MODPATH/*.dtb kernel_dtb
    fi
fi
ui_print "- Repacking 'Boot' Image..."
magiskboot repack $MODPATH/boot.img
ui_print "- Flashing 'Boot' Image..."
dd if=new-boot.img of=$boot
ui_print "- Install Successful!"

ui_print " "

ui_print "- Cleaning GPU cache..."
find /data/user_de/*/*/*cache/* -iname "*shader*" -exec rm -rf {} +
find /data/data/* -iname "*shader*" -exec rm -rf {} +
find /data/data/* -iname "*graphitecache*" -exec rm -rf {} +
find /data/data/* -iname "*gpucache*" -exec rm -rf {} +
find /data_mirror/data*/*/*/*/* -iname "*shader*" -exec rm -rf {} +
find /data_mirror/data*/*/*/*/* -iname "*graphitecache*" -exec rm -rf {} +
find /data_mirror/data*/*/*/*/* -iname "*gpucache*" -exec rm -rf {} +
ui_print "- GPU Cache Cleaning Completed."

ui_print " "
