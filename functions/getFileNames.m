function [ name, fps, bit, chroma, baseName, resolution, NoFrames ] = getFileNames(inputFolder)
%GETFILENAMES Parse all input video file names and
% return them to the main function.
%  Input  :
%
%     inputFolder  : The path to the folder that contains all the input
%                    videos.
%
%  Output :
%     name        : The video file names returned to the main program.
%     baseName    : The base name to be used later for the post-processing.
%     resolution  : The initial resolution of the video file.
%
% Copyright (c) 2020-2021, 
% email: 
% email: 

    fileStruct = dir(inputFolder);
    
    for i = 1:length(fileStruct)
        tmp = split(fileStruct(i).name,'.');
        name(i) = tmp(1); 
        
        str = split(tmp(1),'_');
        
        B = regexp(str(3),'\d*','Match');
        fps(i) = getNum(B);
        
        B = regexp(str(4),'\d*','Match');
        bit(i) = getNum(B);
        
        chroma(i) = str2double(str(5));
        
        baseName(i) = string(str(1));
        resolution(i) = string(str(2));
        
        B = regexp(str(6),'\d*','Match');
        NoFrames(i) = getNum(B);
    end
end

function number = getNum(inputString)
    for ii= 1:length(inputString)
      if ~isempty(inputString{ii})
          number(ii,1)=str2double(inputString{ii}(end));
      else
          number(ii,1)=NaN;
      end
    end
end

