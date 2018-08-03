function [ fceTimes, fceLower, fceUpper ] = getFceLimits( startDate, stopDate, fceFilename )
%GETFCELIMITS Imports data for given interval from fce file
    % startDate and stopDate are provided in datetime format
    % fceFilename is a string path to the file containing fce information
    
    fileId = fopen(fceFilename, 'r');
    % import data from file
    data = textscan(fileId, '%s %s %s', 'CommentStyle', '#');
    % create vector of timestamps
    fceTimes = cell2mat(data{:,1});
    fceTimes = datetime(fceTimes, 'Format', 'yyyy-MM-dd''T''HH:mm:ss');
%     fceTimes = fceTimes(~isnat(fceTimes));

    % create vectors of upper and lower fce limits
    fceLower = data{:,2};
    fceUpper = data{:,3};
    fillLocs = find(strcmp(data{:,2}, 'fill'))';
    % change fill values to -1
    for i = fillLocs
       fceLower{i} = '-1';
       fceUpper{i} = '-1';
    end
    fceLower = str2double(fceLower);
    fceUpper = str2double(fceUpper);
    
    % trim to start and stop dates, include data on either side for
    % interpolation
    interval = find(fceTimes >= startDate & fceTimes < (stopDate + 1));
    interval = max(interval(1) - 1, 1):min(interval(end) + 2, numel(fceLower));
    fceTimes = fceTimes(interval);
    fceLower = (.08 * 1000) .* fceLower(interval);
    fceUpper = (0.5 * 1000) .* fceUpper(interval);
    fclose(fileId);
end

