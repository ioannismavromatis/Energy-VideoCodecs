#!/bin/bash

##########################################################################
########################   Global Variables  #############################
##########################################################################

source settings.cfg

rootpath=$(pwd)

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

    if [[ ! -z $(ls -l $rootpath/metrics/) ]]; then
        echo "PSNR folder not empty - remove all files and directories"
        rm -r $rootpath/metrics
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
        mkdir -p ./metrics/${codec}
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

    sleep $delay
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

    for fullname in ./input/*.yuv; do

        name=${fullname##*/}
        filename=${name%.yuv}
        echo "Run the process for: "$filename
        resolution=$(echo $filename | awk '{ split($0,ar,"_"); print ar[2]}')
        width=$(echo $resolution | awk '{ split($0,ar,"x"); print ar[1]}')
        height=$(echo $resolution | awk '{ split($0,ar,"x"); print ar[2]}')
        frames=$(echo $filename | awk '{ split($0,ar,"_"); print ar[6]}')
        frames=${frames%??????}

        fps=$(echo $filename | awk '{ split($0,ar,"_"); print ar[3]}')
        fps=${fps%???}

        # ffmpeg -i ./input/$filename.mp4 -n ./input/$filename.yuv
    
        # H264 encoding / decoding
        if [[ ${CODECs[@]} =~ "h264" ]]; then
            
            codec="h264"
            for crf in "${CRFsInit[@]}"; do
                encodeFullName="${filename}_encoded_crf_${crf}_${iteration}"
                videoEncodeName="${filename}_encoded_crf_${crf}"
                encodeFullPath="./encoded/$codec/"$videoEncodeName".yuv"
                
                decodeFullName="${filename}_decoded_crf_${crf}_${iteration}"
                videoDecodeName="${filename}_decoded_crf_${crf}"
                decodeFullPath="./decoded/$codec/"$videoDecodeName".yuv"

                export FFREPORT=file=./ffmpeg/$codec/$encodeFullName.log:level=32
                if [[ $powerProfile == "true" ]]; then
                    ./intelgadget ./csv/$codec/${encodeFullName}.csv &
                    ./sampleCPU.sh ./samplecpu/$codec/${encodeFullName} ffmpeg &
                fi
                if [[ $encodeFFMPEG == "true" ]]; then
                    ffmpeg  -s $resolution -y -r $fps -pix_fmt yuv420p10le -i ./input/${filename}.yuv -c:v libx264  -preset ${presetFFMPEG}  -crf ${crf}  $encodeFullPath
                fi
                killProcesses

                export FFREPORT=file=./ffmpeg/$codec/$decodeFullName.log:level=32
                if [[ $powerProfile == "true" ]]; then
                    ./intelgadget ./csv/$codec/${decodeFullName}.csv &
                    ./sampleCPU.sh ./samplecpu/$codec/${decodeFullName} ffmpeg &
                fi
                if [[ $decodeFFMPEG == "true" ]]; then
                    ffmpeg -i $encodeFullPath -y $decodeFullPath
                fi
                killProcesses

                # ffmpeg -i $encodeFullPath -i ./input/${filename}.mp4 -lavfi libvmaf="model_path=vmaf_v0.6.1.pkl":log_path=vmaf_logfile.txt -f null –
                PSNR_SSIM_filename="${filename}_crf_${crf}"
                if [[ $enableMetrics == "true" ]] && [[ $iteration == $RUN_ITERATIONS ]]; then
                    if [[ $width == "3840" ]]; then
                        vmafModel="vmaf_4k_v0.6.1"
                    else
                        vmafModel="vmaf_v0.6.1"
                    fi
                    
                    # ffmpeg -i $encodeFullPath -i ./input/${filename}.mp4 -lavfi psnr=stats_file=./psnr/$codec/${PSNR_SSIM_filename}.txt -f null –
                    # ffmpeg -i $encodeFullPath -i ./input/${filename}.mp4 -lavfi ssim=stats_file=./ssim/$codec/${PSNR_SSIM_filename}.txt -f null -
                    ./vmafrun --reference ./input/${filename}.yuv --distorted ${decodeFullPath} --width $width --height $height --pixel_format 420 --bitdepth 10 --feature psnr --feature float_ssim --feature float_ms_ssim --threads 18 --model version=${vmafModel} --csv --output ./metrics/${codec}/${PSNR_SSIM_filename}.csv
                    
                    rm ./decoded/${codec}/*
                fi
            done
        fi

        sleep $delay

        # H265 encoding / decoding
        if [[ ${CODECs[@]} =~ "h265" ]]; then

            codec="h265"
            for crf in "${CRFsInit[@]}"; do
                encodeFullName="${filename}_encoded_crf_${crf}_${iteration}"
                videoEncodeName="${filename}_encoded_crf_${crf}"
                encodeFullPath="./encoded/$codec/"$videoEncodeName".mp4"
                
                decodeFullName="${filename}_decoded_crf_${crf}_${iteration}"
                videoDecodeName="${filename}_decoded_crf_${crf}"
                decodeFullPath="./decoded/$codec/"$videoDecodeName".yuv"

                export FFREPORT=file=./ffmpeg/$codec/$encodeFullName.log:level=32
                if [[ $powerProfile == "true" ]]; then
                    ./intelgadget ./csv/$codec/${encodeFullName}.csv &
                    ./sampleCPU.sh ./samplecpu/$codec/${encodeFullName} ffmpeg &
                fi
                if [[ $encodeFFMPEG == "true" ]]; then
                    ffmpeg  -s $resolution -y -r $fps -pix_fmt yuv420p10le -i ./input/${filename}.yuv -c:v libx265  -preset ${presetFFMPEG}  -crf ${crf}  $encodeFullPath
                fi
                killProcesses

                export FFREPORT=file=./ffmpeg/$codec/$decodeFullName.log:level=32
                if [[ $powerProfile == "true" ]]; then
                    ./intelgadget ./csv/$codec/${decodeFullName}.csv &
                    ./sampleCPU.sh ./samplecpu/$codec/${decodeFullName} ffmpeg &
                fi
                if [[ $decodeFFMPEG == "true" ]]; then
                    ffmpeg -i $encodeFullPath -y $decodeFullPath
                fi
                killProcesses

                # ffmpeg -i $encodeFullPath -i ./input/${filename}.mp4 -lavfi libvmaf="model_path=vmaf_v0.6.1.pkl":log_path=vmaf_logfile.txt -f null –
                PSNR_SSIM_filename="${filename}_crf_${crf}"
                if [[ $enableMetrics == "true" ]] && [[ $iteration == $RUN_ITERATIONS ]]; then
                    if [[ $width == "3840" ]]; then
                        vmafModel="vmaf_4k_v0.6.1"
                    else
                        vmafModel="vmaf_v0.6.1"
                    fi
                    
                    # ffmpeg -i $encodeFullPath -i ./input/${filename}.mp4 -lavfi psnr=stats_file=./psnr/$codec/${PSNR_SSIM_filename}.txt -f null –
                    # ffmpeg -i $encodeFullPath -i ./input/${filename}.mp4 -lavfi ssim=stats_file=./ssim/$codec/${PSNR_SSIM_filename}.txt -f null -
                    ./vmafrun --reference ./input/${filename}.yuv --distorted ${decodeFullPath} --width $width --height $height --pixel_format 420 --bitdepth 10 --feature psnr --feature float_ssim --feature float_ms_ssim --threads 18 --model version=${vmafModel} --csv --output ./metrics/${codec}/${PSNR_SSIM_filename}.csv
                    
                    rm ./decoded/${codec}/*
                fi

            done
        fi

        sleep $delay

        # VP9 encoding / decoding
        # ffmpeg -s 1920x1080 -r 60 -pix_fmt yuv420p10le -i ./input/S11AirAcrobatic_1920x1080_60fps_10bit_420.yuv -c:v libvpx-vp9 -crf 55 -b:v 0 -row-mt 1 encoded_vp9.yuv
        if [[ ${CODECs[@]} =~ "vp9" ]]; then

            codec="vp9"
            for crf in "${CRFsMapped[@]}"; do
                encodeFullName="${filename}_encoded_crf_${crf}_${iteration}"
                videoEncodeName="${filename}_encoded_crf_${crf}"
                encodeFullPath="./encoded/$codec/"$videoEncodeName".mp4"
                
                decodeFullName="${filename}_decoded_crf_${crf}_${iteration}"
                videoDecodeName="${filename}_decoded_crf_${crf}"
                decodeFullPath="./decoded/$codec/"$videoDecodeName".yuv"

                export FFREPORT=file=./ffmpeg/$codec/$encodeFullName.log:level=32
                if [[ $powerProfile == "true" ]]; then
                    ./intelgadget ./csv/$codec/${encodeFullName}.csv &
                    ./sampleCPU.sh ./samplecpu/$codec/${encodeFullName} ffmpeg &
                fi
                if [[ $encodeFFMPEG == "true" ]]; then
                    ffmpeg  -s $resolution -y -r $fps -pix_fmt yuv420p10le -i ./input/${filename}.yuv -c:v libvpx-vp9 -row-mt 1 -crf ${crf} -b:v 0 $encodeFullPath
                fi
                killProcesses

                export FFREPORT=file=./ffmpeg/$codec/$decodeFullName.log:level=32
                if [[ $powerProfile == "true" ]]; then
                    ./intelgadget ./csv/$codec/${decodeFullName}.csv &
                    ./sampleCPU.sh ./samplecpu/$codec/${decodeFullName} ffmpeg &
                fi
                if [[ $decodeFFMPEG == "true" ]]; then
                    ffmpeg -i $encodeFullPath -y $decodeFullPath
                fi
                killProcesses

                # ffmpeg -i $encodeFullPath -i ./input/${filename}.mp4 -lavfi libvmaf="model_path=vmaf_v0.6.1.pkl":log_path=vmaf_logfile.txt -f null –
                PSNR_SSIM_filename="${filename}_crf_${crf}"
                if [[ $enableMetrics == "true" ]] && [[ $iteration == $RUN_ITERATIONS ]]; then
                    if [[ $width == "3840" ]]; then
                        vmafModel="vmaf_4k_v0.6.1"
                    else
                        vmafModel="vmaf_v0.6.1"
                    fi
                    
                    # ffmpeg -i $encodeFullPath -i ./input/${filename}.mp4 -lavfi psnr=stats_file=./psnr/$codec/${PSNR_SSIM_filename}.txt -f null –
                    # ffmpeg -i $encodeFullPath -i ./input/${filename}.mp4 -lavfi ssim=stats_file=./ssim/$codec/${PSNR_SSIM_filename}.txt -f null -
                    ./vmafrun --reference ./input/${filename}.yuv --distorted ${decodeFullPath} --width $width --height $height --pixel_format 420 --bitdepth 10 --feature psnr --feature float_ssim --feature float_ms_ssim --threads 18 --model version=${vmafModel} --csv --output ./metrics/${codec}/${PSNR_SSIM_filename}.csv
                    
                    rm ./decoded/${codec}/*
                fi

            done
        fi
        
        sleep $delay
        
        # AV1 encoding / decoding
        # ./SvtAv1EncApp -i ./input/D1BasketballPass_416x240_50fps_10bit_420.yuv --fps 50 --input-depth 10 --qp 63  -w 832 -h 480 -n 1550 -b test.ivf
        if [[ ${CODECs[@]} =~ "av1" ]]; then

            codec="av1"
            for crf in "${CRFsMapped[@]}"; do
                encodeFullName="${filename}_encoded_crf_${crf}_${iteration}"
                videoEncodeName="${filename}_encoded_crf_${crf}"
                encodeFullPath="./encoded/$codec/"$videoEncodeName".ivf"
                
                decodeFullName="${filename}_decoded_crf_${crf}_${iteration}"
                videoDecodeName="${filename}_decoded_crf_${crf}"
                decodeFullPath="./decoded/$codec/"$videoDecodeName".yuv"

                if [[ $powerProfile == "true" ]]; then
                    ./intelgadget ./csv/$codec/${encodeFullName}.csv &
                    ./sampleCPU.sh ./samplecpu/$codec/${encodeFullName} SvtAv1EncApp &
                fi
                if [[ $encodeFFMPEG == "true" ]]; then
                    # ffmpeg  -s $resolution -y -r $fps -pix_fmt yuv420p10le -i ./input/${filename}.yuv -row-mt 1 -tiles 2x2 -strict -2 -c:v libaom-av1 -crf ${crf} -b:v 0 $encodeFullPath
                    ./SvtAv1EncApp -i ./input/${filename}.yuv --fps $fps --input-depth 10 --qp ${crf}  -w $width -h $height -n $frames --preset $presetAVI1 --enable-stat-report 1 --stat-file ./ffmpeg/$codec/$encodeFullName.log -b $encodeFullPath
                fi
                killProcesses

                if [[ $powerProfile == "true" ]]; then
                    ./intelgadget ./csv/$codec/${decodeFullName}.csv &
                    ./sampleCPU.sh ./samplecpu/$codec/${decodeFullName} SvtAv1DecApp &
                fi
                if [[ $decodeFFMPEG == "true" ]]; then
                    # ffmpeg -i $encodeFullPath -y $decodeFullPath
                    ./SvtAv1DecApp -i $encodeFullPath -o $decodeFullPath -bit-depth 10 -w $width -h $height -colour-space 420 -fps-frm -fps-summary
                fi
                killProcesses

                # ffmpeg -i $encodeFullPath -i ./input/${filename}.mp4 -lavfi libvmaf="model_path=vmaf_v0.6.1.pkl":log_path=vmaf_logfile.txt -f null –
                PSNR_SSIM_filename="${filename}_crf_${crf}"
                if [[ $enableMetrics == "true" ]] && [[ $iteration == $RUN_ITERATIONS ]]; then
                    if [[ $width == "3840" ]]; then
                        vmafModel="vmaf_4k_v0.6.1"
                    else
                        vmafModel="vmaf_v0.6.1"
                    fi
                    
                    # ffmpeg -i $encodeFullPath -i ./input/${filename}.mp4 -lavfi psnr=stats_file=./psnr/$codec/${PSNR_SSIM_filename}.txt -f null –
                    # ffmpeg -i $encodeFullPath -i ./input/${filename}.mp4 -lavfi ssim=stats_file=./ssim/$codec/${PSNR_SSIM_filename}.txt -f null -
                    ./vmafrun --reference ./input/${filename}.yuv --distorted ${decodeFullPath} --width $width --height $height --pixel_format 420 --bitdepth 10 --feature psnr --feature float_ssim --feature float_ms_ssim --threads 18 --model version=${vmafModel} --csv --output ./metrics/${codec}/${PSNR_SSIM_filename}.csv
                    
                    rm ./decoded/${codec}/*
                fi

            done
        fi

        # VVC encoding / decoding
        # ./vvencapp -s 1920x1080 -r 60 -c yuv420_10 -i ./input/S12CatRobot1_1920x1080_60fps_10bit_420.yuv --preset faster  -q 51 -o test.yuv
        if [[ ${CODECs[@]} =~ "vvc" ]]; then

            codec="vvc"
            for crf in "${CRFsInit[@]}"; do
                encodeFullName="${filename}_encoded_crf_${crf}_${iteration}"
                videoEncodeName="${filename}_encoded_crf_${crf}"
                encodeFullPath="./encoded/$codec/"$videoEncodeName".266"
                
                decodeFullName="${filename}_decoded_crf_${crf}_${iteration}"
                videoDecodeName="${filename}_decoded_crf_${crf}"
                decodeFullPath="./decoded/$codec/"$videoDecodeName".yuv"

                if [[ $powerProfile == "true" ]]; then
                    ./intelgadget ./csv/$codec/${encodeFullName}.csv &
                    ./sampleCPU.sh ./samplecpu/$codec/${encodeFullName} vvencapp &
                fi
                if [[ $encodeFFMPEG == "true" ]]; then
                    ./vvencapp -s $resolution -r $fps -c yuv420_10 -i ./input/${filename}.yuv --preset ${presetVVC}  -q ${crf} -o $encodeFullPath | tee ./ffmpeg/$codec/$encodeFullName.log
                fi
                killProcesses

                if [[ $powerProfile == "true" ]]; then
                    ./intelgadget ./csv/$codec/${decodeFullName}.csv &
                    ./sampleCPU.sh ./samplecpu/$codec/${decodeFullName} vvdecapp &
                fi
                if [[ $decodeFFMPEG == "true" ]]; then
                    ./vvdecapp -b $encodeFullPath -o $decodeFullPath | tee ./ffmpeg/$codec/$decodeFullName.log
                fi
                killProcesses

                # ffmpeg -i $encodeFullPath -i ./input/${filename}.mp4 -lavfi libvmaf="model_path=vmaf_v0.6.1.pkl":log_path=vmaf_logfile.txt -f null –
                PSNR_SSIM_filename="${filename}_crf_${crf}"
                if [[ $enableMetrics == "true" ]] && [[ $iteration == $RUN_ITERATIONS ]]; then
                    if [[ $width == "3840" ]]; then
                        vmafModel="vmaf_4k_v0.6.1"
                    else
                        vmafModel="vmaf_v0.6.1"
                    fi
                    
                    # ffmpeg -i $encodeFullPath -i ./input/${filename}.mp4 -lavfi psnr=stats_file=./psnr/$codec/${PSNR_SSIM_filename}.txt -f null –
                    # ffmpeg -i $encodeFullPath -i ./input/${filename}.mp4 -lavfi ssim=stats_file=./ssim/$codec/${PSNR_SSIM_filename}.txt -f null -
                    ./vmafrun --reference ./input/${filename}.yuv --distorted ${decodeFullPath} --width $width --height $height --pixel_format 420 --bitdepth 10 --feature psnr --feature float_ssim --feature float_ms_ssim --threads 18 --model version=${vmafModel} --csv --output ./metrics/${codec}/${PSNR_SSIM_filename}.csv
                    
                    rm ./decoded/${codec}/*
                fi

            done
        fi
    done
done