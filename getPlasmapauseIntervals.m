function [ intervals ] = getPlasmapauseIntervals( startDate, stopDate, ppFilename )
%GETPLASMAPAUSEINTERVALS gets the outside plasmapause intervals from the 
%given file between the specified start and stop dates

    % open file containing plasmapause intervals
    fileId = fopen(ppFilename, 'r');
    % import data from file
    intervals = textscan(fileId, '%s %s %d', 'CommentStyle', '#');
    intervals(:,3) = [];
    intervals = [intervals{:}];
    % convert to datetime
    intervals = datetime(intervals, 'Format', 'yyyy-MM-dd''T''HH:mm:ss.S');
    
    % trim to specified interval
    [row, ~] = find(intervals >= startDate & intervals < (stopDate + 1));
    intervals = intervals(unique(row), :);    
    
    %close file
    fclose(fileId);
end

