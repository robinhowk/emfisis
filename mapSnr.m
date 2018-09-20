function [ snrMap, features ] = mapSnr( spect, fullSpect, snrThreshold )
%Finds the SNR for each pixel based on an extracted noise sample.

    % get size of spectrogram
    [numRows, ~] = size(spect);
    % calculate the standard deviation of a noise sample
    noiseImage = fullSpect(200:200 + numRows - 1, :);
    
    % calculate SNR for entire burst
    snrMap = spect ./ noiseImage;
    snrMap = (1 ./ snrMap) + 1;
    snrMap = 10*log10(snrMap);

    % threshold SNR
    features = spect;
    features(snrMap < snrThreshold) = min(spect(:));
    
    snrMap(snrMap < 0) = NaN;
end