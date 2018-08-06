function runBatch
addpath('matlab_cdf364_patch-64');
% ppFilename is path to file containing plasmapause intervals
% fceFilename is path to file containing upper and lower fce values for 1-5
% minute intervals
% cdfMasterFile is path to file containing structure of the cdf files
  
  %------------------------------------------------------------------------
  % Set up
  %------------------------------------------------------------------------
  % get start date, stop date, snrThreshold and source files from user
  [startDate, stopDate, snrThreshold, ppIntervals, ppFilename, ...
    fceTimes, fceLower, fceUpper, fceFilename, ...
    cdfDataMaster, cdfInfoMaster] = getUserInput
  

    % set up parameters
    paramfilename = setparam;
    paramstring = paramfilename(1:end-4);

    % set up folders for summary images
    summaryFigBatch = setupBatchFig( startDate, stopDate, paramstring );

    % import plasmapause intervals
    ppIntervals = getPlasmapauseIntervals(startDate, stopDate, ppFilename);

    % import fce limits
    [fceTimes, fceLower, fceUpper] = getFceLimits(startDate, stopDate, fceFilename);

    % initialize variables
    [ batchCounts ] = initializeVariables( paramfilename );

    % load info for cdf files
    [cdfDataMaster, cdfInfoMaster] = spdfcdfread(cdfMasterFile);

    load(paramfilename);
    totalRecordsBatch = 0;
    
    for iDate = startDate:stopDate

        % set up image folders and filenames for day
        [ figFolder, summaryFigDay] = setupDayFigFolder( iDate, paramstring );

        % set up folders and filename for saving data
        [ dataPath, resultsFolder ] = setupDataFolderDay (iDate);

        % set up cdf file
        [ cdfFilename ] = setupCdfFile( iDate );

        % initialize list of files for the day
        filelist = dir(fullfile(dataPath, '*.mat'));

        dayCounts = struct('chorusAngles', zeros(1, length(histEdges.chorusAngles) - 1), ...
                'sweeprates', zeros(1, length(histEdges.sweeprates) - 1), ...
                'hourlyTotals', zeros(1, 24), ...
                'psdSums', zeros(1,500), ...
                'sweepratesList', zeros(1,500));
            
        % set up variables for cdf data for the day
        cdfData = setupCdfRecords(cdfInfoMaster);
        numRecords = 0;
        totalRecordsDay = 0;
        skipped = {};
        numSkipped = 0;
        
        for iFile = 1:size(filelist, 1)
            % get file path for burst
            filename = filelist(iFile).name
            datafilename = sprintf('%s/%s', dataPath, filename);
            burstVar = load(datafilename);
            tspec = burstVar.tspec;
            fspec = burstVar.fspec;
            imagefile = burstVar.imagefile;
            timestamp = burstVar.timestamp;
            
            % continue if in plasmapause interval
            if find(timestamp <= ppIntervals(:,2) & (timestamp + seconds(6)) > ppIntervals(:,1))
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
                
                % if there was no valid fce limits skip this burst
                if ~isnan(fLow)
                    spect = 10*log10(imagefile);
                    [spect, fspec] = trimSpect(spect, fspec, fLow, fHigh);
                    
                    % setup burst information for processing
                    figname = sprintf('%s/%s_%s.jpg', figFolder, strtok(filename, '.'), paramstring);
                    resultFilename = sprintf('%s/%s_result.mat', resultsFolder, strtok(filename, '.'));
                    % calculate ridge transform
                    ridges = find_chorus(paramfilename, spect);
                    % calculate spines
                    spines = findSpines(ridges);
                    [spinesSnr, spineSegments, numSegments] = fitSpines(spines, spect, 5);                    
