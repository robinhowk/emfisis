function [ summaryFigFilename ] = setupBatch( startDate, stopDate )
%SETUP gets parameter information, imports data and creates error log for
%current batch of files to be run

    
    % create filename for summary image for batch, save in current months
    % folder
    summaryFigFolder = sprintf('figures/%04d/%02d', startDate.Year, startDate.Month);
    if exist(summaryFigFolder, 'dir') == 0
        mkdir(summaryFigFolder)
    end
    
    summaryFigFilename = sprintf('figures/%04d/%02d/%04d%02d%02d_to_%04d%02d%02d_a_%s_summary.jpg', ...
        startDate.Year, startDate.Month, startDate.Year, startDate.Month, startDate.Day, ...
        stopDate.Year, stopDate.Month, stopDate.Day, paramstring);
end

