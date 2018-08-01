function [ cdfData, numRecords ] = updateCdfRecords( cdfData, chorusElements, timestamp, tspec, burstIndex, numRecords )
    
    % convert timestamp to datevec for tt2000 format conversion
    for i = 1:numel(chorusElements)
       numRecords = numRecords + 1;
       % convert time of first point to tt2000 format
       epoch = timestamp + seconds(tspec(chorusElements(i).start.time));
       epoch = datevec(epoch);
       cdfData.chorusEpoch(numRecords) = spdfdatenumtott2000(datenum(epoch)); %#ok<*SAGROW>
       
       % add nonzero frequency values
       freq = chorusElements(i).freq;
       cdfData.frequency(numRecords, freq > 0) = freq(freq > 0);
       
       % add nonzero psd values
       psd = chorusElements(i).psd;
       cdfData.psd(numRecords, psd > 0) = psd(psd > 0);
       
       % add sweeprate
       cdfData.sweeprate(numRecords) = chorusElements(i).sweeprate;
       
       % add burst index
       cdfData.burst(numRecords) = burstIndex;
       
       % add chorus index
       cdfData.chorusIndex(numRecords) = i;       
    end
end

