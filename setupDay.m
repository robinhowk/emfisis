function [ dataPath, resultsFolder, figFolder, summaryFigFilename, cdfFilename, filelist, counts ] = setupDay( date, paramstring, edges )
%SETUPDAY setup directores and filename strings for day
    dataPath = sprintf('data/mat/%04d/%02d/%02d', date.Year, date.Month, date.Day);
    resultsFolder = sprintf('%s/results', dataPath);
    imagePath = sprintf('figures/%04d/%02d/%02d', date.Year, date.Month, date.Day);
    figFolder = sprintf('%s/%04d%02d%02d_a_%s', imagePath, date.Year, date.Month, date.Day, paramstring);
    summaryFigFilename = sprintf('%s/%04d%02d%02d_a_%s_summary.jpg', figFolder, date.Year, date.Month, date.Day, paramstring);
    % create directories if they do not exist
    if ~exist(resultsFolder, 'dir')
        mkdir(resultsFolder);
    end
    
    if ~exist(figFolder, 'dir')
       mkdir(figFolder); 
    end
    
    % create cdf filename
    cdfFolder = sprintf('data/cdf/%04d/%02d', date.Year, date.Month);
    
    if ~exist(cdfFolder, 'dir')
        mkdir(cdfFolder)
    end

    cdfFilename = sprintf('%s/rbsp-a_chorus-elements_%04d%02d%02d_v1.0.0', cdfFolder, date.Year, date.Month, date.Day);

    % initialize variables
    filelist = dir(fullfile(dataPath, '*.mat'));


    counts = struct('chorusAngles', zeros(1, length(edges.chorusAngles) - 1), ...
                    'sweeprates', zeros(1, length(edges.sweeprates) - 1), ...
                    'hourlyTotals', zeros(1, 24), ...
                    'psdSums', zeros(1,500), ...
                    'sweepratesList', zeros(1,500));
end

