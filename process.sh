#!/bin/bash

##########################################################################
########################   Global Variables  #############################
##########################################################################

rootpath=$(pwd)
preset="veryslow" # FFMPEG setting for H264 and H265 codecs
RUN_ITERATIONS=3 # number of times to execute for all the different codecs, videos, and CRFs
deleteFiles="false" # by default the existing files will not be removed

runIdleTest="true"  # true or false - to enable or disable the initial idle test experimentation
IDLE_ITERATIONS=10 # number of times that the idle power sampling will be executed
IDLE_TEST_LENGTH=60 # the idle power test lenth - in seconds

declare -a CODECs=( "h264" "h265" "vp9" )
# declare -a CODECs=( "h264" "h265" "vp9" "av1" )

# declare -a CRFs=( 51 )
# declare -a CRFs=( 0 18 23 28 51 )
declare -a CRFs=( 15 35 51 )

##########################################################################
###########################   Functions  #################################
##########################################################################

function deletePrevious () {
    if [[ ! -z $(ls -l $rootpath/encoded/) ]]; then
        echo "Encoding folder not empty - remove all files and directories"
        rm -r $rootpath/encoded
    fi

    if [[ ! -z $(ls -l $rootpath/decoded/) ]]; then
        echo "Decoding folder not empty - remove all files and directories"
        rm -r $rootpath/decoded
    fi

    if [[ ! -z $(ls -l $rootpath/csv/) ]]; then
        echo "CSV folder not empty - remove all files and directories"
        rm -r $rootpath/csv
    fi

    if [[ ! -z $(ls -l $rootpath/samplecpu/) ]]; then
        echo "SampleCPU folder not empty - remove all files and directories"
        rm -r $rootpath/samplecpu
    fi

    if [[ ! -z $(ls -l $rootpath/ffmpeg/) ]]; then
        echo "FFMPEG folder not empty - remove all files and directories"
        rm -r $rootpath/ffmpeg
    fi

    if [[ ! -z $(ls -l $rootpath/psnr/) ]]; then
        echo "FFMPEG folder not empty - remove all files and directories"
        rm -r $rootpath/psnr
    fi

    if [[ ! -z $(ls -l $rootpath/ssim/) ]]; then
        echo "FFMPEG folder not empty - remove all files and directories"
        rm -r $rootpath/ssim
    fi

    if [[ ! -z $(ls -l $rootpath/idle) ]]; then
        echo "Idle folder not empty - remove all files and directories"
        rm -r $rootpath/idle
    fi

    createNewFolderStructure
}

function createNewFolderStructure () {
    for codec in "${CODECs[@]}"; do
        mkdir -p ./encoded/${codec}
        mkdir -p ./decoded/${codec}
        mkdir -p ./csv/${codec}
        mkdir -p ./samplecpu/${codec}
        mkdir -p ./ffmpeg/${codec}
        mkdir -p ./psnr/${codec}
        mkdir -p ./ssim/${codec}
        mkdir -p ./idle
    done
}

function checkArgument () {

    while [[ $deleteFiles != "y" ]] && [[ $deleteFiles != "Y" ]] && [[ $deleteFiles != "n" ]] && [[ $deleteFiles != "N" ]]; do
        read -p echo "Wrong argument was given - "$deleteFiles" - You should pass Y/y or N/n: " deleteFiles
    done

    if [[ $deleteFiles == "Y" ]] || [[ $deleteFiles == "y" ]]; then
        deleteFiles="true"
    fi
}

function killProcesses () {
    # Kill sampleCPU script
    pid=$(ps -ax | grep sampleCPU | grep -v grep |  awk '{print $1}')
    if [[ ! -z "$pid" ]]; then
        kill -15 $pid
    fi

    # Kill intelgadget script
    pid=$(ps -ax | grep intelgadget | grep -v grep |  awk '{print $1}')
    if [[ ! -z "$pid" ]]; then
        kill -15 $pid
    fi

    sleep 10
}

function runIdle () {
    for iteration in $(seq 1 $IDLE_ITERATIONS); do 
        
        echo "Run Idle Power test for $IDLE_TEST_LENGTH seconds"
        logfile="idle_"${iteration}
        ./intelgadget ./idle/${logfile}.csv &
        sleep $IDLE_TEST_LENGTH;
        killProcesses

    done
}

