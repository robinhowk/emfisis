function [totalRecordsBatch, batchCounts] = runBatch( startDate, stopDate, ppFilename, fceFilename, cdfMasterFile )
% format for start and stop date 'yyyy-MM-dd'
% ppFilename is path to file containing plasmapause intervals
% fceFilename is path to file containing upper and lower fce values for 1-5
% minute intervals
% cdfMasterFile is path to file containing structure of the cdf files

    % time to record batch processing time
    t1 = tic;
    startDate = datetime(startDate, 'Format', 'yyyy-MM-dd');
    stopDate = datetime(stopDate, 'Format', 'yyyy-MM-dd');

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
        % time to record burst processing time
        t2 = tic;

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
            load(datafilename);
            
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
        % stop timer
        toc(t2)
    end % end of days loop
    % close all files
    fclose('all');
    
    % create summary histograms for batch
    showSummaryPanel(batchCounts, histEdges, summaryFigBatch);
    
    totalRecordsBatch   
    toc(t1)
end