%                     spinesSnr = removeNoise(spinesSnr);
                    [spinesFinal, chorusCount, chorusElements] = selectSpines(spineSegments, numSegments, tspec, fspec, imagefile, spect, mu1);
                    
                    if chorusCount > 0
                        if numRecords + chorusCount > numel(cdfData.chorusEpoch)
                            numEntries = 1000;
                            % reallocate array sizes, add room for 1000
                            % more entries
                            cdfData.chorusEpoch = [cdfData.chorusEpoch; int64(zeros(numEntries, cdfInfoMaster.Variables{1,2}(1)))];
                            cdfData.frequency =  [cdfData.frequency; cdfInfoMaster.VariableAttributes.FILLVAL{4,2} * ones(numEntries, cdfInfoMaster.Variables{4,2}(1))];
                            cdfData.psd =  [cdfData.psd; cdfInfoMaster.VariableAttributes.FILLVAL{5,2} * ones(numEntries, cdfInfoMaster.Variables{5,2}(1))];
                            cdfData.sweeprate = [cdfData.sweeprate; single(cdfInfoMaster.VariableAttributes.FILLVAL{6,2}) * ones(numEntries, cdfInfoMaster.Variables{6,2}(1))];
                            cdfData.burst = [cdfData.burst; int32(zeros(numEntries, cdfInfoMaster.Variables{7,2}(1)))];
                            cdfData.chorusIndex = [cdfData.chorusIndex; int32(zeros(numEntries, cdfInfoMaster.Variables{8,2}(1)))];
                        end
                            % getHistCounts
                            burstCounts = getHistCounts(chorusElements, histEdges);
                            dayCounts.chorusAngles = dayCounts.chorusAngles + burstCounts.chorusAngles;
                            dayCounts.sweeprates = dayCounts.sweeprates + burstCounts.sweeprates;
                            dayCounts.hourlyTotals(timestamp.Hour + 1) = dayCounts.hourlyTotals(timestamp.Hour + 1) + chorusCount;
                         
                            [cdfData, numRecords] = updateCdfRecords(cdfData, chorusElements, timestamp, tspec, fspec, str2double(filename(13:15)), numRecords);
                            
                            % add to record count
                            totalRecordsDay = totalRecordsDay + chorusCount;
                            
                            showBurstFigure( tspec, fspec, spect, ridges, timestamp, spines, spinesSnr, spinesFinal, chorusElements, chorusCount, histEdges.sweeprates, figname, fLow, fHigh )
                        
                    end
                        
                        % save mat file
                        save(resultFilename, 'imagefile', 'spect', 'fspec', 'tspec', 'ridges', ...
                            'spinesFinal',  'paramfilename', 'timestamp');
                else
                    numSkipped = numSkipped + 1;
                    skipped{numSkipped} = {fprintf('%s, %s', datestr(timestamp), filename)};
                end % end of burst
            end
            close all;
        end % end of bursts loop
        
        % save cdf file for day
        if totalRecordsDay > 0
            writeToCdf( cdfFilename, cdfDataMaster, cdfInfoMaster, cdfData, numRecords, ppFilename, fceFilename, timestamp, tspec(1) );
        end
        
         % create summary histograms for day
        showSummaryPanel(dayCounts, histEdges, summaryFigDay);
        
        % write skipped bursts to file
        if numSkipped > 0
            skippedFilename = sprintf('docs/skipped/rbspa/%04d%02d%02d_skipped_bursts', iDate.Year, iDate.Month, iDate.Day);
            fid = fopen(skippedFilename, 'wt');
            for n = 1:numSkipped
               fprintf(fid, '%s\n', skippedFilename{n}{:});
            end
            fclose(fid);
        end
        % update batch totals
        batchCounts.chorusAngles = batchCounts.chorusAngles + dayCounts.chorusAngles;
        batchCounts.sweeprates = batchCounts.sweeprates + dayCounts.sweeprates;
        batchCounts.hourlyTotals = batchCounts.hourlyTotals + dayCounts.hourlyTotals;
%         batchCounts.psdSums = [batchCounts.psdSums, dayCounts.psdSums(1:totalRecordsDay)];
%         batchCounts.sweepratesList = [batchCounts.sweepratesList, dayCounts.sweepratesList(1:totalRecordsDay)];
        
        % update total records for batch
        totalRecordsBatch = totalRecordsBatch + totalRecordsDay;
        iDate
        totalRecordsDay
    end % end of days loop
    % close all files
    fclose('all');
    
    % create summary histograms for batch
    showSummaryPanel(batchCounts, histEdges, summaryFigBatch);
    
    totalRecordsBatch
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
function [startDate, stopDate, snrThreshold, ppIntervals, ppFilename, ...
  fceTimes, fceLower, fceUpper, fceFilename, ...
  cdfDataMaster, cdfInfoMaster] = getUserInput
  
  % Get date range from user
  [startDate, stopDate] = getDates;
  
  % get snr threshold from user
  snrThreshold = input('\nEnter SNR threshold to be used: ');
  
  % confirm selections
  userConfirm =  input('\n Confirm entered values (y/n): ', 's');
  if isequal(userConfirm, 'n')
    return
  else
    [startDate, stopDate, snrThreshold] = getUserInput;
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
end