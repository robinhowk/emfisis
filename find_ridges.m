function [ridges, bwRidges, maxPoints, snrMap, snrThreshold, psdThreshold] = find_ridges(paramfilename, spect, snrPercentile, psdPercentile)
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
  psdGradient = zeros(size(spect));
  psdThreshold = prctile(spect(:), psdPercentile);
  
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
          noise = nanstd(noiseImage(:));
          snr = curval / noise;
          
          %check if current pixel is max in window. If max keep this pixel
          %and all points within specified psd range
          if curval > psdThreshold - minval && curval == max(subimage(:))
            subimage(subimage < curval - 15) = 0;
            subimage(subimage ~= 0) = 1;
            psdGradient(bottom:top, left:right) = psdGradient(bottom:top, left:right) | subimage;
          end

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
%   bwRidges3 = bwRidges;
  snrThreshold = prctile(snrMap(:), snrPercentile);
  
%   if snrThreshold > 4
%     snrPercentile = snrPercentile - 10;
%     snrThreshold = prctile(snrMap(:), snrPercentile);
%   end
  bwRidges1(snrMap >= snrThreshold) = 1;
  bwRidges2(spect >= psdThreshold) = 1;
%   bwRidges3(psdGradient ~= 0) = 1;
  bwRidges = bwRidges1 | bwRidges2 | psdGradient;
  maxPoints = spect;
  maxPoints(psdGradient ~= 1) = -100;
  ridges(bwRidges ~= 1) = -100;
  
%   figure;i1=subplot(1,1,1);imagesc(psdGradient);set(i1,'ydir','normal');colormap jet;
end