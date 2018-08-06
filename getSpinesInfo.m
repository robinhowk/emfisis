function spinesInfo = getSpinesInfo(spineLabels, numSpines, spect, mu1)
  % preallocate struct
  numSpines
  spinesInfo(numSpines) = struct();
  
  for i = 1:numSpines
    % get the current spine
    curSpine = spineLabels == i;
    % get the time spanned by the spine
    [fcur, tcur] = find(curSpine == 1);
    tvec = min(tcur):1:max(tcur);
    if numel(tvec) < 100
      %----------------------------------------------------------------------
      % find frequency vector
      %----------------------------------------------------------------------
      % find a 3rd degree polynomial to approximate which points are save to
      % the cdf file
      p3 = polyfit(tcur, fcur, 3);
      fp3 = polyval(p3, tvec);
      % calculate the adjusted r value for this fit
      rbar3 = calcAdjRsquared(f, fp3);
      % round fp3 for indexing
      fp3 = round(fp3);

      %----------------------------------------------------------------------
      % find psd vector
      %----------------------------------------------------------------------
      psdVec = zeros(1, numel(fp3));
      for j = 1:numel(fp3)
        psdVec(j) = spect(fp3(j), tvec(j));
      end

      %----------------------------------------------------------------------
      % find sweeprate and chorus angle
      %----------------------------------------------------------------------
      % find a 1st degree polynomial to estimate the orientation of the
      % chorus element
      p1 = polyfit(tcur, fcur, 1);
      fp1 = polyval(p1, tvec);
      % calculate the adjusted r value for this fit
      rbar1 = calcAdjRsquared(f, fp1);
      % use slope to calculate sweeprate and angle
      sweeprate = p1(1) * mu1;
      chorusAngle = atand(p(1));

      %----------------------------------------------------------------------
      % update struct
      %----------------------------------------------------------------------
      spinesInfo(i).startInd = tvec(1);
      spinesInfo(i).stopInd = tvec(end);
      spinesInfo(i).freq = fp3;
      spinesInfo(i).psd = psdVec;
      spinesInfo(i).sweeprate = sweeprate;
      spinesInfo(i).chorusAngle(i) = chorusAngle;
      spinesInfo(i).p1 = p1;
      spinesInfo(i).rbar1 = rbar1;
      spinesInfo(i).fp1 = round(fp1);
      spinesInfo(i).p3 = p3;
      spinesInfo(i).rbar3 = rbar3;
    end
  end
  
  function rbarSquared = calcAdjRsquared( f, fp )
    fbar = mean(f);
    ssTot = sum((f - fbar) .^ 2);
    ssRes = sum((f-fp) .^ 2);
    rsquared = 1 - (ssRes / ssTot);
    rbarSquared = 1 - (1 - rsquared) * ( (numel(fs) - 1) / (numel(fs) - 2));
  end
end

