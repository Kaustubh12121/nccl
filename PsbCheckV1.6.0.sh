# Dell - FRYER - PSB Check - ver. 1.6.0

# Source and use it in another script:
# . ./PSBCheck.sh
# PSBCheckMain -s

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
	if [  "$(lspci -vvv -s $d | grep DeviceName)" != "" ]; then
      DeviceName="$(lspci -vvv -s $d | grep DeviceName | sed 's|^.*DeviceName: ||')"
      echo "$3"" ; [[EndDevice]] $(lspci -s $d | xargs)] ; [$DeviceName] ; $(printf "%s" "$(lspci -vvv -s $d | grep LnkSta: | xargs | sed 's|LnkSta: ||')")"
    else
      echo "$3"" ; [[EndDevice]] $(lspci -s $d | xargs)] ; $(printf "%s" "$(lspci -vvv -s $d | grep LnkSta: | xargs | sed 's|LnkSta: ||')")"
    fi
	if [ "$(setpci -s $d b.B)" == "06" ];then
      SimpleScanBridge $(setpci -s $d 19.b) $(expr $2 + 1) "$3"
    fi
  done
}

SubDid=$(setpci -s $(lspci -d 1000:c030 | cut -d " " -f 1 | head -n 1) b6.W)
case "$SubDid" in
  #---------------------------------------New SSDID of DecFY25 (4.160.3.0)---------------------------------------
  #Fork U.2/E3 (new PSB FW)
  "236b" | "236c")
    PsbSlotCheckList=("#22" "#24" "#23" "#21")
    PsbRootPortMap=("SW1" "SW1" "SW2" "SW2")
    PsbPortNameList=("CPU1 P3" "CPU1 P4" "CPU2 P3" "CPU2 P4")
    PsbConnectorMap=("SL3, SL4" "SL7, SL8" "SL1, SL2" "SL5, SL6")
  ;;
  #Fryer U.2 (new PSB FW)
  "2330" | "2331" | "2332" | "2333") 
    PsbSlotCheckList=("#38" "#39" "#37" "#36" "#32" "#33" "#34" "#35")
    PsbRootPortMap=(1 1 2 2 4 4 3 3)
    PsbPortNameList=("CPU1 P0" "CPU1 P2" "CPU1 P3" "CPU1 P4" "CPU2 P0" "CPU2 P2" "CPU2 P3" "CPU2 P4")
    PsbConnectorMap=("R1" "SL13, SL14" "SL3, SL4" "SL7, SL8" "SL11, SL12" "R4" "SL1, SL2" "SL5, SL6")
  ;;
  #Fryer E3 (new PSB FW)
  "236d" | "236e" | "236f" | "2370") 
    PsbSlotCheckList=("#38" "#39" "#37" "#36" "#32" "#33" "#34" "#35")
    PsbRootPortMap=(1 1 2 2 4 4 3 3)
    PsbPortNameList=("CPU1 P0" "CPU1 P2" "CPU1 P3" "CPU1 P4" "CPU2 P0" "CPU2 P2" "CPU2 P3" "CPU2 P4")
    PsbConnectorMap=("R1" "SL13, SL14" "SL3, SL4" "SL7, SL8" "SL11, SL12" "R4" "SL1, SL2" "SL5, SL6")
  ;;
  #Moss U.2 (new PSB FW)
  "2371" | "2372")
    PsbSlotCheckList=("#22" "#24" "#23" "#21")
    PsbRootPortMap=("SW2" "SW2" "SW1" "SW1")
    PsbPortNameList=("CPU1 P3" "CPU1 P4" "CPU2 P3" "CPU2 P4")
    PsbConnectorMap=("SL3, SL4" "SL7, SL8" "SL1, SL2" "SL5, SL6")
  ;;
  #Moss E3 (new PSB FW)
  "2373" | "2374")
    PsbSlotCheckList=("#22" "#24" "#23" "#21")
    PsbRootPortMap=("SW2" "SW2" "SW1" "SW1")
    PsbPortNameList=("CPU1 P3" "CPU1 P4" "CPU2 P3" "CPU2 P4")
    PsbConnectorMap=("SL3, SL4" "SL7, SL8" "SL1, SL2" "SL5, SL6")
  ;;
  #----------------------------------------PSB SSDID (RTS PSB F/W version)----------------------------------------
  #Fork U.2/E3 (old PSB FW)
  "224a")
    PsbSlotCheckList=("#22" "#24" "#23" "#21")
    PsbRootPortMap=("SW1" "SW1" "SW2" "SW2")
    PsbPortNameList=("CPU1 P3" "CPU1 P4" "CPU2 P3" "CPU2 P4")
    PsbConnectorMap=("SL3, SL4" "SL7, SL8" "SL1, SL2" "SL5, SL6")
  ;;
  #Fryer (old PSB FW)
  "224b") 
    PsbSlotCheckList=("#38" "#39" "#37" "#36" "#32" "#33" "#34" "#35")
    PsbRootPortMap=(1 1 2 2 4 4 3 3)
    PsbPortNameList=("CPU1 P0" "CPU1 P2" "CPU1 P3" "CPU1 P4" "CPU2 P0" "CPU2 P2" "CPU2 P3" "CPU2 P4")
    PsbConnectorMap=("R1" "SL13, SL14" "SL3, SL4" "SL7, SL8" "SL11, SL12" "R4" "SL1, SL2" "SL5, SL6")
  ;;
  #Moss U.2/E3 (old PSB FW)
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
  for RootBus in $(lspci -d 8086:352a | cut -d " " -f 1 | cut -d : -f 1) #8086:352a is intel root port controller
  do
    #echo $RootBus
    SecBus=$(printf "%x" $(expr $(printf "%d" 0x$RootBus) + 1))
    if [ "$(setpci -s $SecBus:00.0 00.L)" == "c0301000" ]; then #check if scendary bus is PSB (c0301000) class code
      DownStreamBus=$(printf "%x" $(expr $(printf "%d" 0x$SecBus) + 1))
      for ((i=0; i<${#PsbRootPortMap[@]}; i++))
      do
        #echo  ${PsbSlotCheckList[$i]}
        #lspci -vvv -s 0000:$DownStreamBus: | grep ${PsbSlotCheckList[$i]},
        if [ "$(lspci -vvv -s 0000:$DownStreamBus: | grep ${PsbSlotCheckList[$i]},)" != "" ]; then
          echo ================================================================================
          echo PSB-${PsbRootPortMap[$i]} - RootPort[${PsbPortNameList[$i]}]: $RootBus:01.0
          echo Root Port to PSB Link Status - $(printf "\t\t%s\n" "$(lspci -vvv -s $RootBus:01.0 | grep LnkSta: | xargs)")
          echo PSB SSDID: $(setpci -s $SecBus:00.0 b6.W) #Add PSB SSDID for individual PSB
          echo PSB Upstream Port: $SecBus:00.0
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
                echo scanbridge
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
          echo "[PSB-${PsbRootPortMap[$i]} SSDID: $(setpci -s $SecBus:00.0 b6.W)]; [Connector - ${PsbConnectorMap[$i]}]; [[ Root Port - ${PsbPortNameList[$i]} $(lspci -s $RootBus:01.0 | xargs) ]]; ; $(printf "%s" "$(lspci -vvv -s $RootBus:01.0 | grep LnkSta: | xargs | sed 's|LnkSta: ||')")"
          echo "[PSB-${PsbRootPortMap[$i]} SSDID: $(setpci -s $SecBus:00.0 b6.W)]; [Connector - ${PsbConnectorMap[$i]}]; [[ UpstreamPort: $(lspci -s $SecBus:00.0 | xargs) ]]; ; $(printf "%s" "$(lspci -vvv -s $SecBus:00.0 | grep LnkSta: | xargs | sed 's|LnkSta: ||')")"

          for downstream in $(lspci -s 0000:$DownStreamBus: | cut -d " " -f 1)
          do
            PhysicalNumber=$(GetSlotNumber $downstream)
            if [ $(($PhysicalNumber)) -eq 0 ];then
              downstreamX=$(echo "[PSB-${PsbRootPortMap[$i]} SSDID: $(setpci -s $SecBus:00.0 b6.W)]; [Connector: ${PsbConnectorMap[$i]}]; [[ DownstreamPort: $(lspci -s $downstream | xargs) ]]; ; $(printf "%s" "$(lspci -vvv -s $downstream | grep LnkSta: | xargs)"| sed 's|LnkSta: ||')")
            else
              if [ $(($PhysicalNumber&128)) -eq 128 ];then
                SlotName=$(echo Bay $(($(($PhysicalNumber&96))>>5)) Slot $(($PhysicalNumber & 31)))
              else
                SlotName=$(echo Slot $PhysicalNumber)
              fi
              downstreamX=$(echo "[PSB-${PsbRootPortMap[$i]} SSDID: $(setpci -s $SecBus:00.0 b6.W)]; [Connector: ${PsbConnectorMap[$i]}]; [[ DownstreamPort: $(lspci -s $downstream | xargs) ]]; $SlotName; $(printf "%s" "$(lspci -vvv -s $downstream | grep LnkSta: | xargs | sed 's|LnkSta: ||')")")
            fi
            #echo Downstream Port: $downstream
            #echo Downstream Port: $downstream $(lspci -vvv -s $downstream | grep DeviceName | xargs)
            #echo Downstream Port Link Status - $(printf "\t\t%s\n" "$(lspci -vvv -s $downstream | grep LnkSta: | xargs)")
            DeviceBus=$(setpci -s $downstream 19.b)
            for device in $(lspci -s 0000:$DeviceBus: | cut -d " " -f 1)
            do
              #DeviceName=$(printf "\t%s\n" "$(lspci -vvv -s $device | grep DeviceName)")
			  if [  "$(lspci -vvv -s $device | grep DeviceName)" != "" ]; then
                DeviceName="$(lspci -vvv -s $device | grep DeviceName | sed 's|^.*DeviceName: ||')"
                echo "$downstreamX; [[EndDevice]] $(lspci -s $device | xargs)] ; [$DeviceName] ; $(printf "%s" "$(lspci -vvv -s $device | grep LnkSta: | xargs | sed 's|LnkSta: ||')")"
              else
			    echo "$downstreamX; [[EndDevice]] $(lspci -s $device | xargs)] ; $(printf "%s" "$(lspci -vvv -s $device | grep LnkSta: | xargs | sed 's|LnkSta: ||')")"
			  fi
			  #echo "[$downstreamX] [PSB-${PsbRootPortMap[$i]}] [Connector - ${PsbConnectorMap[$i]}] [End Device] [$(lspci -s $device | xargs)] [$DeviceName] $(printf "%s" "$(lspci -vvv -s $device | grep LnkSta: | xargs)")"

              if [ "$(setpci -s $device b.B)" == "06" ];then
                SimpleScanBridge $(setpci -s $device 19.B) 1 "$downstreamX"
              fi
            done
          done
        fi
      done
    fi
  done
}


function version_info()
{ echo "Version Info:"
  echo "Version 1.6.0"
  echo "  + Added a new PSB SSDID for Fryer/Fork/Moss due to PSB FW update"
  echo "  + Added a -info function to show version infor and PSB SSDIDs table"
  echo "  + Added -help function"
  echo "Version 1.5.0"
  echo "  + Added a table of PSB SSDID '2330'~'2333' for XE9680 (Fryer) due to PSB FW update"
  echo "  + Show PSB SSDID of individual PSB"
}
function PSB_SSDID()
{
echo ""
echo "PSB SSDID Table:"
# Print the headers
echo -e "\t\tPSB SSID (RTS PSB F/W version)\tNew SSID of DecFY25 (4.160.3.0)"
echo -e "\t\tPSB1\tPSB2\tPSB3\tPSB4\tPSB1\tPSB2\tPSB3\tPSB4"

# Print the data rows
echo -e "Fryer U.2\t224B\t224B\t224B\t224B\t2330\t2331\t2332\t2333"
echo -e "Fryer E.3\t224B\t224B\t224B\t224B\t236D\t236E\t236F\t2370"
echo -e "Fork U2/E3\t224A\t224A\t\t236B\t236C\t\t"
echo -e "Moss U.2\t224C\t224C\t\t2371\t2372\t\t"
echo -e "Moss E.3\t224C\t224C\t\t2373\t2374\t\t"
}
function help()
{
  echo "-s show simple view"
  echo "-f show full view"
  echo "-info show version information and PSB SSDID table"
}
function PSBCheckMain()
{
  if [ "$1" == "-s" ];then
    simpleview
  else
    if [ "$1" == "-f" ];then
      fullview
    else
      if [ "$1" == "-info" ];then
        version_info
        PSB_SSDID
      else
        if [ "$1" == "-help" ];then
          help
        else
          simpleview
          fullview
        fi
      fi
    fi
  fi
}


(return 0 &>/dev/null) || PSBCheckMain "$@"

