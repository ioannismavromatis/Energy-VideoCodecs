function [ metricsQuality ] = readQualityMetrics(inputFile)
%GETFILENAMES Parse all input video file names and
% return them to the main function.
%  Input  : inputFile  : The file name of the csv.
%
%  Output :  metricsQuality        : The structure where the metrics output are
%     stored.
%
% Copyright Angeliki Katsenou, Ioannis Mavromatis (c) 2020-2021, 
% email: 
% email: 


tmp = readmatrix(inputFile);

metricsQuality.psnrY = mean(tmp(:,2));
metricsQuality.psnrU = mean(tmp(:,3));
metricsQuality.psnrV = mean(tmp(:,4));
metricsQuality.psnrYUV = (6*metricsQuality.psnrY+metricsQuality.psnrU+metricsQuality.psnrV)/8;
metricsQuality.VMAF = mean(tmp(:,18));
metricsQuality.SSIM = mean(tmp(:,7));
metricsQuality.MSSSIM = mean(tmp(:,17));