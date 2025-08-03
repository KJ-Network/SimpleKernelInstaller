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

# Get dtbo partition name
if [ ! -e /dev/block/bootdevice/by-name/dtbo* ]; then
    export dtbo="null"
elif test -z "$(getprop ro.boot.slot_suffix)"; then
    export dtbo="/dev/block/bootdevice/by-name/dtbo"
else
    export dtbo="/dev/block/bootdevice/by-name/dtbo$(getprop ro.boot.slot_suffix)"
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
    mv kernel_dtb kernel_dtb_origin
    magiskboot split $MODPATH/Image.gz-dtb
    mv kernel_dtb $MODPATH/new.dtb
    mv kernel_dtb_origin kernel_dtb
elif [ -e $MODPATH/Image-dtb ]; then
    mv kernel_dtb kernel_dtb_origin
    magiskboot split $MODPATH/Image-dtb
    mv kernel_dtb $MODPATH/new.dtb
    mv kernel_dtb_origin kernel_dtb
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
    user_choice_dtb=$(Key_monitoring)
    if [ $user_choice_dtb == "volume_up" ]; then
        mv $MODPATH/*.dtb kernel_dtb
    fi
fi
ui_print "- Repacking 'Boot' Image..."
magiskboot repack $MODPATH/boot.img
ui_print "- Flashing 'Boot' Image..."
dd if=new-boot.img of=$boot
if [ -e $MODPATH/dtbo.img ] && [ $dtbo != "null" ]; then
    ui_print "- dtbo.img detected! Please select:"
    ui_print "- Volume Up: Install dtbo.img (Recommended)"
    ui_print "- Volume Down: Skip install dtbo.img"
    user_choice_dtbo=$(Key_monitoring)
    if [ $user_choice_dtbo == "volume_up" ]; then
        ui_print "- Flashing 'Dtbo' Image..."
        dd if=$MODPATH/dtbo.img of=$dtbo
    fi
fi
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
