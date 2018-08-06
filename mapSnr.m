function [ snrMap, features ] = mapSnr( spect, fullSpect, snrThreshold )
%Finds the SNR for each pixel based on an extracted noise sample. Returns
%features with SNR higher than given threshold and sets all other values to
%min value of spectrogram

  % shift spectrogram so min value starts at 0
  spect0 = spect - min(spect(:));
  noiseSample = fullSpect(200:300, :);
  stdNoise = std2(noiseSample);
    
  % calculate SNR for entire burst
  snrMap = 10*log10(spect0 / stdNoise);

  % threshold SNR
  features = spect;
  features(snrMap < snrThreshold) = min(spect(:));
  snrMap(snrMap < 0) = NaN;
  
end

