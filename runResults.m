% RUNRESULTS Processes all the results for the codec comparison. 
%  Loads the settings from simSettings.m and runs the simulator. 
%
% Usage: runResults
%
% Copyright (c) 2020-2021, 
% email: 
% email: 

clc; clf; clear; clear global; close all;

fprintf('Results - Codec comparison\n');
fprintf('Copyright (c) 2020-2021, XXXX \n');
fprintf('email: \n');
fprintf('email: \n\n');


load('nullArray.mat')
nullArray = encodedArray2;

inputFolder = "./input/*.yuv";

CODECs =[ "h264" "h265" "vvc" "vp9" "av1" ]; 
CRFsInit = [ 22 27 32 37 42 ];
CRFsMapped= [ 27 33 40 46 52 ];
CRFsCodecMapping = [ 0 0 0 1 1 ];

iterations = 3;
idle_iterations = 10;

marker = [ 'o' '+' '*' 's' 'd'];
lineStyle = [ '-' '--' ':' '-.' '-' ];

col=@(x)reshape(x,numel(x),1);
boxplot2=@(C,varargin)boxplot(cell2mat(cellfun(col,col(C),'uni',0)),cell2mat(arrayfun(@(I)I*ones(numel(C{I}),1),col(1:numel(C)),'uni',0)),varargin{:});

% Add all the modules in the path
fprintf('Adding all modules and their subfolders to the path\n');
modules = {'functions'};

% Add each module in the path
for i = 1:length(modules)
    path = genpath(modules{i});
    addpath(path);
end

results = struct;


for iteration = 1:idle_iterations
    path = [ './idle/idle_' num2str(iteration) '.csv' ];
    idle = importCSV(path);
    idleArray = table2array(idle);
    results(iteration).idle = idleArray;
    toPlotIA{iteration} = str2double(idleArray(:,12));
    toPlotDRAM{iteration} = str2double(idleArray(:,19));
end

figure('units','normalized','outerposition',[0 0 1 1])

subplot(2,1,1)
boxplot2(toPlotIA)
title('Idle IA and DRAM power consumption (per 100ms)')
xlabel('Iteration')
ylabel('Watt (IA)')
set(gca,'FontSize', 18)

subplot(2,1,2)
boxplot2(toPlotDRAM)
xlabel('Iteration')
ylabel('Watt (DRAM)')
set(gca,'FontSize', 18)


[ names, fps, bit, chroma, baseName, resolution, NoFrames] = getFileNames(inputFolder);


for name = 1:length(names)
    for crf = 1:length(CRFsInit)
        for codec = 1:length(CODECs)
            for iteration = 1:iterations
                
                if ~CRFsCodecMapping(codec)
                    eval('CRFtoRead = CRFsInit')
                else
                    eval('CRFtoRead = CRFsMapped')
                end
                
                % Encoded Power profile
                path = [ './csv/' CODECs(codec) '/' names(name) '_encoded_crf_' CRFtoRead(crf) '_' iteration '.csv' ];
                path = strjoin(path,'');
               % encoded = importCSV(path);
               
                try
                    encoded = importCSV_RAPL(path);
                    encodedArray = table2array(encoded);
                catch
                    encodedArray = nullArray;
                end
                    
                
                avgWattsEncIA(iteration,codec,crf) = str2double(encodedArray(end,10))/str2double(encodedArray(end,3));
                cumWattsEncIA(iteration,codec,crf) = str2double(encodedArray(end,10));
                dataEncIA{iteration,codec,crf} = str2double(encodedArray(:,9));
                avgWattsEncDRAM(iteration,codec,crf) = str2double(encodedArray(end,20))/str2double(encodedArray(end,3));
                cumWattsEncDRAM(iteration,codec,crf) = str2double(encodedArray(end,20));
                dataEncDRAM{iteration,codec,crf} = str2double(encodedArray(:,19));
                
                % Decoded Power profile
                path = [ './csv/' CODECs(codec) '/' names(name) '_decoded_crf_' CRFtoRead(crf) '_' iteration '.csv' ];
                path = strjoin(path,'');
                
                try
                    decoded = importCSV_RAPL(path);
                    decodedArray = table2array(decoded);
                catch
                    decodedArray = nullArray;
                end
                
                avgWattsDecIA(iteration,codec,crf) = str2double(decodedArray(end,10))/str2double(decodedArray(end,3));
                cumWattsDecIA(iteration,codec,crf) = str2double(decodedArray(end,10));
                dataDecIA{iteration,codec,crf} = str2double(decodedArray(:,9));
                avgWattsDecDRAM(iteration,codec,crf) = str2double(decodedArray(end,20))/str2double(decodedArray(end,3));
                cumWattsDecDRAM(iteration,codec,crf) = str2double(decodedArray(end,20));
                dataDecDRAM{iteration,codec,crf} = str2double(decodedArray(:,19));
                 
