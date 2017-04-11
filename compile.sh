#!/bin/bash

# find out where we are, we should be in the toplevel mega65-core dir
BASEDIR=$(pwd)
# ise compile-script output dir
SCROUTDIR="megascript"


# ensure these directories exists, if not, make them
LOGDIR="build-logs"
if test ! -e    "${BASEDIR}/${LOGDIR}"; then
  echo "Creating ${BASEDIR}/${LOGDIR}"
  mkdir          ${BASEDIR}/${LOGDIR}
fi
if test ! -e    "${BASEDIR}/sdcard-files"; then
  echo "Creating ${BASEDIR}/sdcard-files"
  mkdir          ${BASEDIR}/sdcard-files
fi
if test ! -e    "${BASEDIR}/sdcard-files/old-bitfiles"; then
  echo "Creating ${BASEDIR}/sdcard-files/old-bitfiles"
  mkdir          ${BASEDIR}/sdcard-files/old-bitfiles
fi


TARGET="nonddr" # filename to indicate target is Nexys4 (non-ddr) board
# if the file exists, target the non-ddr board
if test -e ${BASEDIR}/${TARGET}; then
  echo "Compiling for the Nexys4 (non-DDR) board."
  UCF_TARGET_FPGA="../../../src/vhdl/container-nonddr.ucf"
  TARGET_TAG="${TARGET}"
else
  echo "Compiling for the Nexys4DDR board (the default)."
  echo "To compile for the Nexys4 (non-DDR) board, the \"./${TARGET}\" file must exist"
  UCF_TARGET_FPGA="../../../src/vhdl/container-ddr.ucf"
  TARGET_TAG="ddr"
fi


# pre-compile
( cd src ; make generated_vhdl firmware ../doc/iomap.md tools utilities roms)
retcode=$?
#
if test ! $retcode = 0; then
  echo "make failed with return code $retcode" && exit 1
else
  echo "make completed."
  echo " "
fi


# here we need to detect if you have 64 or 32 bit machine
# on a 64-bit installation, both 32 and 64 bit settings files exist.
# on a 32-bit installation, only the settings32 exists.
# -> so first check for the 64-bit settings file.
#
#       special case/path for Colossus Supercomputer
if [ -e /usr/local/Xilinx/14.7/ISE_DS/settings64.sh ]; then
  echo "Detected 64-bit Xilinx installation on Colossus"
  source /usr/local/Xilinx/14.7/ISE_DS/settings64.sh
#       standard install location for 32/64 bit Xilinx installation
elif [ -e /opt/Xilinx/14.7/ISE_DS/settings64.sh ]; then
  echo "Detected 64-bit Xilinx installation"
  source /opt/Xilinx/14.7/ISE_DS/settings64.sh
#       standard install location for 32/64 bit Xilinx installation
elif [ -e /opt/Xilinx/14.7/ISE_DS/settings32.sh ]; then
  echo "Detected 32-bit Xilinx installation"
  source /opt/Xilinx/14.7/ISE_DS/settings32.sh
else
  echo "Cannot detect a Xilinx installation"
  exit 0;
fi
echo " "


# time for the output filenames
datetime2=`date +%m%d%H%M`
# gitstring for the output filenames, results in '10bef97' or similar
gitstring=`git describe --always --abbrev=7 --dirty=~`
# git status of 'B'ranch in 'S'hort format, for the output filename
branch=`git status -b -s | head -n 1`
# get from charpos3, for 6 chars
branch2=${branch:3:6}


# timestamp the compile-logs
outfile0="${BASEDIR}/${LOGDIR}/compile-${datetime2}_0.log"
outfile1="${BASEDIR}/${LOGDIR}/compile-${datetime2}_1-xst.log"
outfile2="${BASEDIR}/${LOGDIR}/compile-${datetime2}_2-ngd.log"
outfile3="${BASEDIR}/${LOGDIR}/compile-${datetime2}_3-map.log"
outfile4="${BASEDIR}/${LOGDIR}/compile-${datetime2}_4-par.log"
outfile5="${BASEDIR}/${LOGDIR}/compile-${datetime2}_5-trc.log"
outfile6="${BASEDIR}/${LOGDIR}/compile-${datetime2}_6-bit.log"


