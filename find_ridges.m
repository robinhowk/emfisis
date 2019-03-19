function [ridges, bwRidges, snrMap, staggeredSnr] = find_ridges(paramfilename, spect)
  %paramfilename has the following variables: 
  % r,tausub,peakfactor_threshold,peakspread_threshold,spread,Delta_psd,Mdelta;
  % close all;
  load(paramfilename);

  [numrows, numcols] = size(spect);
  snrMap = zeros(size(spect));
  for index1 = 1:numrows
      for index2 = 1:numcols
          curval = spect(index1,index2);
          bottom = max((index1-2*r),1);
          top = min((index1+2*r),numrows);
          left = max((index2 - 3*r),1);
          right = min((index2 + 3*r), numcols);
          subimage = spect(bottom:top, left:right);
          
          ind = find(subimage(:) == curval, 1, 'first');
          noiseImage = subimage;
          noiseImage(ind) = [];
          noise = median(noiseImage);
          snr = max(curval - noise, 0);
          snrMap(index1, index2) = snr;
      end
  end
  
  medPsd = medfilt2(spect);
  bwRidges = ones(size(spect));
  
  bwRidges(medPsd > -65 & snrMap < 22) = 0;
  bwRidges(medPsd <= -65 & medPsd > -90 & snrMap < 30) = 0;
  bwRidges(medPsd <= -90 & snrMap < 40) = 0;
  
  ridges = spect;
  staggeredSnr = snrMap .* bwRidges;
  ridges(bwRidges ~= 1) = -100;
end