%                 % CPU utilisation - encoder
%                 path = [ './samplecpu/' CODECs(codec) '/' names(name) '_encoded_crf_' CRFtoRead(crf) '_' iteration '.log' ];
%                 path = strjoin(path,'');
%                 dataCPUEnc{iteration,codec,crf} = importCPUUtilisation(path);
%                       
%                 % CPU utilisation - decoder
%                 path = [ './samplecpu/' CODECs(codec) '/' names(name) '_decoded_crf_' CRFtoRead(crf) '_' iteration '.log' ];
%                 path = strjoin(path,'');
%                 dataCPUDec{iteration,codec,crf} = importCPUUtilisation(path);
            end
            
            path = [ './metrics/' CODECs(codec) '/' names(name) '_crf_' CRFtoRead(crf) '.csv' ];
            path = strjoin(path,'');
            
            try 
                metricsQuality = readQualityMetrics(path);  
                dataPSNR{codec,crf} = metricsQuality.psnrY;
                dataSSIM{codec,crf} = metricsQuality.SSIM;        
                dataVMAF{codec,crf} = metricsQuality.VMAF;
            catch
                dataPSNR{codec,crf} = 0;
                dataSSIM{codec,crf} = 0;        
                dataVMAF{codec,crf} = 0;                
            end



            % Path to encoded video
            path = [ './encoded/' CODECs(codec) '/' names(name) '_encoded_crf_' CRFtoRead(crf) '.*' ];
            path = strjoin(path,'');
            
            s = dir(path);
            bitrate(codec,crf) = s.bytes * 8 * fps(name) / NoFrames(name)/1024; % Value to kbps
            
            averageCumEncIA = 0;
            for iteration = 1:iterations
                averageCumEncIA = averageCumEncIA + cumWattsEncIA(iteration,codec,crf);
            end
            averageCumEncIA = averageCumEncIA / iterations;
            
            averageCumEncDRAM = 0;
            for iteration = 1:iterations
                averageCumEncDRAM = averageCumEncDRAM + cumWattsEncDRAM(iteration,codec,crf);
            end
            averageCumEncDRAM = averageCumEncDRAM / iterations;
            
            averageCumEncOverall(codec,crf) = averageCumEncDRAM + averageCumEncIA;
        
        end
    end
    
    results(name).name = names(name);
    results(name).fps = fps(name);
    results(name).resolution = resolution(name);
    results(name).bit = bit(name);
    results(name).chroma = chroma(name);
    results(name).NoFrames = NoFrames(name);
    results(name).bitrate = bitrate;
    
    results(name).avgWattsEncIA = avgWattsEncIA;
    results(name).cumWattsEncIA = cumWattsEncIA;
    results(name).dataEncIA = dataEncIA;
    results(name).avgWattsEncDRAM = avgWattsEncDRAM;
    results(name).cumWattsEncDRAM = cumWattsEncDRAM;
    results(name).dataEncDRAM = dataEncDRAM;
    results(name).averageCumEncOverall = averageCumEncOverall;
    
    results(name).avgWattsDecIA = avgWattsDecIA;
    results(name).cumWattsDecIA = cumWattsDecIA;
    results(name).dataDecIA = dataDecIA;
    results(name).avgWattsDecDRAM = avgWattsDecDRAM;
    results(name).cumWattsDecDRAM = cumWattsDecDRAM;
    results(name).dataDecDRAM = dataDecDRAM;
    
