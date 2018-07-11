function [ figFolder, summaryFigFilename ] = setupDayFigFolder( date, paramstring )
    % set up directory and file paths where images for this day are stored
    imagePath = sprintf('figures/rbspa/%04d/%02d/%02d', date.Year, date.Month, date.Day);
    figFolder = sprintf('%s/%04d%02d%02d_a_%s', imagePath, date.Year, ...
        date.Month, date.Day, paramstring);
    summaryFigFilename = sprintf('%s/%04d%02d%02d_a_%s_summary.jpg', ...
        figFolder, date.Year, date.Month, date.Day, paramstring);
    
    % create directories    
    if ~exist(figFolder, 'dir')
        mkdir(figFolder);
    end
end