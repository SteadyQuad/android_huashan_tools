#!/bin/bash
ScriptDir=$PWD;
TimeStart=$(date +%s);
source $ScriptDir/android_set_variables.rc;
FilePaths=(\
           "boot.img" \
           "system/bin/surfaceflinger" \
           "system/framework/framework.jar" \
           "system/framework/framework-res.apk" \
           "system/framework/org.cyanogenmod.hardware.jar" \
           "system/framework/services.jar" \
           "system/framework/telephony-common.jar" \
           "system/framework/wifi-service.jar" \
           "system/lib/libandroid_servers.so" \
           "system/lib/libaudiopolicyservice.so" \
           "system/lib/libhardware.so" \
           "system/lib/libRS.so" \
           "system/lib/libRSCpuRef.so" \
           "system/lib/libRSDriver.so" \
           "system/lib/libsurfaceflinger.so" \
           "system/lib/libsurfaceflinger_ddmconnection.so" \
           "system/lib/hw/hwcomposer.msm8960.so" \
           "system/lib/modules/*" \
           "system/priv-app/Dialer/Dialer.apk" \
           "system/priv-app/Settings/Settings.apk" \
           "system/priv-app/SettingsProvider/SettingsProvider.apk" \
           "system/priv-app/SystemUI/SystemUI.apk" \
           "system/priv-app/Telecom/Telecom.apk" \
           );
ModulesNames=(\
              "bootimage" \
              "Dialer" \
              "framework" \
              "framework-res" \
              "hwcomposer.msm8960" \
              "Keyguard" \
              "libandroid_servers" \
              "libaudiopolicyservice" \
              "libhardware" \
              "libRS" \
              "libRSCpuRef" \
              "libRSDriver" \
              "libsurfaceflinger" \
              "libsurfaceflinger_ddmconnection" \
              "org.cyanogenmod.hardware" \
              "services" \
              "services.core" \
              "Settings" \
              "SettingsProvider" \
              "SystemUI" \
              "Telecom" \
              "telephony-common" \
              "wifi-service" \
              );

if [[ "$2" == "manual" ]]; then
  AddonsFile="addons-cm-12.1-"$(date +'%Y%m%d')"-NIGHTLY-$PhoneName-TEST.zip";
else
  AddonsFile="addons-cm-12.1-"$(date +'%Y%m%d')"-NIGHTLY-$PhoneName.zip";
fi;

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
  mka -B -j $BuildJobs ${ModulesNames[*]} | tee $LogFile;

  LogMemory=$(grep "make: fork" $LogFile | sort | uniq);
  LogFail=$(grep "fail" $LogFile | sort | uniq);
  LogError=$(grep "Error" $LogFile | sort | uniq);
  LogInstall=$(grep "Install:.*target/product" $LogFile | sort | uniq);
  echo "$LogMemory";
  echo "$LogFail";
  echo "$LogError";
  echo "$LogInstall";
  echo "";

  if [ -z "$(grep "make failed to build" $LogFile | uniq)" ]; then
    LaunchBuild=0;
  elif [ ! -z "$1" ]; then
    return;
  else
    LaunchBuild=1;
    printf " Press Enter to restart the build... ";
    if [ -z "$1" ]; then
      read key;
    else
      return;
    fi;
    echo "";
    echo "";
  fi;

done;

cd $OutDir;
FilesList="";
for FilePath in ${FilePaths[*]}
do
  FilesList="$FilesList ./$FilePath";
done;

echo "";
echo " [ Building the new zip ]";
echo "";

if [ -f "$TargetDir/$AddonsFile" ]; then
  rm -f "$TargetDir/$AddonsFile";
fi;

cp "$ScriptDir/android_files/addons_template.zip" "$TargetDir/$AddonsFile.unsigned.zip";
zip -g "$TargetDir/$AddonsFile.unsigned.zip" $FilesList;
SignApkDir=$ScriptDir/android_signapk;
java -jar "$SignApkDir/signapk-cm121.jar" -w "$SignApkDir/testkey.x509.pem" "$SignApkDir/testkey.pk8" "$TargetDir/$AddonsFile.unsigned.zip" "$TargetDir/$AddonsFile";
rm -f "$TargetDir/$AddonsFile.unsigned.zip";

export AndroidResult="$TargetDir/$AddonsFile";

echo "";
echo "  $AddonsFile created.";
echo "";
TimeDiff=$(($(date +%s)-$TimeStart));

echo "";
echo " [ Done in $TimeDiff secs ]";
echo "";

if [ -z "$1" ]; then
  read key;
fi;
echo "";
