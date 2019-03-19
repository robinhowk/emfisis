function runBatch
addpath('matlab_cdf364_patch-64');
% ppFilename is path to file containing plasmapause intervals
% fceFilename is path to file containing upper and lower fce values for 1-5
% minute intervals
% cdfMasterFile is path to file containing structure of the cdf files
  % start time
  t1 = tic;
  %------------------------------------------------------------------------
  % Set u
  %------------------------------------------------------------------------
  % get start date, stop date, snrThreshold and source files from user
  [startDate, stopDate, snrPercentile, psdPercentile ppIntervals, ppFilename, ...
    fceTimes, fceLower, fceUpper, fceFilename, ...
    cdfDataMaster, cdfInfoMaster] = getUserInput;
  
  version = 'v3.1.1.1';
  
  % load parameters
  paramfilename = setparam;
  paramstring = paramfilename(1:end-4);
  load(paramfilename);

  % initialize batch counts
  countsBatch = initializeCounts(histEdges, 0);
  totalRecordsBatch = 0;
  
  % get destination file for summary panel
  batchSummaryFigFile = getBatchSummaryDestination(startDate, stopDate, version);
    
  %------------------------------------------------------------------------
  % process each burst
  %------------------------------------------------------------------------
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
    dataPath = sprintf('mat/%04d/%02d/%02d', iDate.Year, iDate.Month, iDate.Day);
    
    % create folders where results and figures will be saved
    [resultsFolder, figFolder, cdfFolder] = createFolders(dataPath, iDate, version);
    
    % get list of files
    filelist = dir(fullfile(dataPath, '*.mat'));
    
    % initilize struct for tracking daily totalts
    countsDay = initializeCounts(histEdges, 500);
    numRecords = 0;
    totalRecordsDay = 0;
    
    dayCounts = struct('chorusAngles', zeros(1, length(histEdges.chorusAngles) - 1), ...
      'sweeprates', zeros(1, length(histEdges.sweeprates) - 1), ...
      'hourlyTotals', zeros(1, 24), ...
      'psdSums', zeros(1,500), ...
      'sweepratesList', zeros(1,500));
            
    % set up variables for cdf data for the day
    cdfData = setupCdfRecords(cdfInfoMaster);
     
    %----------------------------------------------------------------------
    % process each file for the day
    %----------------------------------------------------------------------
    for iFile = 1:size(filelist, 1)
      % get file path for burst
      filename = filelist(iFile).name
      datafilename = sprintf('%s/%s', dataPath, filename);
      data = load(datafilename);
      fspec = data.fspec;
      tspec = data.tspec;
      imagefile = data.imagefile;
      timestamp = data.timestamp
      BuData = data.BuData;
      resultFilename = sprintf('%s/%s_%s.mat', resultsFolder, strtok(filename, '.'), version)
      
      %--------------------------------------------------------------------
      % check if current burst falls within a valid plasmapause interval. 
      % If so, trim spectrogram, scale to 10log10 and continue processing 
      % burst.
      %--------------------------------------------------------------------
      % continue if in plasmapause interval
      if find(timestamp <= ppIntervals(:,2) & ...
          (timestamp + seconds(6)) > ppIntervals(:,1))
        % create filename for result and figure to be saved
        figname = sprintf('%s/%s_%s.jpg', figFolder, strtok(filename, '.'), version);
        
        
        % create spectrogram
        [spect, fspec, fLow, fHigh, isValid] = trimSpectrogram(timestamp, imagefile, ...
          tspec, fspec, fceTimes, fceLower, fceUpper);

        % apply lower threshold of -120  to spectrogram
        spect(spect < -120) = nan;
        
        if isValid
          % create snr map of burst and select features about a given 
          % threshold
          [ridges, bw_ridges, snrMap, snrThreshold, psdThreshold] = find_ridges(paramfilename, spect, snrPercentile, psdPercentile);
        else
          bw_ridges = zeros(size(spect));
        end
        
        % if features are found continue
        if sum(bw_ridges(:)) > 0
          % find spine of detected features
          [skeleton, dist, dist2, segmentLabels, spineLabels, numSpines, spines] = findSpines(ridges);
                 
          if numSpines > 0
            % get information about each spine
            [chorusElements, numChorus] = getSpinesInfo(spineLabels, numSpines, spect, mu1);
          else
            numChorus = 0;
          end
          
          if numChorus > 0
            % create figure
            showBurstFigure( tspec, fspec, spect, snrMap, snrThreshold, ...
              psdThreshold, ridges, segmentLabels, spineLabels, ...
              spines, timestamp, chorusElements, numChorus, ...
              figname, fLow, fHigh, skeleton, dist, dist2, imagefile);
          
            if numRecords + numChorus > numel(cdfData.chorusEpoch)
              numEntries = 1000;
              % reallocate array sizes, add room for 1000
              % more entries
              cdfData.chorusEpoch = [cdfData.chorusEpoch; int64(zeros(numEntries, cdfInfoMaster.Variables{1,2}(1)))];
              cdfData.frequency =  [cdfData.frequency; cdfInfoMaster.VariableAttributes.FILLVAL{4,2} * ones(numEntries, cdfInfoMaster.Variables{4,2}(1))];
              cdfData.psd =  [cdfData.psd; cdfInfoMaster.VariableAttributes.FILLVAL{5,2} * ones(numEntries, cdfInfoMaster.Variables{5,2}(1))];
              cdfData.sweeprate = [cdfData.sweeprate; single(cdfInfoMaster.VariableAttributes.FILLVAL{6,2}) * ones(numEntries, cdfInfoMaster.Variables{6,2}(1))];
              cdfData.burst = [cdfData.burst; int32(zeros(numEntries, cdfInfoMaster.Variables{7,2}(1)))];
            end
            
            % getHistCounts
            burstCounts = getHistCounts(chorusElements, histEdges);
            dayCounts.chorusAngles = dayCounts.chorusAngles + burstCounts.chorusAngles;
            dayCounts.sweeprates = dayCounts.sweeprates + burstCounts.sweeprates;
            dayCounts.hourlyTotals(timestamp.Hour + 1) = dayCounts.hourlyTotals(timestamp.Hour + 1) + numChorus;

            [cdfData, numRecords] = updateCdfRecords(cdfData, chorusElements, timestamp, tspec, fspec, str2double(filename(13:15)), numRecords);

            % add to record count
            totalRecordsDay = totalRecordsDay + numChorus;  
                        
            % save mat file
            save(resultFilename, 'imagefile', 'spect', 'fspec', 'tspec', ...
              'skeleton', 'segmentLabels', ...
              'spineLabels', 'numSpines', 'spines', 'chorusElements', ...
              'paramfilename', 'timestamp', 'BuData');
          else
            % save mat file
              save(resultFilename, 'imagefile', 'spect', 'fspec', ...
                'tspec', 'skeleton', 'segmentLabels', ...
                'spineLabels', 'numSpines', 'spines', ...
                'paramfilename', 'timestamp', 'BuData');
          end
        end % end of burst
      else
        % no ridges, save mat file