function checkRunningInstances () {
    noneRunning="true"

    pidToKill=()
    pid=$(ps -ax | grep sampleCPU | grep -v grep |  awk '{print $1}')
    if [[ ! -z "$pid" ]]; then
        noneRunning="false"
        echo "SampleCPU is running"
        pidToKill+=($pid)
    fi

    pid=$(ps -ax | grep intelgadget | grep -v grep |  awk '{print $1}')
    if [[ ! -z "$pid" ]]; then
        noneRunning="false"
        echo "Intelgadget is running"
        pidToKill+=($pid)
    fi

    pid=$(ps -ax | grep ffmpeg | grep -v grep |  awk '{print $1}')
    if [[ ! -z "$pid" ]]; then
        noneRunning="false"
        echo "Ffmpeg is running"
        pidToKill+=($pid)
    fi

    if [[ $noneRunning == "false" ]]; then
        echo "One or a number of processes are running that shouldn't! Make sure you kill them before running this script!"
        read -p "Do you want to kill them now? [Y/n]: " killall
        
        while [[ $killall != "y" ]] && [[ $killall != "Y" ]] && [[ $killall != "n" ]] && [[ $killall != "N" ]]; do
            read -p "Wrong argument was given - "$killall" - You should pass Y/y or N/n: " killall
        done

        if [[ $killall == "Y" ]] || [[ $killall == "y" ]]; then
            for pid in "${pidToKill[@]}"; do
                kill -15 $pid
            done
        elif [[ $killall == "N" ]] || [[ $killall == "n" ]]; then
            echo "The program will be terminated. You should kill the processes before proceeding"
            exit
        fi
    fi
}

##########################################################################
#########################   End Functions  ###############################
##########################################################################

