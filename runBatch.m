function [totalRecordsBatch, countsBatch] = runBatch
t1 = tic;
%RUNBATCH process all files in data/mat for given dates
%   input format for startDate and stopDate:
%   yyyyMMdd
%   example: January 31, 2015 -> 20150131

%--------------------------------------------------------------------------
% Get date range from user
%--------------------------------------------------------------------------
  % get start date from user
  userStartDate = input('\nEnter start date in the following format yyyyMMdd: ', 's');
  userEndDate = input('\nEnter end date in the following format yyyyMMdd: ', 's');

  % convert dates input by user to datetime format
  startDate = datetime(userStartDate, 'Format', 'yyyyMMdd');
  stopDate = datetime(userEndDate, 'Format', 'yyyyMMdd');
  
  % get snr threshold from user
  snrThreshold = input('\nEnter SNR threshold to be used: ');
  
  % confirm selections
  userConfirm =  input('\n Confirm entered values (y/n): ');
  if isequal(userConfirm, 'n')
    totalRecordsBatch = 0;
    countsBatch = 0;
    return
  end
    
  version = 'v1.1';
%--------------------------------------------------------------------------
% Set up data for processing this batch of files. 
% Load data from source files
% set up error log
% initalize struct for tallying results
%--------------------------------------------------------------------------
  % load param file and extract its title for naming files
  % set up parameters
  paramfilename = setparam;
  paramstring = paramfilename(1:end-4);

  % load source files
  [ppIntervals, fceTimes, fceLower, fceUpper, cdfDataMaster, cdfInfoMaster] = ...
    loadSourceFiles(startDate, stopDate);

  % create error log
  errorLog = sprintf('logs/error_log_%s_to_%s_a.txt', datestr(startDate, 'yyyymmdd'), datestr(stopDate, 'yyyymmdd'));
  errorLogId = fopen(errorLog, 'w');

  % initialize batch counts
  countsBatch = initializeBatchCounts(histEdges, 0);
  totalRecordsBatch = 0;
  
  % get destination file for summary panel
  batchSummaryFigFile = getBurstSummaryDestination(startDate, stopDate, paramstring, version);