%        save(resultFilename, 'imagefile', 'spect', 'fspec', 'tspec', ...
%         'paramfilename', 'timestamp', 'BuData');
      end
      close all;
    end % end of bursts loop
        
    % save cdf file for day
    if totalRecordsDay > 0
      sourceFiles = getSourceFiles( ppFilename, fceFilename, timestamp);
      writeToCdf( cdfFolder, version, iDate, cdfDataMaster, cdfInfoMaster, ...
        cdfData, numRecords, tspec(1), sourceFiles );
    end
        
    % create summary histograms for day
    daySummaryFigFile = sprintf('%s/%04d%02d%02d_a_%s_summary_%s.jpg', ...
      figFolder, iDate.Year, iDate.Month, iDate.Day, paramstring, version);
    showSummaryPanel(countsDay, histEdges, daySummaryFigFile);
        
    % update batch totals
    countsBatch.chorusAngles = countsBatch.chorusAngles + dayCounts.chorusAngles;
    countsBatch.sweeprates = countsBatch.sweeprates + dayCounts.sweeprates;
    countsBatch.hourlyTotals = countsBatch.hourlyTotals + dayCounts.hourlyTotals;
%         batchCounts.psdSums = [batchCounts.psdSums, dayCounts.psdSums(1:totalRecordsDay)];
%         batchCounts.sweepratesList = [batchCounts.sweepratesList, dayCounts.sweepratesList(1:totalRecordsDay)];
        
    % update total records for batch
    totalRecordsBatch = totalRecordsBatch + totalRecordsDay;
    iDate
    totalRecordsDay
    toc(t2)
  end % end of days loop
  % close all files
  fclose('all');
    
  % create summary histograms for batch
  showSummaryPanel(countsBatch, histEdges, batchSummaryFigFile);
    
  totalRecordsBatch
  toc(t1)
