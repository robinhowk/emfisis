function [ snrMap, features ] = mapSnr( spect, fullSpect, snrThreshold )
%Finds the SNR for each pixel based on an extracted noise sample.

    % shift spectrogram to positive values.
    spect0 = spect - min(spect(:));
    % calculate the standard deviation of a noise sample
    noiseSample = fullSpect(200:300, :);
    stdNoise = std2(noiseSample);
    
    % calculate SNR for entire burst
    snrMap = 10*log10(spect0 / stdNoise);

    % threshold SNR
    features = spect;
    features(snrMap < snrThreshold) = NaN;
end