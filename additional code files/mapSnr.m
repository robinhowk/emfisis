function [ snrMap, snrThreshold, features ] = mapSnr( spect, fullSpect, snrPercentile )
%Finds the SNR for each pixel based on an extracted noise sample.

    % get size of spectrogram
    [numRows, ~] = size(spect);
    size(fullSpect)
    % calculate the standard deviation of a noise sample
    try 
      noiseImage = fullSpect(200:200 + numRows - 1, :);   
      % calculate SNR for entire burst
      snrMap = spect ./ noiseImage;
      snrMap = (1 ./ snrMap) + 1;
      snrMap = 10*log10(snrMap);
    
      % threshold SNR
      snrThreshold = prctile(snrMap(:), snrPercentile);
      features = spect;
      features(snrMap < snrThreshold) = min(spect(:));
      
      snrMap(snrMap < 0) = NaN;
    catch ME
      snrMap = NaN(size(spect));
      snrThreshold = nan;
      features = NaN(size(spect));
    end
end