%     results(name).dataCPUEnc = dataCPUEnc;
%     results(name).dataCPUDec = dataCPUDec;
    
    metrics(name).dataPSNR = dataPSNR;
    metrics(name).dataSSIM = dataSSIM;
end

metrics

% for name = 1:length(names)
%     %     Decoding CPU utilisation and Power
%     figure('units','normalized','outerposition',[0 0 1 1])
%     for iteration = 1:iterations
%         mydataRAPL = [];
%         mydataSampleCPU = [];
% 
%         for crf = 1:length(CRFs)
%             for codec = 1:length(CODECs)
%                 tmp(codec) = results(name).dataDecIA(iteration,codec,crf);                
%             end
%             
%             maxNumEl = max(cellfun(@numel,tmp));
%             Cpad = cellfun(@(x){padarray(x(:),[maxNumEl-numel(x),0],NaN,'post')}, tmp);
%             mydataRAPL{crf} = cell2mat(Cpad);
%             
%             for codec = 1:length(CODECs)
%                 tmp2(codec) = results(name).dataCPUDec(iteration,codec,crf);
%             end
%             maxNumEl = max(cellfun(@numel,tmp2));
%             Cpad = cellfun(@(x){padarray(x(:),[maxNumEl-numel(x),0],NaN,'post')}, tmp2);
%             mydataSampleCPU{crf} = cell2mat(Cpad);
%         end
%         
%         subplot(iterations,2,(iteration*2)-1)
%         
%         boxplotGroup(mydataRAPL, 'PrimaryLabels', {'15' '35' '51'}, 'SecondaryLabels', {'h264' 'h265' 'vp9'}, 'GroupLines', true);
%         str = [ 'Watts (No. of iteration = ' num2str(iteration) ')' ];
%         ylabel(str)
%         if (iteration == 1) 
%             str = [ names{name} ' - Decoder - IA Power (in Watts)' ];
%             title(str,'Interpreter', 'none', 'FontSize', 20)
%         end
%         
%         subplot(iterations,2,(iteration*2))
%         
%         boxplotGroup(mydataSampleCPU, 'PrimaryLabels', {'15' '35' '51'}, 'SecondaryLabels', {'h264' 'h265' 'vp9'}, 'GroupLines', true);
%         str = [ '% (No. of iteration = ' num2str(iteration) ')' ];
%         ylabel(str)
%         if (iteration == 1) 
%             str = [ names{name} ' - Decoder - CPU Utilisation (in %)' ];
%             title(str,'Interpreter', 'none', 'FontSize', 20)
%         end
%     end
%     
%     %     Decoding DRAM power
%     figure('units','normalized','outerposition',[0 0 1 1])
%     for iteration = 1:iterations
%         mydataRAPL = [];
%         for crf = 1:length(CRFs)
%             for codec = 1:length(CODECs)
%                 tmp(codec) = results(name).dataDecDRAM(iteration,codec,crf);
%             end
%             maxNumEl = max(cellfun(@numel,tmp));
%             Cpad = cellfun(@(x){padarray(x(:),[maxNumEl-numel(x),0],NaN,'post')}, tmp);
%             mydataRAPL{crf} = cell2mat(Cpad);
%             
%         end
%         subplot(iterations,1,iteration)
%         
%         boxplotGroup(mydataRAPL, 'PrimaryLabels', {'15' '35' '51'}, 'SecondaryLabels', {'h264' 'h265' 'vp9'}, 'GroupLines', true);
%         str = [ 'Watts (No. of iteration = ' num2str(iteration) ')' ];
%         ylabel(str)
%         if (iteration == 1) 
%             str = [ names{name} ' - Decoder - DRAM Power (in Watts)' ];
%             title(str,'Interpreter', 'none', 'FontSize', 20)
%         end
%     end
%     
%     %     Encoding CPU utilisation and Power
%     figure('units','normalized','outerposition',[0 0 1 1])
%     for iteration = 1:iterations
%         mydataRAPL = [];
%         mydataSampleCPU = [];
%         for crf = 1:length(CRFs)
%             for codec = 1:length(CODECs)
%                 tmp(codec) = results(name).dataEncIA(iteration,codec,crf);
%             end
%             maxNumEl = max(cellfun(@numel,tmp));
%             Cpad = cellfun(@(x){padarray(x(:),[maxNumEl-numel(x),0],NaN,'post')}, tmp);
%             mydataRAPL{crf} = cell2mat(Cpad);
%             
%             for codec = 1:length(CODECs)
%                 tmp2(codec) = results(name).dataCPUEnc(iteration,codec,crf);
%             end
%             maxNumEl = max(cellfun(@numel,tmp2));
%             Cpad = cellfun(@(x){padarray(x(:),[maxNumEl-numel(x),0],NaN,'post')}, tmp2);
%             mydataSampleCPU{crf} = cell2mat(Cpad);
%         end
%         
%         subplot(iterations,2,(iteration*2)-1)
%         
%         boxplotGroup(mydataRAPL, 'PrimaryLabels', {'15' '35' '51'}, 'SecondaryLabels', {'h264' 'h265' 'vp9'}, 'GroupLines', true);
%         str = [ 'Watts (No. of iteration = ' num2str(iteration) ')' ];
%         ylabel(str)
%         if (iteration == 1) 
%             str = [ names{name} ' - Encoder - IA Power (in Watts)' ];
%             title(str,'Interpreter', 'none', 'FontSize', 20)
%         end
%         
%         subplot(iterations,2,(iteration*2))
%         boxplotGroup(mydataSampleCPU, 'PrimaryLabels', {'15' '35' '51'}, 'SecondaryLabels', {'h264' 'h265' 'vp9'}, 'GroupLines', true);
%         str = [ '% (No. of iteration = ' num2str(iteration) ')' ];
%         ylabel(str)
%         if (iteration == 1) 
%             str = [ names{name} ' - Encoder - CPU Utilisation (in %)' ];
%             title(str,'Interpreter', 'none', 'FontSize', 20)
%         end
%     end
%     
%     %     Encoding DRAM power
%     figure('units','normalized','outerposition',[0 0 1 1])
%     for iteration = 1:iterations
%         mydataRAPL = [];
%         for crf = 1:length(CRFs)
%             for codec = 1:length(CODECs)
%                 tmp(codec) = results(name).dataEncDRAM(iteration,codec,crf);
%             end
%             maxNumEl = max(cellfun(@numel,tmp));
%             Cpad = cellfun(@(x){padarray(x(:),[maxNumEl-numel(x),0],NaN,'post')}, tmp);
%             mydataRAPL{crf} = cell2mat(Cpad);
%             
%         end
%         subplot(iterations,1,iteration)
%         
%         boxplotGroup(mydataRAPL, 'PrimaryLabels', {'15' '35' '51'}, 'SecondaryLabels', {'h264' 'h265' 'vp9'}, 'GroupLines', true);
%         str = [ 'Watts (No. of iteration = ' num2str(iteration) ')' ];
%         ylabel(str)
%         if (iteration == 1) 
%             str = [ names{name} ' - Encoder - DRAM Power (in Watts)' ];
%             title(str,'Interpreter', 'none', 'FontSize', 20)
%         end
%     end
% end