end

%--------------------------------------------------------------------------
% getUserInput
% Input: none
% Output: Start and stop date in datetime format
%         snrThreshold - features above this threshold are kept
%         ppIntervals - valid plasmapause intervals
%         fceTimes, fceLower, fceUpper - upper and lower fce values for the
%           corresponding time interval
%         cdfDataMaster and cdfInfoMaster - info loaded from the cdf
%           template
%         ppFilename, fceFilename - path to these files
%--------------------------------------------------------------------------
function [startDate, stopDate, snrThreshold, psdThreshold, ppIntervals, ppFilename, ...
  fceTimes, fceLower, fceUpper, fceFilename, ...
  cdfDataMaster, cdfInfoMaster] = getUserInput
  
  % Get date range from user
  [startDate, stopDate] = getDates;
  
  % get snr threshold from user
  snrThreshold = input('\nEnter SNR percentile to be used: ');
  psdThreshold = input('\nEnter PSD percentile to be used: ');
  
  % confirm selections
  userConfirm =  input('\n Confirm entered values (y/n): ', 's');
  if isequal(userConfirm, 'n')
    [startDate, stopDate, snrThreshold, psdThreshold] = getUserInput;
  end
  
  % load source files
  [ppIntervals, ppFilename, fceTimes, fceLower, fceUpper, fceFilename, ...
    cdfDataMaster, cdfInfoMaster] = loadSourceFiles(startDate, stopDate);
  %------------------------------------------------------------------------
  % getDates
  % Input: none
  % Output: startDate and stopDate in datetime format
  %------------------------------------------------------------------------
  function [startDate, stopDate] = getDates
    % get start date from user
    userStartDate = input('\nEnter start date in the following format yyyyMMdd: ', 's');
    userEndDate = input('\nEnter end date in the following format yyyyMMdd: ', 's');

    % convert dates input by user to datetime format
    startDate = datetime(userStartDate, 'Format', 'yyyyMMdd');
    stopDate = datetime(userEndDate, 'Format', 'yyyyMMdd');
  end

  %------------------------------------------------------------------------
  % loadSourceFiles
  % Input: none
  % Output: ppIntervals, ppFilename, fceTimes, fceLower, fceFilename,
  %         cdfDataMaster, cdfInfoMaster
  %------------------------------------------------------------------------
  function [ppIntervals, ppFilename, fceTimes, fceLower, fceUpper, fceFilename,...
  cdfDataMaster, cdfInfoMaster] = loadSourceFiles(startDate, stopDate)
    % get location of files from user
    ppFilename = getFilename('*.txt', 'plamapause intervals');
    fceFilename = getFilename('*.dat', 'f_ce limits');
    cdfFilename = getFilename('*.cdf', 'cdf master template');
  
    % load data from files
    ppIntervals = getPlasmapauseIntervals(startDate, stopDate, ppFilename);
    [fceTimes, fceLower, fceUpper] = getFceLimits(startDate, stopDate, fceFilename);
    [cdfDataMaster, cdfInfoMaster] = spdfcdfread(cdfFilename);
  end

  %------------------------------------------------------------------------
  % getFilename
  % Input: fileType - extension of desired file
  %        fileContents - description of file
  % Output: filename - path to selected file
  %------------------------------------------------------------------------
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

  %------------------------------------------------------------------------
  % getPlasmapauseIntervals
  % Input: startDate and stopDate in datetime format
  %        ppFilename - path to file containing intervals
  % Output: intervals - matrix containing start and end time for each
  %           interval
  %------------------------------------------------------------------------
  function [ intervals ] = getPlasmapauseIntervals( startDate, stopDate, ppFilename )
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
  
  %------------------------------------------------------------------------
  % getFceLimits
  % Input: start date and stop date in datetime format
  %        fceFilename - path to file containing fce times and limits
  % Output: fceTimes - time of sample
  %         fceLower - lower limit
  %         fceUpper - upper limit
  %------------------------------------------------------------------------
  function [ fceTimes, fceLower, fceUpper ] = getFceLimits( startDate, stopDate, fceFilename )
    fileId = fopen(fceFilename, 'r');
    % import data from file
    data = textscan(fileId, '%s %s %s', 'CommentStyle', '#');
    % create vector of timestamps
    fceTimes = cell2mat(data{:,1});
    fceTimes = datetime(fceTimes, 'Format', 'yyyy-MM-dd''T''HH:mm:ss');

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
end