if [ $# -eq 0 ]; then
    read -p "Do you want to delete the previous files [Y/n]? " deleteFiles;
fi
checkArgument

checkRunningInstances

if [[ $deleteFiles == "true" ]]; then
    echo "Delete all previous files"
    deletePrevious
else
    createNewFolderStructure
fi

chmod +x sampleCPU.sh

# Run the Power Profiling during an idle state
if [[ $runIdleTest == "true" ]]; then
    runIdle
fi

# Run the Power Profiling for each codec
for iteration in $(seq 1 $RUN_ITERATIONS); do 

    for fullname in ./input/*.mp4; do

        name=${fullname##*/}
        filename=${name%.mp4}
        echo "Run the process for: "$filename
        resolution=$(echo $filename | awk '{ split($0,ar,"_"); print ar[2]}')

        ffmpeg -i ./input/$filename.mp4 -n ./input/$filename.yuv
    
        # H264 encoding / decoding
        if [[ ${CODECs[@]} =~ "h264" ]]; then
            
            codec="h264"
            for crf in "${CRFs[@]}"; do
                encodeName="${filename}_encoded_crf_${crf}_${iteration}"
                encodeFullPath="./encoded/$codec/"$encodeName".mp4"
                decodeName="${filename}_decoded_crf_${crf}_${iteration}"
                decodeFullPath="./decoded/$codec/"$encodeName".yuv"
                
                export FFREPORT=file=./ffmpeg/$codec/$encodeName.log:level=32
                ./intelgadget ./csv/$codec/${encodeName}.csv &
                ./sampleCPU.sh ./samplecpu/$codec/${encodeName} &
                ffmpeg  -s $resolution -n -r 60 -pix_fmt yuv420p10le -i ./input/${filename}.yuv -c:v libx264  -preset ${preset}  -crf ${crf}  $encodeFullPath
                killProcesses

                export FFREPORT=file=./ffmpeg/$codec/$decodeName.log:level=32
                ./intelgadget ./csv/$codec/${decodeName}.csv &
                ./sampleCPU.sh ./samplecpu/$codec/${decodeName} &
                ffmpeg -i $encodeFullPath $decodeFullPath
                killProcesses

                # ffmpeg -i $encodeFullPath -i ./input/${filename}.mp4 -lavfi libvmaf="model_path=vmaf_v0.6.1.pkl":log_path=vmaf_logfile.txt -f null –
                ffmpeg -i $encodeFullPath -i ./input/${filename}.mp4 -lavfi psnr=stats_file=./psnr/$codec/${filename}.txt -f null –
                ffmpeg -i $encodeFullPath -i ./input/${filename}.mp4 -lavfi ssim=stats_file=./ssim/$codec/${filename}.txt -f null -
            done
        fi

        sleep 10

        # H265 encoding / decoding
        if [[ ${CODECs[@]} =~ "h265" ]]; then

            codec="h265"
            for crf in "${CRFs[@]}"; do
                encodeName="${filename}_encoded_crf_${crf}_${iteration}"
                encodeFullPath="./encoded/$codec/"$encodeName".mp4"
                decodeName="${filename}_decoded_crf_${crf}_${iteration}"
                decodeFullPath="./decoded/$codec/"$encodeName".yuv"

                export FFREPORT=file=./ffmpeg/$codec/$encodeName.log:level=32
                ./intelgadget ./csv/$codec/${encodeName}.csv &
                ./sampleCPU.sh ./samplecpu/$codec/${encodeName} &
                ffmpeg  -s $resolution -n -r 60 -pix_fmt yuv420p10le -i ./input/${filename}.yuv -c:v libx265  -preset ${preset}  -crf ${crf}  $encodeFullPath
                killProcesses

                export FFREPORT=file=./ffmpeg/$codec/$decodeName.log:level=32
                ./intelgadget ./csv/$codec/${decodeName}.csv &
                ./sampleCPU.sh ./samplecpu/$codec/${decodeName} &
                ffmpeg -i $encodeFullPath $decodeFullPath
                killProcesses

                # ffmpeg -i $encodeFullPath -i ./input/${filename}.mp4 -lavfi libvmaf="model_path=vmaf_v0.6.1.pkl":log_path=vmaf_logfile.txt -f null –
                ffmpeg -i $encodeFullPath -i ./input/${filename}.mp4 -lavfi psnr=stats_file=./psnr/$codec/${filename}.txt -f null –
                ffmpeg -i $encodeFullPath -i ./input/${filename}.mp4 -lavfi ssim=stats_file=./ssim/$codec/${filename}.txt -f null -

            done
        fi

        sleep 10

        # VP9 encoding / decoding
        # ffmpeg -s 1920x1080 -r 60 -pix_fmt yuv420p10le -i ./input/S11AirAcrobatic_1920x1080_60fps_10bit_420.yuv -c:v libvpx-vp9 -crf 55 -b:v 0 -row-mt 1 encoded_vp9.yuv
        if [[ ${CODECs[@]} =~ "vp9" ]]; then

            codec="vp9"
            for crf in "${CRFs[@]}"; do
                encodeName="${filename}_encoded_crf_${crf}_${iteration}"
                encodeFullPath="./encoded/$codec/"$encodeName".mp4"
                decodeName="${filename}_decoded_crf_${crf}_${iteration}"
                decodeFullPath="./decoded/$codec/"$encodeName".yuv"

                export FFREPORT=file=./ffmpeg/$codec/$decodeName.log:level=32
                ./intelgadget ./csv/$codec/${encodeName}.csv &
                ./sampleCPU.sh ./samplecpu/$codec/${encodeName} &
                ffmpeg  -s $resolution -n -r 60 -pix_fmt yuv420p10le -i ./input/${filename}.yuv -c:v libvpx-vp9 -row-mt 1 -crf ${crf} -b:v 0 $encodeFullPath
                killProcesses

                export FFREPORT=file=./ffmpeg/$codec/$decodeName.log:level=32
                ./intelgadget ./csv/$codec/${decodeName}.csv &
                ./sampleCPU.sh ./samplecpu/$codec/${decodeName} &
                ffmpeg -i $encodeFullPath $decodeFullPath
                killProcesses

                # ffmpeg -i $encodeFullPath -i ./input/${filename}.mp4 -lavfi libvmaf="model_path=vmaf_v0.6.1.pkl":log_path=vmaf_logfile.txt -f null –
                ffmpeg -i $encodeFullPath -i ./input/${filename}.mp4 -lavfi psnr=stats_file=./psnr/$codec/${filename}.txt -f null –
                ffmpeg -i $encodeFullPath -i ./input/${filename}.mp4 -lavfi ssim=stats_file=./ssim/$codec/${filename}.txt -f null -

            done
        fi
        
        sleep 10
        
        # AV1 encoding / decoding
        # ffmpeg -i input.mp4 -c:v libaom-av1 -crf 30 -b:v 0 av1_test.mkv
        if [[ ${CODECs[@]} =~ "av1" ]]; then
            echo "Do nothing for now."
        fi
    done
done