%--------------------------------------------------------------------------
% process each burst
%--------------------------------------------------------------------------
  for iDate = startDate:stopDate
    % start timer
    t2 = tic;
    
    %----------------------------------------------------------------------
    % Initialize daily variables
    % set datapath for mat files for this day
    % create folders for storing results
    % get list of all mat files for this day
    % initialize counts for tracking daily totals
    % create structure for storing data to be written to cdfs
    %----------------------------------------------------------------------
    % set data path for current day
    dataPath = sprintf('mat/%04d/%02d/%02d', date.Year, date.Month, date.Day);
    
    % create folders where results and figures will be saved
    [resultsFolder, figFolder] = createFolders(datapath, date, paramstring);
    
    % get list of files
    filelist = dir(fullfile(dataPath, '*.mat'));
    
    % initilize struct for tracking daily totalts
    countsDay = initializeCounts(histEdges, defaultNum);
    numRecords = 0;
    totalRecordsDay = 0;
    
    % setup cdf results
    cdfData = setupCdfRecords(cdfInfoMaster);
    
    %----------------------------------------------------------------------
    % process each file for day
    %----------------------------------------------------------------------
    for iFile = 1:size(filelist,1)
      % get file path for burst
      filename = filelist(iFile).name;
      datafilename = sprintf('%s/%s', dataPath, filename);
      data = load(datafilename);
      fspec = data.fspec;
      tspec = data.tspec;
      imagefile = data.imagefile;
      %------------------------------------------------------------------
      % check if current burst falls within a valid plasmapause interval. 
      % If so, trim spectrogram, scale to 10log10 and continue processing 
      % burst.
      %------------------------------------------------------------------
      if find(timestamp <= ppIntervals(:,2) & ...
        (timestamp + seconds(6)) > ppIntervals(:,1))
        % create filename for result and figure to be saved
        figname = sprintf('%s/%s_%s_%s.jpg', figFolder, strtok(filename, '.'), paramstring, version);
        resultFilename = sprintf('%s/%s_%s.mat', resultsFolder, strtok(filename, '.'), version);
        % create spectrogram
        [spect, fspec, isValid] = trimSpectrogram(timestamp, imagefile, fspec, fceTimes, fceLower, fceUpper);
        
        % create snr map of burst and select features about a given
        % threshold
        [ snrMap, features ] = mapSnr( spect, imagefile, snrThreshold );

        % if ridges are found, continue
        if ~isnan(sum(features(:))) && isValid
          [spine, bwSpine] = center_of_mass(features, 2, 2);
          [ chorusElements, tracedElements, chorusCount ] = ...
            traceBurst( bwSpine, spine, imagefile, fspec, tspec, mu1, ...
            features, errorLogId, filename);

          % create figure
          showBurstFigure(tspec, fspec, spect, snrMap, features, ...
            snrThreshold, spine, tracedElements, chorusElements, ...
            chorusCount, histEdges.sweeprates, figname);

          % if chorus are found, continue
          if chorusCount > 0
            if numRecords + chorusCount > numel(cdfData.chorusEpoch)
                numEntries = 1000;
                % reallocate array sizes, add room for 1000
                % more entries
                cdfData.chorusEpoch = [cdfData.chorusEpoch; int64(zeros(numEntries, cdfInfoMaster.Variables{1,2}(1)))];
                cdfData.frequency =  [cdfData.frequency; cdfInfoMaster.VariableAttributes.FILLVAL{4,2} * ones(numEntries, cdfInfoMaster.Variables{4,2}(1))];
                cdfData.psd =  [cdfData.psd; cdfInfoMaster.VariableAttributes.FILLVAL{5,2} * ones(numEntries, cdfInfoMaster.Variables{5,2}(1))];
                cdfData.sweeprates = [cdfData.sweeprates; cdfInfoMaster.VariableAttributes.FILLVAL{6,2} * ones(numEntries, cdfInfoMaster.Variables{6,2}(1))];
                cdfData.burst = [cdfData.burst; int32(zeros(numEntries, cdfInfoMaster.Variables{7,2}(1)))];
                cdfData.chorusIndex = [cdfData.chorusIndex; int32(zeros(numEntries, cdfInfoMaster.Variables{8,2}(1)))];
            end

            % getHistCounts
            burstCounts = getHistCounts(chorusElements, histEdges);
            countsDay.chorusAngles = countsDay.chorusAngles + burstCounts.chorusAngles;
            countsDay.sweeprates = countsDay.sweeprates + burstCounts.sweeprates;
            countsDay.hourlyTotals(timestamp.Hour + 1) = countsDay.hourlyTotals(timestamp.Hour + 1) + chorusCount;

            % add psd sums and sweeprates to array
            for i = 1:chorusCount
                countsDay.psdSums(totalRecordsDay + i) = chorusElements(i).psdSumLine;
                countsDay.sweepratesList(totalRecordsDay + i) = chorusElements(i).sweeprate;
            end

            [cdfData, numRecords] = updateCdfRecords(cdfData, chorusElements, timestamp, tspec, str2double(filename(13:15)), numRecords);

            % add to record count
            totalRecordsDay = totalRecordsDay + chorusCount;

            % save mat file
            save(resultFilename, 'imagefile', 'imagefile1', 'fspec', ...
              'tspec', 'features', 'bwRidges', 'chorusElements', ...
              'paramfilename', 'timestamp', 'tracedElements', 'spine', ...
              'bwSpine');
          else
            % save mat file
            save(resultFilename, 'imagefile', 'imagefile1', 'fspec', ...
              'tspec', 'features', 'bwRidges', 'paramfilename', 'timestamp');
          end
        else
          % no ridges, save mat file
          save(resultFilename, 'imagefile', 'imagefile1', 'fspec', ...
            'tspec', 'paramfilename', 'timestamp');
        end
      end % end of burst
    end % end day

     % save summary data for day
    resultsDayFilename = sprintf('%s/%04d%02d%02d_summary_%s.mat', ...
      resultsFolder, iDate.Year, iDate.Month, iDate.Day, version);
    save(resultsDayFilename, 'countsDay', 'totalRecordsDay');

    % save cdf file for day
    if totalRecordsDay > 0
      writeToCdf( cdfFolder, version, date, cdfDataMaster, cdfInfoMaster, ...
        cdfData, numRecords, tspec(1) );
    end

    % create summary histograms for day
    daySummaryFigFile = sprintf('%s/%04d%02d%02d_a_%s_summary_%s.jpg', ...
      figFolder, date.Year, date.Month, date.Day, paramstring, version);
    showSummaryPanel(countsDay, histEdges, daySummaryFigFile);

    % update batch totals
    countsBatch.chorusAngles = countsBatch.chorusAngles + countsDay.chorusAngles;
    countsBatch.sweeprates = countsBatch.sweeprates + countsDay.sweeprates;
    countsBatch.hourlyTotals = countsBatch.hourlyTotals + countsDay.hourlyTotals;
    countsBatch.psdSums = [countsBatch.psdSums, countsDay.psdSums(1:totalRecordsDay)];
    countsBatch.sweepratesList = [countsBatch.sweepratesList, countsDay.sweepratesList(1:totalRecordsDay)];

    % update total records for batch
    totalRecordsBatch = totalRecordsBatch + totalRecordsDay;
    iDate
    totalRecordsDay
    % stop timer
    toc(t2)
  end % end of batch
    
  % close all files
  fclose('all');

  % create summary histograms for batch
  showSummaryPanel(countsBatch, histEdges, batchSummaryFigFile);
    
  totalRecordsBatch   
  toc(t1)
