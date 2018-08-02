function [ fceTimes, fceLimits ] = getFceLimits( startDate, stopDate, fceFilename )
%GETFCELIMITS Imports data for given interval from fce file
    

  fileId = fopen(fceFilename, 'r');
  % import data from file
  data = textscan(fileId, '%s %f', 'Delimiter', 'Z, ', 'CommentStyle', '#');
  % create vector of timestamps
  fceTimes = data{:,1};
  fceTimes = datetime(fceTimes, 'Format', 'yyyy-MM-dd''T''HH:mm:ss.SSS');
  fceTimes = fceTimes(~isnat(fceTimes));
  % create vector of fce limits
  fceLimits = data{:,2};
  fceLimits = fceLimits(~isnan(fceLimits));
  % trim to start and stop dates
  interval = find(fceTimes >= startDate & fceTimes < (stopDate + 1));
  fceTimes = fceTimes(interval);
  fceLimits = fceLimits(interval);
  fclose(fileId);
end