%--------------------------------------------------------------------------
% Input: histEdges - limits of histograms for chorus angles and sweeprates
%        defaultNum - number of entries to be initialized
% Output: counts - strcut of variables to be tracked
%--------------------------------------------------------------------------
function counts = initializeCounts(histEdges, defaultNum)
  % chorusAnglesBatch - hist counts for chorus angles
  % sweepratesBatch - hist counts for sweeprates
  chorusAngles = zeros(1, length(histEdges.chorusAngles) - 1);
  sweeprates = zeros(1, length(histEdges.sweeprates) - 1);
  hourTotals = zeros(1, 24);
  if defaultNum == 0
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

%--------------------------------------------------------------------------
% getBatchSummaryDestination
% Input: start date and stop date in datetime format
%        version: software version number as a string
% Output: destinationFile - path to where file will be saved
%--------------------------------------------------------------------------
% gets location where summary panel for the batch is saved
function destinationFile = getBatchSummaryDestination(startDate, stopDate, version)
  % create filename for summary image for batch, save in current months folder
  destinationFolder = sprintf('%s/rbsp-a/figures/%04d/%02d', version, startDate.Year, startDate.Month);
  
  if exist(destinationFolder, 'dir') == 0
    mkdir(destinationFolder)
  end
    
  destinationFile = sprintf('%s/%04d%02d%02d_to_%04d%02d%02d_rbsp-a_summary.jpg', ...
    destinationFolder, startDate.Year, startDate.Month, startDate.Day, ...
    stopDate.Year, stopDate.Month, stopDate.Day);
end

%--------------------------------------------------------------------------
% showSummaryPanel
% Input: counts - totals to be displayed
%        edges - limits of histograms for sweeprates and chorus angles
%        destination file - path where image will be saved
% Output: none
%--------------------------------------------------------------------------
function showSummaryPanel( counts, edges, destinationFile )
  summary = figure('visible', 'off');
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
  bar(bins, counts.sweeprates / 1000, 'histc');
  axis(h2, 'tight');
  title(h2, 'Distribution of Sweeprates');
  xlabel('Sweeprate (KHz / sec)');
  ylabel('Estimated\newlineprobability');

  h3 = subplot(3,1,3);
  bins = (edges.chorusAngles(1:end-1) + edges.chorusAngles(2:end)) / 2;
  bar(bins, counts.chorusAngles, 'histc');
  axis(h3, 'tight');
  title(h3, 'Distribution of Chorus Angles');
  ylabel('Estimated\newlineprobability');
  
  % render image maximized to screen
  set(gcf, 'Position', get(0, 'Screensize'));
  % save figure
  saveas(summary, destinationFile);
  close all
end

