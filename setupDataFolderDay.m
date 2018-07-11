function [ dataPath, resultsFolder ] = setupDataFolderDay ( date )
    % creates path and folders for storing data for the day
    dataPath = sprintf('../mat/%04d/%02d/%02d', date.Year, date.Month, date.Day);
    resultsFolder = sprintf('data/rbspa/mat/%04d/%02d/%02d', date.Year, date.Month, date.Day);

    if ~exist(resultsFolder, 'dir')
        mkdir(resultsFolder)
    end
end