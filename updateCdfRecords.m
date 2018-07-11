function [ cdfData, numRecords ] = updateCdfRecords( cdfData, chorusElements, timestamp, tspec, fspec, burstIndex, numRecords )
    
    % convert timestamp to datevec for tt2000 format conversion
    for i = 1:numel(chorusElements)
       numRecords = numRecords + 1;
       % convert time of first point to tt2000 format
       startTime = chorusElements(i).time;
       startTime = tspec(startTime(1));
       epoch = timestamp + seconds(startTime);
       epoch = datevec(epoch);
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

