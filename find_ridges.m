function [ridges, bwRidges, snrMap, staggeredSnr] = find_ridges(paramfilename, spect)
  %paramfilename has the following variables: 
  % r,tausub,peakfactor_threshold,peakspread_threshold,spread,Delta_psd,Mdelta;
  % close all;
  load(paramfilename);
  medPsd = medfilt2(spect);
  medPsd(medPsd == 0) = min(spect(:));
  [numrows, numcols] = size(spect);
  snrMap = zeros(size(spect));
  for index1 = 1:numrows
      for index2 = 1:numcols
          curval = spect(index1,index2);
          bottom = max((index1-1*r),1);
          top = min((index1+1*r),numrows);
          left = max((index2 - 2*r),1);
          right = min((index2 + 2*r), numcols);
          subimage = spect(bottom:top, left:right);
          
          ind = find(subimage(:) == curval, 1, 'first');
          noiseImage = subimage;
          noiseImage(ind) = nan;
          noise = nanmedian(noiseImage(:));
          snr = max(curval - noise, 0);
          snrMap(index1, index2) = snr;
      end
  end
  

  bwRidges = ones(size(spect));
  bwRidges(medPsd > -55 & snrMap < 10) = 0;
  bwRidges(medPsd <= -55 & medPsd > -65 & snrMap < 15) = 0 ;
  bwRidges(medPsd <= -65 & medPsd > -70 & snrMap < 22.5) = 0 ;
  bwRidges(medPsd <= -70 & medPsd > -80 & snrMap < 25) = 0;
  bwRidges(medPsd <= -80 & medPsd > -90 & snrMap < 35) = 0;
  bwRidges(medPsd <= -90 & snrMap < 40) = 0;
  
%   figure;i1=subplot(2,3,1);imagesc(spect);colormap jet;set(i1,'ydir','normal');
%   temp = spect;
%   temp(temp < -60) = min(spect(:));
%   temp2 = snrMap;
%   temp2(temp2 < 20) = 0;
%   i2=subplot(2,3,2);imagesc(temp);colormap jet;set(i2,'ydir','normal');colorbar
%   i3=subplot(2,3,3);imagesc(temp2);colormap jet;set(i3,'ydir','normal');colorbar
%   i4=subplot(2,3,4);
%   i5=subplot(2,3,5);
%   i6=subplot(2,3,6);
%   pause;close;
  ridges = spect;
  staggeredSnr = snrMap .* bwRidges;
  ridges(bwRidges ~= 1) = min(spect(:));
end