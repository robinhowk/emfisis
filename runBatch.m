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
    userStartDate = input('Enter start date in the following format yyyyMMdd: ', 's');
    userEndDate = input('Enter end date in the following format yyyyMMdd: ', 's');
    
    % convert dates input by user to datetime format
    startDate = datetime(userStartDate, 'Format', 'yyyyMMdd');
    stopDate = datetime(userEndDate, 'Format', 'yyyyMMdd');
    
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
    [ppIntervals, fceTimes, fceLimits, cdfDataMaster, cdfInfoMaster] = ...
      loadSourceFiles(startDate, stopDate);
    
    % create error log
    errorLog = sprintf('logs/error_log_%s_to_%s_a.txt', datestr(startDate, 'yyyymmdd'), datestr(stopDate, 'yyyymmdd'));
    errorLogId = fopen(errorLog, 'w');
    
    % initialize batch counts
    countsBatch = initializeBatchCounts(histEdges);
    totalRecordsBatch = 0;
    
%--------------------------------------------------------------------------
  % move to end when creating image?
    [summaryFigBatch] ...
        = setupBatch(startDate, stopDate);

%--------------------------------------------------------------------------
% process each burst

    for iDate = startDate:stopDate
        % start timer
        t2 = tic;
        
        [dataPath, resultsFolder, figFolder, summaryFigDay, cdfFilename, filelist, countsDay] = setupDay( iDate, paramstring, histEdges);
        cdfData = setupCdfRecords(cdfInfoMaster);
        numRecords = 0;
        totalRecordsDay = 0;
        
        for iFile = 1:size(filelist,1)
            % get file path for burst
            filename = filelist(iFile).name;
            datafilename = sprintf('%s/%s', dataPath, filename);
            load(datafilename);
            
            % continue if in plasmapause interval
            if find(timestamp <= ppIntervals(:,2) & (timestamp + seconds(6)) > ppIntervals(:,1))
                % create imagefile
                % create timestamp with one second precision to find freq
                % limit
                tempTime = datevec(timestamp);
                tempTime(6) = floor(tempTime(6));
                tempTime = datetime(tempTime);
                freqLimit = fceLimits(find((fceTimes > tempTime), 1));
                freqLimit = find((fspec > freqLimit), 1);
                [figname, resultFilename, imagefile, imagefile1, fspec] = setupBurst(filename, datafilename, paramstring, figFolder, resultsFolder, freqLimit, delta_psd);
                [ridges, bwRidges] = find_ridges(paramfilename, datafilename, imagefile1);
                
                % if ridges are found, continue
                if sum(sum(bwRidges)) >  0
                    ridgesZero = ridges - min(min(ridges));
                    [spine, bwSpine] = center_of_mass(ridgesZero, 2, 2);
                    [ chorusElements, tracedElements, chorusCount ] = traceBurst( bwSpine, spine, imagefile, fspec, tspec, mu1, ridgesZero, errorLogId, filename);
                    
                    % create figure
                    showBurstFigure(tspec, fspec, delta_psd, imagefile1, ridges, spine, tracedElements, chorusElements, chorusCount, histEdges.sweeprates, figname);
                    
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
                        save(resultFilename, 'imagefile', 'imagefile1', 'fspec', 'tspec', 'ridges', 'bwRidges', 'chorusElements', 'paramfilename', 'timestamp', 'tracedElements', 'spine', 'bwSpine');
                    else
                        % save mat file
                        save(resultFilename, 'imagefile', 'imagefile1', 'fspec', 'tspec', 'ridges', 'bwRidges', 'paramfilename', 'timestamp');
                    end
                else
                    % no ridges, save mat file
                    save(resultFilename, 'imagefile', 'imagefile1', 'fspec', 'tspec', 'paramfilename', 'timestamp');
                end
            end % end of burst
        end % end day
        
         % save summary data for day
        resultsDayFilename = sprintf('%s/%04d%02d%02d_summary.mat', resultsFolder, iDate.Year, iDate.Month, iDate.Day);
        save(resultsDayFilename, 'countsDay', 'totalRecordsDay');

        % save cdf file for day
        if totalRecordsDay > 0
            writeToCdf( cdfFilename, cdfDataMaster, cdfInfoMaster, cdfData, numRecords, tspec(1) );
        end

        % create summary histograms for day
        showSummaryPanel(countsDay, histEdges, summaryFigDay);
        
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
    showSummaryPanel(countsBatch, histEdges, summaryFigBatch);
    
    totalRecordsBatch   
    toc(t1)
end

function [ppIntervals, fceTimes, fceLimits, cdfDataMaster, cdfInfoMaster] = loadSourceFiles(startDate, stopDate)
  % get location of files from user
  ppFilename = getFilename('*.txt', 'plamapause intervals');
  fceFilename = getFilename('*.dat', 'f_ce limits');
  cdfFilename = getFilename('*.cdf', 'cdf master template');
  
  % load data from files
  ppIntervals = getPlasmapauseIntervals(startDate, stopDate, ppFilename);
  [fceTimes, fceLimits] = getFceLimits(startDate, stopDate, fceFilename);
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

function countsBatch = initializeBatchCounts(histEdges)
    % chorusAnglesBatch - hist counts for chorus angles
    % sweepratesBatch - hist counts for sweeprates
    chorusAngles = zeros(1, length(histEdges.chorusAngles) - 1);
    sweeprates = zeros(1, length(histEdges.sweeprates) - 1);
    hourTotals = zeros(1, 24);
    psdSums = [];
    sweepratesList = [];
    countsBatch = struct('chorusAngles', chorusAngles, ...
                         'sweeprates', sweeprates, ...
                         'hourlyTotals', hourTotals, ...
                         'psdSums', psdSums, ...
                         'sweepratesList', sweepratesList);
    
end


