#!/bin/bash
ScriptDir=$PWD;
TimeStart=$(date +%s);
source $ScriptDir/android_set_variables.rc;
KernelPath="boot.img";
FilePaths=("system/lib/modules/");
ModulesNames=("bootimage");

if [ -f $TargetDir/$FilePath ]; then rm $TargetDir/$FilePath; fi;

cd $AndroidDir/;
source ./build/envsetup.sh;
croot;
breakfast $PhoneName;

LaunchBuild=1;
while [ $LaunchBuild != 0 ];
do

  echo "";
  echo " [ Making the requested libraries ]";
  echo "";
  cd $AndroidDir/;
  mka -j $BuildJobs ${ModulesNames[*]} | tee $LogFile;
  echo "";

  if [ -z "$(grep "make failed to build" $LogFile | uniq)" ]; then
    LaunchBuild=0;
  else
    LaunchBuild=1;
    printf " Press Enter to restart the build... ";
    read key;
    echo "";
    echo "";
  fi;

done;

TimeDiff=$(($(date +%s)-$TimeStart));
if [ "$(ls -A $TargetDir)" ]; then
  cp $OutDir/$KernelPath $TargetDir/$KernelPath;
fi;

echo "";
echo "  \"fastboot flash boot $KernelPath & fastboot reboot\"";

adbPush=1;
while [ $adbPush != 0 ];
do
  echo "";
  echo "";
  echo " [ Upload new modules files - Debugging USB ]";
  echo "";
  printf "  Press enter to continue...";
  read key;

  echo "";
  adbPush=0;
  $ScriptDir/android_root_adb.sh;
  OutDir=$AndroidDir/out/target/product/$PhoneName;
  for FilePath in ${FilePaths[*]}
  do
    adb push $OutDir/$FilePath /$FilePath;
    if [ $? != 0 ]; then adbPush=1; fi;
  done;

  if [ $adbPush == 0 ]; then
    echo "";
    echo " Rebooting to bootloader...";
    echo "";
    sleep 5;
    adb reboot bootloader;
  fi;
done;

echo "";
echo "";
echo " [ Upload new kernel - Bootloader USB ]";
echo "";
echo "";
cd $OutDir/;
sudo fastboot flash boot $KernelPath;
sudo fastboot reboot;

echo "";
echo " [ Done in $TimeDiff secs ]";
echo "";
read key;