%--------------------------------------------------------------------------
% createFolders
% Input: datapath - path where data is to be stored
%        date - date of burst
%        version - software version number
% Output: path to results folder, figures folder and cdf folder
%--------------------------------------------------------------------------
function [resultsFolder, figFolder, cdfFolder] = createFolders(datapath, date, version)
    
  resultsFolder = sprintf('%s/rbsp-a/data/%s', version, datapath);
  figFolder = sprintf('%s/rbsp-a/figures/%04d/%02d/%02d', version, date.Year, date.Month, date.Day);
  cdfFolder = sprintf('%s/rbsp-a/data/cdf/%04d/%02d', version, date.Year, date.Month);
  
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

%--------------------------------------------------------------------------
%
%
%
%--------------------------------------------------------------------------
function [spect, fspec, fLow, fHigh, isValid] = trimSpectrogram(timestamp, ...
  imagefile, tspec, fspec, fceTimes, fceLower, fceUpper)
  
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
    if isempty(high) || high > 199
      isValid = false;
      fLow = fspec(1);
      fHigh = fspec(end);
      return;
    end
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
  
  %------------------------------------------------------------------------
  %
  %
  %
  %------------------------------------------------------------------------
  function [ interpValue ] = interpFce( prevTime, nextTime, curTime, prevFce, nextFce )
    %Interpolates Fce Values based on given timestamp. Returns the upper and
    %lower fce limits. Linear interpolation is used on curTime between prevTime 
    %and nextTime to find these values.
        if prevFce < 0 || nextFce < 0
            interpValue = NaN;
            return
        end

        prevTime = datenum(prevTime);
        nextTime = datenum(nextTime);
        curTime = datenum(curTime);
        
        % intermediate values used for calculation
        a = (nextFce - prevFce) / (nextTime - prevTime);
        b = curTime - prevTime;

        % interpolated value
        interpValue = prevFce + (a * b);
    end
end

%--------------------------------------------------------------------------
%
%
%
%--------------------------------------------------------------------------
function [ counts ] = getHistCounts( chorusElements, edges )
    chorusAngles = [chorusElements.chorusAngle];
    sweeprates = [chorusElements.sweeprate];
    
    angleCounts = histcounts(chorusAngles, edges.chorusAngles);
    sweeprateCounts = histcounts(sweeprates / 1000, edges.sweeprates);

    counts = struct('chorusAngles', angleCounts, 'sweeprates', sweeprateCounts);
end

%--------------------------------------------------------------------------
%
%
%
%--------------------------------------------------------------------------
function sourceFiles = getSourceFiles( ppFilename, fceFilename, timestamp)
    date = datestr(timestamp, 'yyyy MM DD');
    year = date(1:4);
    month = date(6:7);
    day = date(9:10);
    
    filelist = dir(sprintf('/var/EMFISIS-SOC/OUT/RBSP-A/L2/%s/%s/%s', year, month, day));
    sourceFiles{1,1} = ppFilename;
    sourceFiles{2,1} = fceFilename;
    
    for i = 1:numel(filelist)
        if contains(filelist(i).name, sprintf('%s%s%s', year, month, day)) ...
                && contains(filelist(i).name, 'waveform-continuous-burst')
            sourceFiles{3,1} = filelist(i).name;
            return
        end
    end
end

%--------------------------------------------------------------------------
%
%
%
%--------------------------------------------------------------------------
function [ cdfData, numRecords ] = updateCdfRecords( cdfData, chorusElements, timestamp, tspec, fspec, burstIndex, numRecords )
    
    % convert timestamp to datevec for tt2000 format conversion
    for i = 1:numel(chorusElements)
      numRecords = numRecords + 1;
      % convert time of first point to tt2000 format
      startTime = chorusElements(i).startInd;
      startTime = tspec(startTime);
      epoch = timestamp + seconds(startTime);
      epoch = datevec(epoch);
      spdfdatenumtott2000(datenum(epoch))
      cdfData.chorusEpoch(numRecords) = spdfdatenumtott2000(datenum(epoch)); %#ok<*SAGROW>


      % add frequency values
      freq = chorusElements(i).freq;
      freq = fspec(freq);
      cdfData.frequency(numRecords, 1:numel(freq)) = freq;

      % add psd values
      psd = chorusElements(i).psd;
      cdfData.psd(numRecords, 1:numel(psd)) = psd;

      % add sweeprate
      cdfData.sweeprate(numRecords) = chorusElements(i).sweeprate;

      % add burst index
      cdfData.burst(numRecords) = burstIndex;

      % add chorus index
      cdfData.chorusIndex(numRecords) = i;       
    end
