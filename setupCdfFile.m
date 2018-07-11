function [ cdfFilename ] = setupCdfFile( date )
    % creates directory and filename for cdf file
    cdfFolder = sprintf('data/rbspa/cdf/%04d/%02d', date.Year, date.Month);
    cdfFilename = sprintf('%s/rbsp-a_chorus-elements_%04d%02d%02d_v2.0.0', ...
        cdfFolder, date.Year, date.Month, date.Day);
    
    if ~exist(cdfFolder, 'dir')
        mkdir(cdfFolder)
    end
end