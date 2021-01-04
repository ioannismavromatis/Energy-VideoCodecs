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


inputFolder = "./input/*.mp4";

CODECs =[ "h264" "h265" "vp9" ];
CRFs = [ 15 35 51 ];
iterations = 4;
idle_iterations = 10;

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


[ names, fps, bit, chroma, baseName, resolution ] = getFileNames(inputFolder);

for name = 1:length(names)
    for crf = 1:length(CRFs)
        for codec = 1:length(CODECs)
            for iteration = 1:iterations
                % Encoded Power profile
                path = [ './csv/' CODECs(codec) '/' names(name) '_encoded_crf_' CRFs(crf) '_' iteration '.csv' ];
                path = strjoin(path,'');
                encoded = importCSV(path);
                encodedArray = table2array(encoded);
                
                avgWattsEncIA(iteration,codec,crf) = str2double(encodedArray(end,13))/str2double(encodedArray(end,3));
                cumWattsEncIA(iteration,codec,crf) = str2double(encodedArray(end,13));
                dataEncIA{iteration,codec,crf} = str2double(encodedArray(:,12));
                avgWattsEncDRAM(iteration,codec,crf) = str2double(encodedArray(end,20))/str2double(encodedArray(end,3));
                cumWattsEncDRAM(iteration,codec,crf) = str2double(encodedArray(end,20));
                dataEncDRAM{iteration,codec,crf} = str2double(encodedArray(:,19));
                
                % Decoded Power profile
                path = [ './csv/' CODECs(codec) '/' names(name) '_decoded_crf_' CRFs(crf) '_' iteration '.csv' ];
                path = strjoin(path,'');
                decoded = importCSV(path);
                decodedArray = table2array(decoded);
                
                avgWattsDecIA(iteration,codec,crf) = str2double(decodedArray(end,13))/str2double(decodedArray(end,3));
                cumWattsDecIA(iteration,codec,crf) = str2double(decodedArray(end,13));
                dataDecIA{iteration,codec,crf} = str2double(decodedArray(:,12));
                avgWattsDecDRAM(iteration,codec,crf) = str2double(decodedArray(end,20))/str2double(decodedArray(end,3));
                cumWattsDecDRAM(iteration,codec,crf) = str2double(decodedArray(end,20));
                dataDecDRAM{iteration,codec,crf} = str2double(decodedArray(:,19));
                
                % CPU utilisation - encoder
                path = [ './samplecpu/' CODECs(codec) '/' names(name) '_encoded_crf_' CRFs(crf) '_' iteration '.log' ];
                path = strjoin(path,'');
                dataCPUEnc{iteration,codec,crf} = importCPUUtilisation(path);
                      
                % CPU utilisation - decoder
                path = [ './samplecpu/' CODECs(codec) '/' names(name) '_decoded_crf_' CRFs(crf) '_' iteration '.log' ];
                path = strjoin(path,'');
                dataCPUDec{iteration,codec,crf} = importCPUUtilisation(path);
                
            end
        end
    end
    
    results(name).name = names(name);
    results(name).fps = fps(name);
    results(name).resolution = resolution(name);
    results(name).bit = bit(name);
    results(name).chroma = chroma(name);
    
    results(name).avgWattsEncIA = avgWattsEncIA;
    results(name).cumWattsEncIA = cumWattsEncIA;
    results(name).dataEncIA = dataEncIA;
    results(name).avgWattsEncDRAM = avgWattsEncDRAM;
    results(name).cumWattsEncDRAM = cumWattsEncDRAM;
    results(name).dataEncDRAM = dataEncDRAM;
    
    results(name).avgWattsDecIA = avgWattsDecIA;
    results(name).cumWattsDecIA = cumWattsDecIA;
    results(name).dataDecIA = dataDecIA;
    results(name).avgWattsDecDRAM = avgWattsDecDRAM;
    results(name).cumWattsDecDRAM = cumWattsDecDRAM;
    results(name).dataDecDRAM = dataDecDRAM;
    
    results(name).dataCPUEnc = dataCPUEnc;
    results(name).dataCPUDec = dataCPUDec;
end