for name = 1:length(names)
    
    if ~CRFsCodecMapping(codec)
        eval('CRFtoRead = CRFsInit')
    else
        eval('CRFtoRead = CRFsMapped')
    end
    
    
    for i = 1:length(CRFsInit)
        txt(i) = string([num2str(CRFsInit(i)) ' \rightarrow' ]);
    end
    
    figure('units','normalized','outerposition',[0 0 1 1])
    
    subplot(3,2,1)
    for codec = 1:length(CODECs)
        for crf = 1:length(CRFsInit)
            avgPSNR(crf) = mean(metrics(name).dataPSNR{codec,crf});
        end
        plot(results(name).averageCumEncOverall(codec,:),avgPSNR, 'Marker',marker(codec),'MarkerSize',11,'LineStyle',lineStyle(codec), 'LineWidth',2)
        text(results(name).averageCumEncOverall(codec,:),avgPSNR,txt,'FontSize',14,'HorizontalAlignment','right')
        hold on
    end
    title(['Avg. Cumulative Energy - PSNR - CRFs \{' num2str(CRFsInit) '\}'])
    xlabel('Avg. Cumulative Energy (Joule)')
    ylabel('PSNR (dB)')
    set(gca,'FontSize', 18)
    grid on;
    legend(CODECs{1},CODECs{2},CODECs{3},CODECs{4},CODECs{5})

    
    
    subplot(3,2,2)
    for codec = 1:length(CODECs)
        for crf = 1:length(CRFsInit)
            avgSSIM(crf) = mean(metrics(name).dataSSIM{codec,crf});
        end
        plot(results(name).averageCumEncOverall(codec,:),avgSSIM, 'Marker',marker(codec),'MarkerSize',11,'LineStyle',lineStyle(codec), 'LineWidth',2)
        text(results(name).averageCumEncOverall(codec,:),avgSSIM,txt,'FontSize',14,'HorizontalAlignment','right')
        hold on
    end
    title(['Avg. Cumulative Energy - SSIM - CRFs \{' num2str(CRFsInit) '\}'])
    xlabel('Avg. Cumulative Energy (Joule)')
    ylabel('Norm.')
    set(gca,'FontSize', 18)
    grid on;
    legend(CODECs{1},CODECs{2},CODECs{3},CODECs{4},CODECs{5})
    
    subplot(3,2,3)
    for codec = 1:length(CODECs)
        for crf = 1:length(CRFsInit)
            avgPSNR(crf) = mean(metrics(name).dataPSNR{codec,crf});
        end
        plot(results(name).bitrate(codec,:),avgPSNR, 'Marker',marker(codec),'MarkerSize',11,'LineStyle',lineStyle(codec), 'LineWidth',2)
        text(results(name).bitrate(codec,:),avgPSNR,txt,'FontSize',14,'HorizontalAlignment','right')
        hold on
    end
    title(['Bitrate - PSNR - CRFs \{' num2str(CRFsInit) '\}'])
    xlabel('Bitrate (kbits per frame)')
    ylabel('PSNR (dB)')
    set(gca,'FontSize', 18)
    grid on;
    legend(CODECs{1},CODECs{2},CODECs{3},CODECs{4},CODECs{5})
    
    subplot(3,2,4)
    for codec = 1:length(CODECs)
        for crf = 1:length(CRFsInit)
            avgSSIM(crf) = mean(metrics(name).dataSSIM{codec,crf});
        end
        plot(results(name).bitrate(codec,:),avgSSIM, 'Marker',marker(codec),'MarkerSize',11,'LineStyle',lineStyle(codec), 'LineWidth',2)
        text(results(name).bitrate(codec,:),avgSSIM,txt,'FontSize',14,'HorizontalAlignment','right')
        hold on
    end
    title(['Bitrate - SSIM - CRFs \{' num2str(CRFsInit) '\}'])
    xlabel('Bitrate (kbits per frame)')
    ylabel('Norm.')
    set(gca,'FontSize', 18)
    grid on;
    legend(CODECs{1},CODECs{2},CODECs{3},CODECs{4},CODECs{5})
    
    subplot(3,2,5)
    for codec = 1:length(CODECs)
        plot(results(name).averageCumEncOverall(codec,:),results(name).bitrate(codec,:), 'Marker',marker(codec),'MarkerSize',11,'LineStyle',lineStyle(codec), 'LineWidth',2)
        text(results(name).averageCumEncOverall(codec,:),results(name).bitrate(codec,:),txt,'FontSize',14,'HorizontalAlignment','right')
        hold on
    end
    title(['Bitrate - SSIM - CRFs \{' num2str(CRFsInit) '\}'])
    xlabel('Avg. Cumulative Energy (Joule)')
    ylabel('Bitrate (kbits per frame)')
    set(gca,'FontSize', 18)
    grid on;
    legend(CODECs{1},CODECs{2},CODECs{3},CODECs{4},CODECs{5})
end
