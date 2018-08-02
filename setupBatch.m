function [ paramfilename, paramstring, summaryFigFilename, ppIntervals, ...
  fceTimes, fceLimits, errorLogId, counts, cdfDataMaster, cdfInfoMaster] ...
        = setupBatch( startDate, stopDate )
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
    
    % import plasmapause intervals and fce limits
    % get plasmapause file from user
    ppFilename = getPPFilename;
    ppIntervals = getPlasmapauseIntervals(startDate, stopDate, ppFilename);
    [fceTimes, fceLimits] = getFceLimits(startDate, stopDate);
    
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
    cdfMasterFile = getCdfMasterFile;
    [cdfDataMaster, cdfInfoMaster] = spdfcdfread(cdfMasterFile);
end

function ppFilename = getPPFilename
  % define MException in case when no file is selected
  msgID = 'getPPFilename:NoFileSelcted';
  msg = 'Selection of file containing plasmapause intervals is required.';
  selectException = MException(msgID, msg);
  
  % get file path from user
  [file, path] = uigetfile('*.txt', 'Select file containing plasmapause intervals');
  if isequal(file, 0)
    % if user does not select file, throw an exception to terminate program
    fclose('all');
    throw(selectException);
  else
    ppFilename = fullfile(path, file);
    opts.Interpreter = 'tex';
    opts.Default = 'Cancel';
    displayName = strrep(ppFilename, '\', '\\');
    displayName = strrep(displayName, '_', '\_');
    confirm = questdlg({'Confirm your selection.'; displayName}, ...
        'Confirm selection', ...
        'Ok', 'Cancel', opts);
    if isequal(confirm, 'Cancel')
      ppFilename = getPPFilename;
    end
  end
end

function cdfMasterFile = getCdfMasterFile
  % define MException in case when no file is selected
  msgID = 'getCdfMasterFile:NoFileSelcted';
  msg = 'getCdfMasterFile\nSelection of cdf template is required.';
  selectException = MException(msgID, msg);
  
  % get file path from user
  [file, path] = uigetfile('.cdf', 'Select cdf master file');
  if isequal(file, 0)
    % if user does not select file, throw an exception to terminate program
    fclose('all');
    throw(selectException);
  else
    cdfMasterFile = fullfile(path, file);
    opts.Interpreter = 'tex';
    opts.Default = 'Cancel';
    displayName = strrep(cdfMasterFile, '\', '\\');
    displayName = strrep(displayName, '_', '\_');
    confirm = questdlg(sprintf('Confirm your selection.\n%s', displayName'), ...
        'Confirm selection', ...
        'Ok', 'Cancel', opts);
    if isequal(confirm, 'Cancel')
      cdfMasterFile = getCdfMasterFile;
    end
  end
end