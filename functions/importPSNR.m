function psnrImportValues = importPSNR(filename, dataLines)
%IMPORTFILE Import data from a text file
%  psnrImportValues = IMPORTFILE(FILENAME) reads
%  data from text file FILENAME for the default selection.  Returns the
%  data as a table.
%
%  psnrImportValues = IMPORTFILE(FILE, DATALINES)
%  reads data for the specified row interval(s) of text file FILENAME.
%  Specify DATALINES as a positive scalar integer or a N-by-2 array of
%  positive scalar integers for dis-contiguous row intervals.
%
%  Example:
%  psnrImportValues = importfile("/Users/ioannis/Documents/git/codec-comparison/psnr/h264/S11AirAcrobatic_1920x1080_60fps_10bit_420.txt", [1, Inf]);
%
%  See also READTABLE.
%
% Auto-generated by MATLAB on 03-Jan-2021 13:12:57

%% Input handling

% If dataLines is not specified, define defaults
if nargin < 2
    dataLines = [1, Inf];
end

%% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 9);

% Specify range and delimiter
opts.DataLines = dataLines;
opts.Delimiter = " ";

% Specify column names and types
opts.VariableNames = ["Frame", "MSEAvg", "MSEy", "MSEu", "MSEv", "PSNRAvg", "PSNRy", "PSNRu", "PSNRv"];
opts.VariableTypes = ["double", "double", "double", "double", "double", "double", "double", "double", "double"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";
opts.LeadingDelimitersRule = "ignore";

% Specify variable properties
opts = setvaropts(opts, ["Frame", "MSEAvg", "MSEy", "MSEu", "MSEv", "PSNRAvg", "PSNRy", "PSNRu", "PSNRv"], "TrimNonNumeric", true);
opts = setvaropts(opts, ["Frame", "MSEAvg", "MSEy", "MSEu", "MSEv", "PSNRAvg", "PSNRy", "PSNRu", "PSNRv"], "ThousandsSeparator", ",");

% Import the data
psnrImportValues = readtable(filename, opts);

end