end

%--------------------------------------------------------------------------
%
%
%
%--------------------------------------------------------------------------
function writeToCdf( cdfFolder, version, date, cdfDataMaster, cdfInfoMaster, data, numRecords, deltaT, sourceFiles )
  filename = sprintf('%s/rbsp-a_chorus-elements_%04d%02d%02d_%s', cdfFolder, date.Year, date.Month, date.Day, version);

  % initialize static variables
  timeOffset = 0:deltaT:(98*deltaT);
  timeOffsetLabel = cdfDataMaster{3};

  varlist{2 * length(cdfInfoMaster.Variables(:,1))} = {};
  datatypes{2 * length(cdfInfoMaster.Variables(:,1))} = {};
  % construct variable list, cell array for cdf file
  for i = 1:length(cdfInfoMaster.Variables(:,1))
    varlist{2 * i - 1} = cdfInfoMaster.Variables{i,1};
    datatypes{2 * i - 1} = cdfInfoMaster.Variables{i, 1};
    datatypes{2 * i} = cdfInfoMaster.Variables{i, 4};
  end

  varlist{2} = data.chorusEpoch(1:numRecords);
  varlist{4} = timeOffset;
  varlist{6} = timeOffsetLabel;
  varlist{8} = data.frequency(1:numRecords, :);
  varlist{10} = data.psd(1:numRecords, :);
  varlist{12} = data.sweeprate(1:numRecords);
  varlist{14} = data.burst(1:numRecords);
  varlist{16} = data.chorusIndex(1:numRecords);

  % construct recordbound variable list
  rbvars = {cdfInfoMaster.Variables{:,1}};
  for i = length(cdfInfoMaster.Variables(:,1)):-1:1
     if (strncmpi(cdfInfoMaster.Variables{i,5}, 'f', 1) == 1)
         rbvars(:,i) = [];
     end
  end
  
  ga = cdfInfoMaster.GlobalAttributes;
  ga.FFT_size = {'1024'};
  d1 = datestr(datetime('now'), 'ddd mmm dd HH:MM:SS');
  d2 = datestr(datetime('now'), 'yyyy');
  created = sprintf('%s CDT %s', d1, d2);
  ga.Generation_date = {created};
  ga.Source_file_list = sourceFiles;

  spdfcdfwrite(filename, varlist, ...
          'GlobalAttributes', cdfInfoMaster.GlobalAttributes, ...
          'VariableAttributes', cdfInfoMaster.VariableAttributes, ...
          'RecordBound', rbvars, ...
          'Vardatatypes', datatypes, ...
          'CDFLeapSecondLastUpdated', cdfInfoMaster.FileSettings.LeapSecondLastUpdated);
end

%--------------------------------------------------------------------------
%
%
%
%--------------------------------------------------------------------------

function [ cdfData ] = setupCdfRecords( cdfInfoMaster )
% initialize cdf matrixes/vectors with space allocated for 100 entries
  numEntries = 1000;
  cdfData = struct( 'chorusEpoch', ...
      int64(zeros(numEntries, cdfInfoMaster.Variables{1,2}(1))), ...
    'frequency', ...
      cdfInfoMaster.VariableAttributes.FILLVAL{4,2} * ones(numEntries, cdfInfoMaster.Variables{4,2}(1)), ...
    'psd', ...
      cdfInfoMaster.VariableAttributes.FILLVAL{5,2} * ones(numEntries, cdfInfoMaster.Variables{5,2}(1)), ...
    'sweeprate', ...
      single( cdfInfoMaster.VariableAttributes.FILLVAL{6,2}) * zeros(numEntries, cdfInfoMaster.Variables{6,2}(1)), ...
    'burst', ...
      int32(zeros(numEntries, cdfInfoMaster.Variables{7,2}(1))), ...
    'chorusIndex', ...
      int32(zeros(numEntries, cdfInfoMaster.Variables{8,2}(1))));
end