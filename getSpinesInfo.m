function [spinesInfo, totalSpines] = getSpinesInfo(spineLabels, numSpines, spect, mu1)
  % preallocate struct
  spinesInfo = struct();
  totalSpines = 0;
  [numRows, numCols] = size(spect);
  
  for i = 1:numSpines
    % get the current spine
    curSpine = spineLabels == i;
    % get the time spanned by the spine
    [fcur, tcur] = find(curSpine == 1);
    tvec = min(tcur):1:max(tcur);
    if numel(tvec) < 100 && ~isempty(tvec) && (max(fcur) - min(fcur) > 4)
      %--------------------------------------------------------------------
      % find sweeprate and chorus angle
      %--------------------------------------------------------------------
      % find a 1st degree polynomial to estimate the orientation of the
      % chorus element
      p1 = polyfit(tcur, fcur, 1);
      fp1 = polyval(p1, tvec);
      % calculate the adjusted r value for this fit
      rbar1 = calcAdjRsquared(fcur, fp1);
      % use slope to calculate sweeprate and angle
      sweeprate = p1(1) * mu1;
      chorusAngle = atand(p1(1));
      fp1 = round(fp1);
      fp1(fp1 < 1) = 1;
      fp1(fp1 > numRows) = numRows;
      
      % reject angles over 88 degree to prevent indexing errors on vertical
      % lines
      if chorusAngle < 88
        %------------------------------------------------------------------
        % find frequency vector
        %------------------------------------------------------------------
        % find a 3rd degree polynomial to approximate which points are save to
        % the cdf file. If there are not enough points, use results from 1st
        % degree fit
        if numel(tvec) > 5
          p3 = polyfit(tcur, fcur, 3);
          fp3 = polyval(p3, tvec);
          % calculate the adjusted r value for this fit
          rbar3 = calcAdjRsquared(fcur, fp3);
        else
          p3 = p1;
          fp3 = fp1;
          rbar3 = rbar1;
        end
        % round fp3 for indexing
        fp3 = round(fp3);
        fp3(fp3 < 1) = 1;
        fp3(fp3 > numRows) = numRows;

        %------------------------------------------------------------------
        % find psd vector
        %------------------------------------------------------------------
        psdVec = zeros(1, numel(fp3));
        for j = 1:numel(fp3)
          psdVec(j) = spect(fp3(j), tvec(j));
        end

        %------------------------------------------------------------------
        % update struct
        %------------------------------------------------------------------
        totalSpines = totalSpines + 1;
        spinesInfo(totalSpines).startInd = tvec(1);
        spinesInfo(totalSpines).stopInd = tvec(end);
        spinesInfo(totalSpines).freq = fp3;
        spinesInfo(totalSpines).psd = psdVec;
        spinesInfo(totalSpines).sweeprate = sweeprate;
        spinesInfo(totalSpines).chorusAngle = chorusAngle;
        spinesInfo(totalSpines).p1 = p1;
        spinesInfo(totalSpines).rbar1 = rbar1;
        spinesInfo(totalSpines).fp1 = round(fp1);
        spinesInfo(totalSpines).p3 = p3;
        spinesInfo(totalSpines).rbar3 = rbar3;
      end
    end
  end
  
  function rbarSquared = calcAdjRsquared( f, fp )
    fbar = mean(f);
    ssTot = sum((f - fbar) .^ 2);
    ssRes = sum((f-fp) .^ 2);
    rsquared = 1 - (ssRes / ssTot);
    rbarSquared = 1 - (1 - rsquared) * ( (numel(f) - 1) / (numel(f) - 2));
  end
end

