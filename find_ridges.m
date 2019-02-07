
function [ridges, bwRidges, snrMap, snrThreshold, psdThreshold] = find_ridges(paramfilename, spect, snrPercentile, psdPercentile)
  %paramfilename has the following variables: 
  % r,tausub,peakfactor_threshold,peakspread_threshold,spread,Delta_psd,Mdelta;
  % close all;
  load(paramfilename);

  minval = min(min(spect(spect ~= -Inf)));
  spect(spect == -Inf) = minval;
  imagefilenew = (spect - minval);
%   len = (length(thetavec)); %#ok<NODEF>
%   thetavec = thetavec(1:len/2);
  [numrows, numcols] = size(spect);
%   ridges = minval*ones(numrows,numcols);
  bwRidges = zeros(size(spect));
  snrMap = zeros(size(spect));
  for index1 = 1:numrows
      for index2 = 1:numcols
          curval = imagefilenew(index1,index2);
          bottom = max((index1-2*r),1);
          top = min((index1+2*r),numrows);
          left = max((index2 - 3*r),1);
          right = min( (index2+3*r), numcols);

          subimage = imagefilenew(bottom:top, left:right);
%           radsubimage = radon(subimage,thetavec);
%           maxsubimage = max(subimage(:));

%           deltasub = (maxsubimage - curval)/(maxsubimage);
%           minThreshold = prctile(subimage(:), 30);

          ind = find(subimage(:) == curval, 1, 'first');
          noiseImage = subimage;
          noiseImage(ind) = [];
          noise = std(noiseImage(:));
          snr = curval / noise;

  %         figure;i1=subplot(1,2,1);imagesc(radsubimage);colormap jet;set(i1,'ydir', 'normal');
%           [val, ind] = max(max(radsubimage));
%           slice = radsubimage(:, ind);
  %         i2=subplot(1,2,2);plot(slice);
  %         hold on;
%           [pks, loc] = findpeaks(slice);
  %         findpeaks(slice, 'annotate', 'extents', 'widthreference', 'halfheight');
%           dist = abs(slice - (val/2));
%           [~, pl] = min(dist(1:loc));
%           [~, pr] = min(dist(loc:end));
%           pr = pr + loc - 1;
  %         plot([pl, pr], [slice(pl), slice(pr)], 'r*');
%           signal = sum(slice(pl:pr));
%           noise = sum(slice) - signal;
%           snr = signal / noise;

  %         pause;close;
          snrMap(index1, index2) = snr;

  %         if curval > minThreshold && ~isnan(curval)
  %             [chorus_flag] = isbraid(radsubimage,theta_phi,thetavec,spread);
  %             if chorus_flag
  %                 ridges(index1,index2) = (spect(index1,index2));
  %                 bw_ridges(index1,index2) = 1;
  %             end
  %         end
      end
  end
  ridges = spect;
  bwRidges1 = bwRidges;
  bwRidges2 = bwRidges;
  snrThreshold = prctile(snrMap(:), snrPercentile);
  psdThreshold = prctile(spect(:), psdPercentile);
  bwRidges1(snrMap >= snrThreshold) = 1;
  bwRidges2(spect >= psdThreshold) = 1;
  bwRidges = bwRidges1 | bwRidges2;
  bwRidges(spect < -90) = 0;
  ridges(bwRidges ~= 1) = nan;
end