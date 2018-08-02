function [ fceTimes, fceLimits ] = getFceLimits( startDate, stopDate )
%GETFCELIMITS Imports data for given interval from fce file
    
  fceFilename = getFceFilename;
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
end

function fceFilename = getFceFilename
  % define MException in case when no file is selected
  msgID = 'getFceFilename:NoFileSelcted';
  msg = 'getFceFilename\nSelection of file containing f_ce limits is required.';
  selectException = MException(msgID, msg);
  
  % get file path from user
  [file, path] = uigetfile('.dat', 'Select file containing f_ce limits');
  if isequal(file, 0)
    % if user does not select file, throw an exception to terminate program
    fclose('all');
    throw(selectException);
  else
    fceFilename = fullfile(path, file);
    opts.Interpreter = 'tex';
    opts.Default = 'Cancel';
    displayName = strrep(fceFilename, '\', '\\');
    displayName = strrep(displayName, '_', '\_');
    confirm = questdlg(sprintf('Confirm your selection.\n%s', displayName'), ...
        'Confirm selection', ...
        'Ok', 'Cancel', opts);
    if isequal(confirm, 'Cancel')
      fceFilename = getFceFilename();
    end
  end
end
