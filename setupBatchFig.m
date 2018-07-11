function [ batchSummaryFilename ] = setupBatchFig( startDate, stopDate, paramstring )
    % sets up folders and file names where figures are to be saved
    batchFigFolder = sprintf('figures/%04d/%02d', startDate.Year, startDate.Month);
    if exist(batchFigFolder, 'dir') == 0
        mkdir(batchFigFolder)
    end
    
    batchSummaryFilename = sprintf('figures/%04d/%02d/%04d%02d%02d_to_%04d%02d%02d_a_%s_summary.jpg', ...
        startDate.Year, startDate.Month, startDate.Year, startDate.Month, ...
        startDate.Day, stopDate.Year, stopDate.Month, stopDate.Day, paramstring);
end