function statsEnergy = importCSV_RAPL(filename, dataLines)
%IMPORTFILE Import data from a text file
%  A1CAMPFIRE3840X216030FPS10BIT420300FRAMESENCODEDCRF221 =
%  IMPORTFILE(FILENAME) reads data from text file FILENAME for the
%  default selection.  Returns the data as a table.
%
%  A1CAMPFIRE3840X216030FPS10BIT420300FRAMESENCODEDCRF221 =
%  IMPORTFILE(FILE, DATALINES) reads data for the specified row
%  interval(s) of text file FILENAME. Specify DATALINES as a positive
%  scalar integer or a N-by-2 array of positive scalar integers for
%  dis-contiguous row intervals.
%
%  Example:
%  A1Campfire3840x216030fps10bit420300framesencodedcrf221 = importfile("/Users/angelikikatsenou/Downloads/codec-comparison/csv/h264/A1Campfire_3840x2160_30fps_10bit_420_300frames_encoded_crf_22_1.csv", [1, Inf]);
%
%  See also READTABLE.
%
% Auto-generated by MATLAB on 16-Jan-2021 20:58:38

%% Input handling

% If dataLines is not specified, define defaults
if nargin < 2
    dataLines = [1, Inf];
end

%% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 22);

% Specify range and delimiter
opts.DataLines = dataLines;
opts.Delimiter = "";

% Specify column names and types
opts.VariableNames = ["SystemTime", "RDTSC", "ElapsedTimesec", "CPUUtilization", "CPUFrequency_0MHz", "CPUMinFrequency_0MHz", "CPUMaxFrequency_0MHz", "CPURequstedFrequency_0MHz", "ProcessorPower_0Watt", "CumulativeProcessorEnergy_0Joules", "CumulativeProcessorEnergy_0mWh", "IAPower_0Watt", "CumulativeIAEnergy_0Joules", "CumulativeIAEnergy_0mWh", "PackageTemperature_0C", "PackageHot_0", "CPUMinTemperature_0C", "CPUMaxTemperature_0C", "DRAMPower_0Watt", "CumulativeDRAMEnergy_0Joules", "CumulativeDRAMEnergy_0mWh", "PackagePowerLimit_0Watt"];
opts.VariableTypes = ["char", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, "SystemTime", "WhitespaceRule", "preserve");
opts = setvaropts(opts, "SystemTime", "EmptyFieldRule", "auto");
opts = setvaropts(opts, ["ElapsedTimesec", "CPUUtilization", "ProcessorPower_0Watt", "CumulativeProcessorEnergy_0Joules", "CumulativeProcessorEnergy_0mWh", "IAPower_0Watt", "CumulativeIAEnergy_0Joules", "CumulativeIAEnergy_0mWh", "DRAMPower_0Watt", "CumulativeDRAMEnergy_0Joules", "CumulativeDRAMEnergy_0mWh", "PackagePowerLimit_0Watt"], "TrimNonNumeric", true);
opts = setvaropts(opts, ["RDTSC", "ElapsedTimesec", "CPUUtilization", "CPUFrequency_0MHz", "CPUMinFrequency_0MHz", "CPUMaxFrequency_0MHz", "CPURequstedFrequency_0MHz", "ProcessorPower_0Watt", "CumulativeProcessorEnergy_0Joules", "CumulativeProcessorEnergy_0mWh", "IAPower_0Watt", "CumulativeIAEnergy_0Joules", "CumulativeIAEnergy_0mWh", "PackageTemperature_0C", "PackageHot_0", "CPUMinTemperature_0C", "CPUMaxTemperature_0C", "DRAMPower_0Watt", "CumulativeDRAMEnergy_0Joules", "CumulativeDRAMEnergy_0mWh", "PackagePowerLimit_0Watt"], "DecimalSeparator", ",");
opts = setvaropts(opts, ["ElapsedTimesec", "CPUUtilization", "ProcessorPower_0Watt", "CumulativeProcessorEnergy_0Joules", "CumulativeProcessorEnergy_0mWh", "IAPower_0Watt", "CumulativeIAEnergy_0Joules", "CumulativeIAEnergy_0mWh", "DRAMPower_0Watt", "CumulativeDRAMEnergy_0Joules", "CumulativeDRAMEnergy_0mWh", "PackagePowerLimit_0Watt"], "ThousandsSeparator", ".");

% Import the data
statsEnergy = readtable(filename, opts);

end