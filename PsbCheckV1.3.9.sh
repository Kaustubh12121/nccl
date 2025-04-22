#!/bin/bash

# Dell - FRYER - PSB Check - ver. 1.3.9

# Source and use it in another script:
# . ./PSBCheck.sh
# PSBCheckMain -s
#

function hex2dec()
{
  addr="$(echo $1 | sed 's| .*$||' | sed 's|\.|:|')"
  IFS=':' read -r -a arr <<< "$addr"
  echo "10#[$((16#${arr[0]})):$((16#${arr[1]})).$((16#${arr[2]}))]"
}



function GetSlotNumber()
{
  #PsbSlotCheckList=("#38" "#39" "#37" "#36" "#32" "#33" "#34" "#35")
  #PsbRootPortMap=(1 1 2 2 4 4 3 3)
  #PsbPortNameList=("CPU1 P0" "CPU1 P2" "CPU1 P3" "CPU1 P4" "CPU2 P0" "CPU2 P2" "CPU2 P3" "CPU2 P4")
  #PsbConnectorMap=("R1" "SL13, SL14" "SL3, SL4" "SL7, SL8" "SL11, SL12" "R4" "SL1, SL2" "SL5, SL6")
  SlotNumber=""
  CapPtr=$(setpci -s $1 34.b)
  while [ "$CapPtr" != "00" ] && [ "$CapPtr" != "FF" ];
  do
    CapID=$(setpci -s $1 $CapPtr.b )
    if [ "$CapID" == "10" ]; then
      if [ $(($((16#$(setpci -s $1 $(printf "%x" $(expr $((16#$CapPtr)) + 2 )).w)))&$((16#100)))) -ne 0 ];then
        SlotCap=$( setpci -s $1  $(printf "%x" $(expr $((16#$CapPtr)) + $((16#14)) )).l)
        PysicalSlot=$(($((16#$SlotCap))&$((16#FFF80000))))
        SlotNumber=$(($PysicalSlot>>19))
      fi
      break
    fi
    NextCapPtr=$( setpci -s $1  $(printf "%x" $(expr $((16#$CapPtr)) + 1 )).b)
    CapPtr=$NextCapPtr
  done
  echo $SlotNumber
}


function ScanBridge()
{
  ScanBus=$1
  for d in $(lspci -s 0000:$ScanBus: | cut -d " " -f 1)
  do
    #if [  "$(lspci -vvv -s $d | grep DeviceName)" != "" ]; then
    #   printf "\t%s\n" "$(lspci -vvv -s $d | grep DeviceName | xargs)"
    #fi
    printf "\t\t"
    for ((j = 0; j < $2; j++))
    do
      printf "\t"
    done
    for ((j = 0; j < $2; j++))
    do
      printf "+"
    done
    printf " %s\n" "$(lspci -s $d | xargs)"
    printf "\t\t\t"
    for ((j = 0; j < $2; j++))
    do
      printf "\t"
    done
    for ((j = 0; j < $2; j++))
    do
      printf "  "
    done
    printf " %s\n" "$(lspci -vvv -s $d | grep LnkSta: | xargs)"
    if [ "$(setpci -s $d b.B)" == "06" ];then
      ScanBridge $(setpci -s $d 19.b) $(expr $2 + 1)
    fi
  done
}


function SimpleScanBridge()
{
  ScanBus=$1
  for d in $(lspci -s 0000:$ScanBus: | cut -d " " -f 1)
  do
    #if [  "$(lspci -vvv -s $d | grep DeviceName)" != "" ]; then
    #   printf "\t%s\n" "$(lspci -vvv -s $d | grep DeviceName | xargs)"
    #fi
    echo "[PSB-$3] [Connector - $4] [End Device] [$(lspci -s $d | xargs)] $(printf "%s" "$(lspci -vvv -s $d | grep LnkSta: | xargs)")"
    if [ "$(setpci -s $d b.B)" == "06" ];then
      SimpleScanBridge $(setpci -s $d 19.b) $(expr $2 + 1) $3 $4
    fi
  done
}

SubDid=$(setpci -s $(lspci -d 1000:c030 | cut -d " " -f 1 | head -n 1) b6.W)
case "$SubDid" in
  "224a")
    PsbSlotCheckList=("#22" "#24" "#23" "#21")
    PsbRootPortMap=("SW1" "SW1" "SW2" "SW2")
    PsbPortNameList=("CPU1 P3" "CPU1 P4" "CPU2 P3" "CPU2 P4")
    PsbConnectorMap=("SL3, SL4" "SL7, SL8" "SL1, SL2" "SL5, SL6")
  ;;
  "224b")
    PsbSlotCheckList=("#38" "#39" "#37" "#36" "#32" "#33" "#34" "#35")
    PsbRootPortMap=(1 1 2 2 4 4 3 3)
    PsbPortNameList=("CPU1 P0" "CPU1 P2" "CPU1 P3" "CPU1 P4" "CPU2 P0" "CPU2 P2" "CPU2 P3" "CPU2 P4")
    PsbConnectorMap=("R1" "SL13, SL14" "SL3, SL4" "SL7, SL8" "SL11, SL12" "R4" "SL1, SL2" "SL5, SL6")
  ;;
  "224c")
    PsbSlotCheckList=("#22" "#24" "#23" "#21")
    PsbRootPortMap=("SW2" "SW2" "SW1" "SW1")
    PsbPortNameList=("CPU1 P3" "CPU1 P4" "CPU2 P3" "CPU2 P4")
    PsbConnectorMap=("SL3, SL4" "SL7, SL8" "SL1, SL2" "SL5, SL6")
  ;;
  "22f7")
    PsbSlotCheckList=("#38" "#37" "#32" "#34")
    PsbRootPortMap=(1 2 4 3)
    PsbPortNameList=("CPU1 P0" "CPU1 P4" "CPU2 P0" "CPU2 P4")
    PsbConnectorMap=("R1" "SL7, SL8" "SL11, SL12" "SL5, SL6")
  ;;

esac


function fullview()
{
  echo ================================================================================
  echo "Info: Model Name: $(dmidecode -t 1 | grep Product | cut -d ":" -f 2)"
  echo "Info: PSB SSDID: $SubDid"
  for RootBus in $(lspci -d 8086:352a | cut -d " " -f 1 | cut -d : -f 1)
  do
    #echo $RootBus
    SecBus=$(printf "%x" $(expr $(printf "%d" 0x$RootBus) + 1))
    if [ "$(setpci -s $SecBus:00.0 00.L)" == "c0301000" ]; then
      DownStreamBus=$(printf "%x" $(expr $(printf "%d" 0x$SecBus) + 1))
      for ((i=0; i<${#PsbRootPortMap[@]}; i++))
      do
        #echo  ${PsbSlotCheckList[$i]}
        #lspci -vvv -s 0000:$DownStreamBus: | grep ${PsbSlotCheckList[$i]},
        if [ "$(lspci -vvv -s 0000:$DownStreamBus: | grep ${PsbSlotCheckList[$i]},)" != "" ]; then
          echo ================================================================================
          echo PSB-${PsbRootPortMap[$i]} - RootPort[${PsbPortNameList[$i]}]: $RootBus:01.0
          echo Root Port to PSB Link Status - $(printf "\t\t%s\n" "$(lspci -vvv -s $RootBus:01.0 | grep LnkSta: | xargs)")
          echo PSB Upstream Port: $SecBus:0.0
          echo Connector: ${PsbConnectorMap[$i]}
          echo ================================================================================
          for downstream in $(lspci -s 0000:$DownStreamBus: | cut -d " " -f 1)
          do
            PhysicalNumber=$(GetSlotNumber $downstream)
            if [ $(($PhysicalNumber)) -ne 0 ];then
              if [ $(($PhysicalNumber&128)) -eq 128 ];then
                echo Bay $(($(($PhysicalNumber&96))>>5)) Slot $(($PhysicalNumber & 31)):
              else
                echo Slot $PhysicalNumber:
              fi
            fi
            echo Downstream Port: $downstream
            #echo Downstream Port: $downstream $(lspci -vvv -s $downstream | grep DeviceName | xargs)
            echo Downstream Port Link Status - $(printf "\t\t%s\n" "$(lspci -vvv -s $downstream | grep LnkSta: | xargs)")
            DeviceBus=$(setpci -s $downstream 19.b)
            for device in $(lspci -s 0000:$DeviceBus: | cut -d " " -f 1)
            do
              if [  "$(lspci -vvv -s $device | grep DeviceName)" != "" ]; then
                printf "\t%s\n" "$(lspci -vvv -s $device | grep DeviceName | xargs)"
              fi
              printf "\t%s\n" "$(lspci -s $device | xargs)"
              printf "\t\t%s\n" "$(lspci -vvv -s $device | grep LnkSta: | xargs)"
              if [ "$(setpci -s $device b.B)" == "06" ];then
                ScanBridge $(setpci -s $device 19.B) 1
              fi
            done
            echo ------------------------------------------------------------------------------
          done
          echo ================================================================================
        fi
      done
    fi
  done
  echo ================================================================================
}


function simpleview()
{
  echo "Info: Model Name: $(dmidecode -t 1 | grep Product | cut -d ":" -f 2)"
  echo "Info: PSB SSDID: $SubDid"
  for RootBus in $(lspci -d 8086:352a | cut -d " " -f 1 | cut -d : -f 1)
  do
    #echo $RootBus
    SecBus=$(printf "%x" $(expr $(printf "%d" 0x$RootBus) + 1))
    if [ "$(setpci -s $SecBus:00.0 00.L)" == "c0301000" ]; then
      DownStreamBus=$(printf "%x" $(expr $(printf "%d" 0x$SecBus) + 1))
      for ((i=0; i<${#PsbRootPortMap[@]}; i++))
      do
        #echo  ${PsbSlotCheckList[$i]}
        #lspci -vvv -s 0000:$DownStreamBus: | grep ${PsbSlotCheckList[$i]},
        if [ "$(lspci -vvv -s 0000:$DownStreamBus: | grep ${PsbSlotCheckList[$i]},)" != "" ]; then
          #echo ================================================================================
          #echo PSB-${PsbRootPortMap[$i]} - RootPort[${PsbPortNameList[$i]}]: $RootBus:01.0
          #echo Root Port to PSB Link Status - $(printf "\t\t%s\n" "$(lspci -vvv -s $RootBus:01.0 | grep LnkSta: | xargs)")
          #echo PSB Upstream Port: $SecBus:0.0
          #echo Connector: ${PsbConnectorMap[$i]}
          #echo ================================================================================
          echo "[PSB-${PsbRootPortMap[$i]}]; [Connector - ${PsbConnectorMap[$i]}]; [[ Root Port - ${PsbPortNameList[$i]} $(lspci -s $RootBus:01.0 | xargs) ]]; ; $(printf "%s" "$(lspci -vvv -s $RootBus:01.0 | grep LnkSta: | xargs | sed 's|LnkSta: ||')")"
          echo "[PSB-${PsbRootPortMap[$i]}]; [Connector - ${PsbConnectorMap[$i]}]; [[ UpstreamPort: $(lspci -s $SecBus:00.0 | xargs) ]]; ; $(printf "%s" "$(lspci -vvv -s $SecBus:00.0 | grep LnkSta: | xargs | sed 's|LnkSta: ||')")"

          for downstream in $(lspci -s 0000:$DownStreamBus: | cut -d " " -f 1)
          do
            PhysicalNumber=$(GetSlotNumber $downstream)
            if [ $(($PhysicalNumber)) -eq 0 ];then
              downstreamX=$(echo "[PSB-${PsbRootPortMap[$i]}]; [Connector: ${PsbConnectorMap[$i]}]; [[ DownstreamPort: $(lspci -s $downstream | xargs) | $(hex2dec "$(lspci -s $downstream)") ]]; ; $(printf "%s" "$(lspci -vvv -s $downstream | grep LnkSta: | xargs)"| sed 's|LnkSta: ||')")
            else
              if [ $(($PhysicalNumber&128)) -eq 128 ];then
                SlotName=$(echo Bay $(($(($PhysicalNumber&96))>>5)) Slot $(($PhysicalNumber & 31)))
              else
                SlotName=$(echo Slot $PhysicalNumber)
              fi
              downstreamX=$(echo "[PSB-${PsbRootPortMap[$i]}]; [Connector: ${PsbConnectorMap[$i]}]; [[ DownstreamPort: $(lspci -s $downstream | xargs) | $(hex2dec "$(lspci -s $downstream)") ]]; $SlotName; $(printf "%s" "$(lspci -vvv -s $downstream | grep LnkSta: | xargs | sed 's|LnkSta: ||')")")
            fi
            #echo Downstream Port: $downstream
            #echo Downstream Port: $downstream $(lspci -vvv -s $downstream | grep DeviceName | xargs)
            #echo Downstream Port Link Status - $(printf "\t\t%s\n" "$(lspci -vvv -s $downstream | grep LnkSta: | xargs)")
            DeviceBus=$(setpci -s $downstream 19.b)
            for device in $(lspci -s 0000:$DeviceBus: | cut -d " " -f 1)
            do
              DeviceName="$(lspci -vvv -s $device | grep DeviceName | sed 's|^.*DeviceName: ||')"
              echo "$downstreamX; [[EndDevice]] $(lspci -s $device | xargs)] | $(hex2dec "$(lspci -s $device)") ; [$DeviceName] ; $(printf "%s" "$(lspci -vvv -s $device | grep LnkSta: | xargs | sed 's|LnkSta: ||')")"

              if [ "$(setpci -s $device b.B)" == "06" ];then
                SimpleScanBridge $(setpci -s $device 19.B) 1 ${PsbRootPortMap[$i]} ${PsbConnectorMap[$i]}
              fi
            done
          done
        fi
      done
    fi
  done
}


function PSBCheckMain()
{
  if [ "$1" == "-s" ];then
    simpleview
  else
    if [ "$1" == "-f" ];then
      fullview
    else
      simpleview
      fullview
    fi
  fi
}


(return 0 &>/dev/null) || PSBCheckMain "$@"