# debug
echo "Compiling for the Nexys4${TARGET_TAG} board" >> $outfile0


# ISE build parameters
ISE_COMMON_OPTS="-intstyle ise"
ISE_NGDBUILD_OPTS="-p xc7a100t-csg324-1 -dd _ngo -sd ../../../ipcore_dir -nt timestamp"
ISE_MAP_OPTS="-p xc7a100t-csg324-1 -w -logic_opt on -ol high -t 1 -xt 0 -register_duplication on -r 4 -mt off -ir off -ignore_keep_hierarchy -pr b -lc off -power off"
ISE_PAR_OPTS="-w -ol std -mt off"
ISE_TRCE_OPTS="-v 3 -s 1 -n 3 -fastpaths -xml"


# move into here so that all the ISE-generated output does not fill the base directory
cd ${BASEDIR}/ise147pn/mega65-${TARGET_TAG}/working
echo "Changing into:"
pwd
echo " "

# create the nessessary ISE build-artifact directories
if test ! -e    "${BASEDIR}/ise147pn/mega65-${TARGET_TAG}/working/xst/"; then
  echo "Creating ${BASEDIR}/ise147pn/mega65-${TARGET_TAG}/working/xst/"
  mkdir          ${BASEDIR}/ise147pn/mega65-${TARGET_TAG}/working/xst/
fi
if test ! -e    "${BASEDIR}/ise147pn/mega65-${TARGET_TAG}/working/xst/projnav.tmp/"; then
  echo "Creating ${BASEDIR}/ise147pn/mega65-${TARGET_TAG}/working/xst/projnav.tmp/"
  mkdir          ${BASEDIR}/ise147pn/mega65-${TARGET_TAG}/working/xst/projnav.tmp
fi


# debug, put the git-commit-ID in the first log file.
echo ${gitstring} > $outfile0
# put the git-branch-ID in the log file.
echo ${branch}  >> $outfile0
echo ${branch2} >> $outfile0


# convenient path to access the ISE build-artifacts
SCROUTDIR_FULL="${BASEDIR}/ise147pn/mega65-${TARGET_TAG}/working/${SCROUTDIR}"
#
if test ! -e    "${SCROUTDIR_FULL}"; then
  echo "Creating ${SCROUTDIR_FULL}"
  mkdir          ${SCROUTDIR_FULL}
fi


# begin the ISE build:
echo "Beginning the ISE build."
echo "Check ./${LOGDIR}/compile-<datetime>-X.log for the log files, X={1,2,3,4,5,6}"
echo " "

cat ${BASEDIR}/src/version.a65
pwd
echo " "


#
# ISE: synthesize
#
datetime=`date +%Y%m%d_%H:%M:%S`
echo "==> $datetime Starting: xst, see container.syr"
xst ${ISE_COMMON_OPTS} -ifn "container.xst" -ofn "${SCROUTDIR_FULL}/container.syr" >> $outfile1
retcode=$?
if [ $retcode -ne 0 ] ; then
  echo "xst failed with return code $retcode" &&
  cat $outfile1 | grep ERROR
  exit 1
else
  cat $outfile1 | grep WARN
fi


#
# ISE: ngdbuild
#
datetime=`date +%Y%m%d_%H:%M:%S`
echo "==> $datetime Starting: ngdbuild, see container.bld"
ngdbuild ${ISE_COMMON_OPTS} ${ISE_NGDBUILD_OPTS} -uc ${UCF_TARGET_FPGA} container.ngc ${SCROUTDIR_FULL}/container.ngd > $outfile2
retcode=$?
if [ $retcode -ne 0 ] ; then
  echo "ngdbuild failed with return code $retcode" &&
  cat $outfile2 | grep ERROR
  exit 1
else
  cat $outfile2 | grep WARN
fi

#
# ISE: map
#
datetime=`date +%Y%m%d_%H:%M:%S`
echo "==> $datetime Starting: map, see container_map.mrp"
map ${ISE_COMMON_OPTS} ${ISE_MAP_OPTS} -o ${SCROUTDIR_FULL}/container_map.ncd ${SCROUTDIR_FULL}/container.ngd ${SCROUTDIR_FULL}/container.pcf > $outfile3
retcode=$?
if [ $retcode -ne 0 ] ; then
  echo "map failed with return code $retcode" &&
  cat $outfile3 | grep ERROR
  exit 1
