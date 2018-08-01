function [ paramfilename, paramstring, summaryFigFilename, ppIntervals, fceTimes, fceLimits, errorLogId, counts, cdfDataMaster, cdfInfoMaster] ...
        = setupBatch( startDate, stopDate, ppFilename, fceFilename, cdfMasterFile )
%SETUP gets parameter information, imports data and creates error log for
%current batch of files to be run

    % set up parameters
    paramfilename = setparam;
    paramstring = paramfilename(1:end-4);
    
    % create filename for summary image for batch, save in current months
    % folder
    summaryFigFolder = sprintf('figures/%04d/%02d', startDate.Year, startDate.Month);
    if exist(summaryFigFolder, 'dir') == 0
        mkdir(summaryFigFolder)
    end
    
    summaryFigFilename = sprintf('figures/%04d/%02d/%04d%02d%02d_to_%04d%02d%02d_a_%s_summary.jpg', ...
        startDate.Year, startDate.Month, startDate.Year, startDate.Month, startDate.Day, ...
        stopDate.Year, stopDate.Month, stopDate.Day, paramstring);
    
    % import d plasmapause intervals and fce limits
    ppIntervals = getPlasmapauseIntervals(startDate, stopDate, ppFilename);
    [fceTimes, fceLimits] = getFceLimits(startDate, stopDate, fceFilename);
    % create error log
    errorLog = sprintf('logs/error_log_%s_to_%s_a.txt', datestr(startDate, 'yyyymmdd'), datestr(stopDate, 'yyyymmdd'));
    errorLogId = fopen(errorLog, 'w');
    
    % initialize variables
    % chorusAnglesBatch - hist counts for chorus angles
    % sweepratesBatch - hist counts for sweeprates
    load(paramfilename, 'histEdges');
    chorusAngles = zeros(1, length(histEdges.chorusAngles) - 1);
    sweeprates = zeros(1, length(histEdges.sweeprates) - 1);
    hourTotals = zeros(1, 24);
    psdSums = [];
    sweepratesList = [];
    
    counts = struct('chorusAngles', chorusAngles, 'sweeprates', sweeprates, 'hourlyTotals', hourTotals, 'psdSums', psdSums, 'sweepratesList', sweepratesList);
    
    % get info about master cdf file
    [cdfDataMaster, cdfInfoMaster] = spdfcdfread(cdfMasterFile);
end