for name = 1:length(names)
    mydataRAPL = [];
    mydataSampleCPU = [];
    figure('units','normalized','outerposition',[0 0 1 1])
    for iteration = 1:iterations
        for codec = 1:length(CODECs)
            for crf = 1:length(CRFs)
                tmp(crf) = results(name).dataDecIA(iteration,codec,crf);
            end
            maxNumEl = max(cellfun(@numel,tmp));
            Cpad = cellfun(@(x){padarray(x(:),[maxNumEl-numel(x),0],NaN,'post')}, tmp);
            mydataRAPL{codec} = cell2mat(Cpad);
            
            for crf = 1:length(CRFs)
                tmp2(crf) = results(name).dataCPUDec(iteration,codec,crf);
            end
            maxNumEl = max(cellfun(@numel,tmp2));
            Cpad = cellfun(@(x){padarray(x(:),[maxNumEl-numel(x),0],NaN,'post')}, tmp2);
            mydataSampleCPU{codec} = cell2mat(Cpad);
        end
        
        subplot(iterations,2,(iteration*2)-1)
        
        boxplotGroup(mydataRAPL, 'PrimaryLabels', {'15' '35' '51'}, 'SecondaryLabels', {'h264' 'h265' 'vp9'}, 'GroupLines', true);
        str = [ 'Watts (No. of iteration = ' num2str(iteration) ')' ];
        ylabel(str)
        if (iteration == 1) 
            str = [ names{name} ' - Decoder - IA Power (in Watts)' ];
            title(str,'Interpreter', 'none', 'FontSize', 20)
        end
        
        subplot(iterations,2,(iteration*2))
        
        boxplotGroup(mydataSampleCPU, 'PrimaryLabels', {'15' '35' '51'}, 'SecondaryLabels', {'h264' 'h265' 'vp9'}, 'GroupLines', true);
        str = [ '% (No. of iteration = ' num2str(iteration) ')' ];
        ylabel(str)
        if (iteration == 1) 
            str = [ names{name} ' - Decoder - CPU Utilisation (in %)' ];
            title(str,'Interpreter', 'none', 'FontSize', 20)
        end
    end
    
    mydataRAPL = [];
    figure('units','normalized','outerposition',[0 0 1 1])
    for iteration = 1:iterations
        for codec = 1:length(CODECs)
            for crf = 1:length(CRFs)
                tmp(crf) = results(name).dataDecDRAM(iteration,codec,crf);
            end
            maxNumEl = max(cellfun(@numel,tmp));
            Cpad = cellfun(@(x){padarray(x(:),[maxNumEl-numel(x),0],NaN,'post')}, tmp);
            mydataRAPL{codec} = cell2mat(Cpad);
            
        end
        subplot(iterations,1,iteration)
        
        boxplotGroup(mydataRAPL, 'PrimaryLabels', {'15' '35' '51'}, 'SecondaryLabels', {'h264' 'h265' 'vp9'}, 'GroupLines', true);
        str = [ 'Watts (No. of iteration = ' num2str(iteration) ')' ];
        ylabel(str)
        if (iteration == 1) 
            str = [ names{name} ' - Decoder - DRAM Power (in Watts)' ];
            title(str,'Interpreter', 'none', 'FontSize', 20)
        end
    end
    
    mydataRAPL = [];
    mydataSampleCPU = [];
    figure('units','normalized','outerposition',[0 0 1 1])
    for iteration = 1:iterations
        for codec = 1:length(CODECs)
            for crf = 1:length(CRFs)
                tmp(crf) = results(name).dataEncIA(iteration,codec,crf);
            end
            maxNumEl = max(cellfun(@numel,tmp));
            Cpad = cellfun(@(x){padarray(x(:),[maxNumEl-numel(x),0],NaN,'post')}, tmp);
            mydataRAPL{codec} = cell2mat(Cpad);
            
            for crf = 1:length(CRFs)
                tmp2(crf) = results(name).dataCPUEnc(iteration,codec,crf);
            end
            maxNumEl = max(cellfun(@numel,tmp2));
            Cpad = cellfun(@(x){padarray(x(:),[maxNumEl-numel(x),0],NaN,'post')}, tmp2);
            mydataSampleCPU{codec} = cell2mat(Cpad);
        end
        
        subplot(iterations,2,(iteration*2)-1)
        
        boxplotGroup(mydataRAPL, 'PrimaryLabels', {'15' '35' '51'}, 'SecondaryLabels', {'h264' 'h265' 'vp9'}, 'GroupLines', true);
        str = [ 'Watts (No. of iteration = ' num2str(iteration) ')' ];
        ylabel(str)
        if (iteration == 1) 
            str = [ names{name} ' - Encoder - IA Power (in Watts)' ];
            title(str,'Interpreter', 'none', 'FontSize', 20)
        end
        
        subplot(iterations,2,(iteration*2))
        boxplotGroup(mydataSampleCPU, 'PrimaryLabels', {'15' '35' '51'}, 'SecondaryLabels', {'h264' 'h265' 'vp9'}, 'GroupLines', true);
        str = [ '% (No. of iteration = ' num2str(iteration) ')' ];
        ylabel(str)
        if (iteration == 1) 
            str = [ names{name} ' - Encoder - CPU Utilisation (in %)' ];
            title(str,'Interpreter', 'none', 'FontSize', 20)
        end
    end
    
    mydataRAPL = [];
    figure('units','normalized','outerposition',[0 0 1 1])
    for iteration = 1:iterations
        for codec = 1:length(CODECs)
            for crf = 1:length(CRFs)
                tmp(crf) = results(name).dataEncDRAM(iteration,codec,crf);
            end
            maxNumEl = max(cellfun(@numel,tmp));
            Cpad = cellfun(@(x){padarray(x(:),[maxNumEl-numel(x),0],NaN,'post')}, tmp);
            mydataRAPL{codec} = cell2mat(Cpad);
            
        end
        subplot(iterations,1,iteration)
        
        boxplotGroup(mydataRAPL, 'PrimaryLabels', {'15' '35' '51'}, 'SecondaryLabels', {'h264' 'h265' 'vp9'}, 'GroupLines', true);
        str = [ 'Watts (No. of iteration = ' num2str(iteration) ')' ];
        ylabel(str)
        if (iteration == 1) 
            str = [ names{name} ' - Encoder - DRAM Power (in Watts)' ];
            title(str,'Interpreter', 'none', 'FontSize', 20)
        end
    end
end