end

function [ppIntervals, fceTimes, fceLower, fceUpper, cdfDataMaster, cdfInfoMaster] = loadSourceFiles(startDate, stopDate)
  % get location of files from user
  ppFilename = getFilename('*.txt', 'plamapause intervals');
  fceFilename = getFilename('*.dat', 'f_ce limits');
  cdfFilename = getFilename('*.cdf', 'cdf master template');
  
  % load data from files
  ppIntervals = getPlasmapauseIntervals(startDate, stopDate, ppFilename);
  [fceTimes, fceLower, fceUpper] = getFceLimits(startDate, stopDate, fceFilename);
  [cdfDataMaster, cdfInfoMaster] = spdfcdfread(cdfFilename);
end

function filename = getFilename(fileType, fileContents)
  % define MException in case when no file is selected
  msgID = 'getPPFilename:NoFileSelcted';
  msg = ['Selection of file containing ' fileContents ' is required.'];
  selectException = MException(msgID, msg);
  
  % get file path from user
  [file, path] = uigetfile(fileType, ['Select file containing ' fileContents]);
  if isequal(file, 0)
    % if user does not select file, throw an exception to terminate program
    fclose('all');
    throw(selectException);
  else
    filename = fullfile(path, file);
    opts.Interpreter = 'tex';
    opts.Default = 'Cancel';
    displayName = strrep(filename, '\', '\\');
    displayName = strrep(displayName, '_', '\_');
    confirm = questdlg({'Confirm your selection.'; displayName}, ...
        'Confirm selection', ...
        'Ok', 'Cancel', opts);
    if isequal(confirm, 'Cancel')
      filename = getFilename;
    end
  end
end

function counts = initializeCounts(histEdges, defaultNum)
  % chorusAnglesBatch - hist counts for chorus angles
  % sweepratesBatch - hist counts for sweeprates
  chorusAngles = zeros(1, length(histEdges.chorusAngles) - 1);
  sweeprates = zeros(1, length(histEdges.sweeprates) - 1);
  hourTotals = zeros(1, 24);
  if defualtNum == 0
    psdSums = [];
    sweepratesList = [];
  else
    psdSums = zeros(1, defaultNum);
    sweepratesList = zeros(1, defaultNum);
  end

  counts = struct('chorusAngles', chorusAngles, ...
                       'sweeprates', sweeprates, ...
                       'hourlyTotals', hourTotals, ...
                       'psdSums', psdSums, ...
                       'sweepratesList', sweepratesList);
end

function [resultsFolder, figFolder, cdfFolder] = createFolders(datapath, date, paramstring)
    
  resultsFolder = sprintf('v1.1/results/data/%s/results', datapath);
  imagePath = sprintf('v1.1/figures/%04d/%02d/%02d', date.Year, date.Month, date.Day);
  figFolder = sprintf('%s/%04d%02d%02d_a_%s', imagePath, date.Year, date.Month, date.Day, paramstring);
  cdfFolder = sprintf('v1.1/data/cdf/%04d/%02d', date.Year, date.Month);
  
  % create directories if they do not exist
  if ~exist(resultsFolder, 'dir')
    mkdir(resultsFolder);
  end
  
  if ~exist(figFolder, 'dir')
    mkdir(figFolder); 
  end
  
  if ~exist(cdfFolder, 'dir')
    mkdir(cdfFolder)
  end
end

function [spect, fspec, isValid] = trimSpectrogram(timestamp, imagefile, fspec, fceTimes, fceLower, fceUpper)
  % check a fceTime falls inside the burst
  fceInd = find(timestamp >= fceTimes & timestamp + seconds(6) <= fceTimes);
  if numel(fceInd) == 1
    fLow = fceLower(fceInd);
    fHigh = fceUpper(fceInd);
  else
    tmid = timestamp + seconds(tspec(end))/2;
    next = find(fceTimes > tmid, 1, 'first');
    prev = next - 1;
    fLow = interpFce(fceTimes(prev), fceTimes(next), tmid, fceLower(prev), fceLower(next));
    fHigh = interpFce(fceTimes(prev), fceTimes(next), tmid, fceUpper(prev), fceUpper(next));
  end

  % if there was no valid fce limits set fspec to an empty vector
  spect = 10*log10(imagefile);
  if ~isnan(fLow)
    low = find(fspec > fLow, 1, 'first');
    low = low - 1;
    high = find(fspec > fHigh, 1, 'first');
    low = min(max(1, low), numel(fspec));
    high = max(min(numel(fspec), high), 1);
    if low ~= high
        fspec = fspec(low:high);
        spect = spect(low:high, :);
    end
    isValid = true;
  else
    isValid = false;
  end
end

function destinationFile = getBurstSummaryDestination(startDate, stopDate, paramstring, version)
  % create filename for summary image for batch, save in current months folder
  destinationFolder = sprintf('%s/figures/%04d/%02d_%s', version, startDate.Year, startDate.Month, version);
  
  if exist(destinationFolder, 'dir') == 0
    mkdir(destinationFolder)
  end
    
  destinationFile = sprintf('%s/%04d%02d%02d_to_%04d%02d%02d_a_%s_summary.jpg', ...
    destinationFolder, startDate.Year, startDate.Month, startDate.Day, ...
    stopDate.Year, stopDate.Month, stopDate.Day, paramstring);
end

function showSummaryPanel( counts, edges, destinationFile )
  summary = figure('visibility', 'off');
  % plot hourly totals
  h1 = subplot(3, 1, 1);
  bar(0:1:23, counts.hourlyTotals, 'histc');
  axis(h1, 'tight');
  title(h1, 'Total Chorus, By Hour');
  xlabel('Hour');
  ylabel('Total Chorus');

  % distribution of sweeprates
  h2 = subplot(3,1,2);
  bins = (edges.sweeprates(1:end-1) + edges.sweeprates(2:end)) / 2;
  bar(bins, counts.sweeprates / sum(counts.sweeprates), 'histc');
  axis(h2, 'tight');
  title(h2, 'Distribution of Sweeprates');
  xlabel('Sweeprate (KHz / sec)');
  ylabel('Estimated\newlineprobability');

  h3 = subplot(3,1,3);
  bins = (edges.chorusAngles(1:end-1) + edges.chorusAngles(2:end)) / 2;
  bar(bins, counts.chorusAngles / sum(counts.chorusAngles), 'histc');
  axis(h3, 'tight');
  title(h3, 'Distribution of Chorus Angles');
  ylabel('Estimated\newlineprobability');
  
  % render image maximized to screen
  set(gcf, 'Position', get(0, 'Screensize'));
  % save figure
  saveas(summary, destinationFile);
  close all
end