else
  cat $outfile3 | grep WARN
fi

#
# ISE: place and route
#
datetime=`date +%Y%m%d_%H:%M:%S`
echo "==> $datetime Starting: par, see container.par"
par ${ISE_COMMON_OPTS} ${ISE_PAR_OPTS} ${SCROUTDIR_FULL}/container_map.ncd ${SCROUTDIR_FULL}/container.ncd ${SCROUTDIR_FULL}/container.pcf > $outfile4
retcode=$?
if [ $retcode -ne 0 ] ; then
  echo "par failed with return code $retcode" &&
  cat $outfile4 | grep ERROR
  exit 1
else
  cat $outfile4 | grep WARN
fi

#
# ISE: trace
#
datetime=`date +%Y%m%d_%H:%M:%S`
echo "==> $datetime Starting: trce, see container.twr"
trce ${ISE_COMMON_OPTS} ${ISE_TRCE_OPTS} ${SCROUTDIR_FULL}/container.twx ${SCROUTDIR_FULL}/container.ncd -o ${SCROUTDIR_FULL}/container.twr ${SCROUTDIR_FULL}/container.pcf > $outfile5
retcode=$?
if [ $retcode -ne 0 ] ; then
  echo "trce failed with return code $retcode" &&
  cat $outfile5 | grep ERROR
  exit 1
else
  cat $outfile5 | grep WARN
fi

#
# ISE: bitgen
#
datetime=`date +%Y%m%d_%H:%M:%S`
echo "==> $datetime Starting: bitgen, see container.bgn"
bitgen ${ISE_COMMON_OPTS} -f container.ut ${SCROUTDIR_FULL}/container.ncd > $outfile6
retcode=$?
if [ $retcode -ne 0 ] ; then
  echo "bitgen failed with return code $retcode" &&
  cat $outfile6 | grep ERROR
  exit 1
else
  cat $outfile6 | grep WARN
fi


#
# ISE -> all done
#
datetime=`date +%Y%m%d_%H:%M:%S`
echo "==> $datetime Finished!"
echo "Refer to compile[1-6].*.log for the output of each Xilinx command."

# find interesting build stats and append them to the 0.log file.
echo "From $outfile1: =================================================" >> $outfile0
 tail -n 9 $outfile1 >> $outfile0
echo "From $outfile2: =================================================" >> $outfile0
 grep "Total" $outfile2 >> $outfile0
echo "From $outfile3: =================================================" >> $outfile0
 tail -n 8 $outfile3 >> $outfile0
echo "From $outfile4: =================================================" >> $outfile0
 grep "Generating Pad Report" -A 100 $outfile4 >> $outfile0
echo "From $outfile5: =================================================" >> $outfile0
 tail -n 1 $outfile5 >> $outfile0
echo "From $outfile6: =================================================" >> $outfile0
 echo "Nil" >> $outfile0
echo " "


## now prepare the sdcard-output directory by moving any existing bit-file
if test -e                ${BASEDIR}/sdcard-files/*.bit; then
  echo "Found OLD bit files, so will move them."
  for filename in ${BASEDIR}/sdcard-files/*.bit; do
    echo " mv ${filename} ${BASEDIR}/sdcard-files/old-bitfiles"
           mv ${filename} ${BASEDIR}/sdcard-files/old-bitfiles
  done
else
  echo "No existing bit files found."
fi
echo " "


# now copy the bit-file to the sdcard-output directory, and timestamp it with time and git-status
echo "cp ${SCROUTDIR_FULL}/container.bit ${BASEDIR}/sdcard-files/bit${datetime2}_${branch2}_${gitstring}_${TARGET_TAG}.bit"
cp       ${SCROUTDIR_FULL}/container.bit ${BASEDIR}/sdcard-files/bit${datetime2}_${branch2}_${gitstring}_${TARGET_TAG}.bit
echo " "

ls -al ${BASEDIR}/sdcard-files
