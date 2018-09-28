function [ skeleton, segmentLabels, spineLabels, numSpines, spines ] = findSpines( ridges )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
    
  % find the skeleton of ridge features
  skeleton = skeletonize(ridges);

  % identify each segment of the skeleton
  [segmentLabels, numSegments, bpoints, epoints] = identifySegments(skeleton);

  % classify each branch point
  bpointInfo = classifyBpoints( segmentLabels, bpoints, epoints );

  [spineLabels, numSpines] = identifySpines( skeleton, segmentLabels, numSegments, bpoints, bpointInfo );
  
  spines = zeros(size(spineLabels));
  spines(spineLabels > 0) = 1;
end


%--------------------------------------------------------------------------
% skeletonize
% Input: ridges - ridge features from SNR map
% Output: spines - spines extracted from ridge along gradient
% Extracts the domint ridges along the gradient, creating skeleton of ridge
% features
%--------------------------------------------------------------------------
function skeleton = skeletonize( ridges )
  % create binary version of ridge features
  ridges = ridges - min(ridges(:));
  bwRidges = ridges;
  bwRidges(bwRidges > min(ridges(:))) = 1;
  bwRidges(bwRidges ~= 1) = 0;
  bwRidges = bwmorph(bwRidges, 'fill');
  
  % thin and clean skeleton
  skeleton = bwmorph(bwRidges, 'thin', Inf);  
  skeleton = bwmorph(skeleton, 'clean');
  
  % pad skeleton so edges can be reached for further cleaning
  skeleton = padarray(skeleton, [2 2], 0, 'both');
  
  % remove branches of size 1
  skeleton = removeSpurs(skeleton);

  % straighten zig-zags in spines
  skeleton = straightenSpines( skeleton);

  % remove corners that do not affect connectivity
  skeleton = removeCornersAndTs(skeleton);

  % remove padding
  skeleton = skeleton(3:end-2, 3:end-2);
    
%--------------------------------------------------------------------------
% straightenSpines
% Input: spines - binary skeletonized image
% Output: spines - same image with zig-zags removed when it does not affect
% connectivity
%--------------------------------------------------------------------------
  function [ spines ] = straightenSpines( spines )
    shiftLeft = [1 0 0; 0 1 0; 1 0 0];
    shiftUp = [1 0 1; 0 1 0; 0 0 0];
    shiftRight = [ 0 0 1; 0 1 0; 0 0 1];
    shiftDown = [0 0 0; 0 1 0; 1 0 1];

    [numRows, numCols] = size(spines);

    for i = 2:numCols-1
      tempArray = spines(:, i-1:i+1);
      for j = 2:numRows-1
        subimage = tempArray(j-1:j+1, :);
        if isequal(subimage, shiftLeft)
          subimage(2) = 1;
          subimage(5) = 0;
          tempArray(j-1:j+1, :) = subimage;
        elseif isequal(subimage, shiftUp)
          subimage(4) = 1;
          subimage(5) = 0;
          tempArray(j-1:j+1, :) = subimage;
        elseif isequal(subimage, shiftRight)
          subimage(8) = 1;
          subimage(5) = 0;
          tempArray(j-1:j+1, :) = subimage;
        elseif isequal(subimage, shiftDown)
          subimage(6) = 1;
          subimage(5) = 0;
          tempArray(j-1:j+1, :) = subimage;
        end
      end
      spines(:, i-1:i+1) = tempArray;
    end
  end

%--------------------------------------------------------------------------
% removeCornersAndTs
% Input: spines - binary skeletonized image
% Output: spines - same image with corner points and t points removed that
% generate uncessary branch points
%--------------------------------------------------------------------------
  function [ spines ] = removeCornersAndTs (spines)
    % middle index of subimage
    mid = 13;

    % masks of possible corner positions
    cornerLRV = [0 0 0; 1 1 0; 0 1 0; 0 1 0];
    cornerURV = flip(cornerLRV);
    cornerULV = fliplr(cornerURV);
    cornerLLV = flip(cornerULV);
    cornerURH = [0 0 1 0; 1 1 1 0; 0 0 0 0];
    cornerLRH = flip(cornerURH);
    cornerLLH = fliplr(cornerLRH);
    cornerULH = fliplr(cornerURH);
    % masks for possible T-intersection positions
    t1 = [0 1 0; 1 1 1; 0 0 0];
    t2 = [0 1 0; 0 1 1; 0 1 0];
    t3 = [0 0 0; 1 1 1; 0 1 0];
    t4 = [0 1 0; 1 1 0; 0 1 0];

    % find all points in the spine
    [f, t] = find(spines == 1);


    % for each point, determine if it is a corner. If it is a corner,
    % remove it from the spine
    for i = 1:numel(f)
      subimage = spines(f(i)-2:f(i)+2, t(i)-2:t(i)+2);

      if isequal(subimage(2:5, 2:4), cornerLRV)
        subimage(mid) = 0;
      elseif isequal(subimage(1:4, 2:4), cornerURV)
        subimage(mid) = 0;
      elseif isequal(subimage(1:4, 2:4), cornerULV)
        subimage(mid) = 0;
      elseif isequal(subimage(2:5, 2:4), cornerLLV)
        subimage(mid) = 0;
      elseif isequal(subimage(2:4, 1:4), cornerURH)
        subimage(mid) = 0;
      elseif isequal(subimage(2:4, 1:4), cornerLRH)
        subimage(mid) = 0;
      elseif isequal(subimage(2:4, 2:5), cornerLLH)
        subimage(mid) = 0;
      elseif isequal(subimage(2:4, 2:5), cornerULH)
        subimage(mid) = 0;
      elseif isequal(subimage(2:4, 2:4), t1)
        subimage(mid) = 0;
      elseif isequal(subimage(2:4, 2:4), t2)
        subimage(mid) = 0;
      elseif isequal(subimage(2:4, 2:4), t3)
        subimage(mid) = 0;
      elseif isequal(subimage(2:4, 2:4), t4)
        subimage(mid) = 0;
      end

      spines(f(i), t(i)) = subimage(mid);
    end
  end

%--------------------------------------------------------------------------
% removeSpurs
% Inputs: spines - binary skeletonized image
% Outputs: spines - same image with branches of lenght 1 that generate
% unnecessary branch boints
%--------------------------------------------------------------------------
  function [ spines ] = removeSpurs(spines)
    % find branchpoints
    bpoints = bwmorph(spines, 'branchpoints');
    [fb, tb] = find(bpoints == 1);

    % find spurs
    spurs = bwmorph(spines, 'spur');
    spurs = spines - spurs;
    spurs = find(spurs == 1);
    [fs, ts] = ind2sub(size(spines), spurs);

    % calculate distance between each branch point and spur
    distSpurBpoint = sqrt( (fs' - fb) .^ 2 + (ts' - tb) .^ 2);

    % determine if there is a branchpoint - spur combination with a
    % distance less than 1.5 in each column. 1.5 is large enough to account
    % for two diagonal pixels.
    isValidSpur = logical(sum(distSpurBpoint < 1.5));

    % identify spurs to be removed
    spurs = spurs(isValidSpur);
    spines(spurs) = 0;    
  end
end


%--------------------------------------------------------------------------
% Identify Segments
% Input: spines
% Output: segmentLabels - matrix with each segment identified by a number
%       numSegments - total number of segments identified
%       ePoints - binary matrix with location of all end points marked 1
%       bPoints - binary matrix with location of all branch points marked 1
% Finds all the segments making up spines
%--------------------------------------------------------------------------
function [segmentLabels, numSegments, bpoints, epoints] = identifySegments(spines)
  % Identify end points and branch points. An extra point can be paired
  % with the branch point when necessary to fully disconnect segments.
  spines = padarray(spines, [1, 1], 0, 'both');
  bpoints = bwmorph(spines, 'branchpoints');
  epoints = zeros(size(spines));

  [fs, ts] = find(spines == 1);

  % extra points to fully disconnect spines
  fx = zeros(10, 1);
  tx = fx;
  % saves branch point associated with the extra point as an ordered pair
  % (t, f)
  newBpointPair = zeros(10,2);
  numNewBpoints = 0;

  for i = 1:numel(ts)
    f = fs(i);t = ts(i);
    subimage = spines(f-1:f+1, t-1:t+1);
    % if the current point is an end point, the subimage will
    % contain only two pixels
    if sum(subimage(:)) == 2
        epoints(f, t) = 1;

    % if the current point is a branch point, check if it fully
    % disconnects the adjacent segments
    elseif bpoints(f, t) == 1
      subimage(5) = 0;
      [spineLabels, numCC] = bwlabel(subimage);
      % iterate through each label and remove a point if there is
      % more than 1 associated with that label
      for j = 1:numCC
        if nnz(spineLabels == j) > 1
            [fnew, tnew] = find(spineLabels == j, 1, 'first');
            % increment number of new branch points and add new
            % branch point to list of extra branch points
            numNewBpoints = numNewBpoints + 1;
            fx(numNewBpoints) = f + fnew - 2;
            tx(numNewBpoints) = t + tnew - 2;
            newBpointPair(numNewBpoints, :) = [t, f];
        end
      end
    end
  end
    
  tx = tx(1:numNewBpoints);
  fx = fx(1:numNewBpoints);

  newBpoints = zeros(size(spines));
  newBpoints(sub2ind(size(spines), fx, tx)) = 1;

  segments = spines & ~bpoints;
  segments = segments & ~newBpoints;
  [segmentLabels, numSegments] = bwlabel(segments);

  % add the extra branch points back and include them in the closest
  % segment
  [fs, ts] = find(segmentLabels > 0);
  [~, ind] = min(sqrt((fs - fx') .^ 2 + (ts - tx') .^ 2));
  for j = 1:numel(ind)
    tempLabel = segmentLabels(fs(ind(j)), ts(ind(j)));
    segmentLabels(fx(j), tx(j)) = tempLabel;
  end
  
  segmentLabels = segmentLabels(2:end-1, 2:end-1);
  bpoints = bpoints(2:end-1, 2:end-1);
  epoints = epoints(2:end-1, 2:end-1);
end


%--------------------------------------------------------------------------
% Classify Branch Points
% Input: segmentLabels - matrix with each segment identified by a number
%       ePoints - binary matrix with location of all end points marked 1
%       bPoints - binary matrix with location of all branch points marked 1
% Output: bpointInfo - see below
% For each branch point determine the following:
% (1) Adjacent branches
% (2) True/False does adjacent branch have an endpoint
% saved in the matrix configuration 
% [adjacent branches, has endpoint, branch point number]
%--------------------------------------------------------------------------
function bpointInfo = classifyBpoints( segmentLabels, bpoints, epoints )
  % locate each branch point
  [fb, tb] = find(bpoints == 1);
  numBpoints = numel(fb);

  % identify which segments have an endpoint
  epointLabels = unique(epoints .* segmentLabels);
  epointLabels(epointLabels == 0) = [];

  % preallocate array for bpointInfo
  bpointInfo = zeros(3, 2, numBpoints);

  % create bpointInfo matrix
  size(fb)
  size(tb)
  for i = 1:numBpoints
    i
    labels = segmentLabels(fb(i) - 1:fb(i) + 1, tb(i) - 1:tb(i) + 1);
    labels = unique(labels(labels > 0))';
    hasEpoint = ismember(labels, epointLabels);
    bpointInfo(1:numel(labels), :, i) = [labels; hasEpoint]';
  end
end


%--------------------------------------------------------------------------
%
% Input:
% Output:
% Identify spines from the skeleton image. 
%--------------------------------------------------------------------------
function [newSpines, numNewSpines] = identifySpines( skeleton, segmentLabels, numSegments, bpoints, bpointInfo )
  % get location of branch points
  [fb, tb] = find(bpoints == 1);

  % create visited arrays for keeping track of processed segments and
  % bpoints
  visitedSegments = false(numSegments, 1);
  visitedBpoints = false(numel(fb), 1);

  % keep track of spines that are valid
  numNewSpines = 0;
  newSpines = zeros(size(segmentLabels));
  % keep track of label reassignemnts
  newLabels = zeros(numSegments, 1);

  %----------------------------------------------------------------------

  % Begin by processing skeltons without branch points. Find these
  % segments
  % find each component in the skeleton
  [skelLabels, ~] = bwlabel(skeleton);
  skels = unique(skelLabels .* bpoints);
  skels(skels == 0) = [];
  skelLabels(ismember(skelLabels, skels)) = 0;
  noBpointLabels = unique(segmentLabels(skelLabels > 0 & segmentLabels > 0));
  % for each of these segments determine if the segment is of sufficient
  % size and inside desired range of angles. As each segment is
  % processed, mark it as visited
  for i = noBpointLabels'
    curSegment = segmentLabels == i;
    if nnz(curSegment) > 4
      % calculate the goodness of fit
      [rbarSquared, p] = calcAdjRsquared( curSegment );
      % determine angle of segment
      segmentAngle = abs(atand(p(1)));
      if segmentAngle < 85 && segmentAngle > 10 && rbarSquared > 0.5
        numNewSpines = numNewSpines + 1;
        newSpines(curSegment) = numNewSpines;
        % update label assignment
        newLabels(i) = numNewSpines;
      else
        newLabels(i) = NaN;
      end
    else
      newLabels(i) = NaN;
    end
    visitedSegments(i) = true;
  end
  
  %------------------------------------------------------------------------

  % Next find trunk segments. Trunk segments have 1 branch containg an
  % endpoint and the remaining segments end with another branch point.
  % Grow the spine from the trunk.

  % get all potential trunk points
  curBpoints = find((squeeze(sum(bpointInfo(:, 2, :))) == 1) == true);
  dist = sqrt( (fb(curBpoints)' - fb) .^ 2 + (tb(curBpoints)' - tb) .^ 2);
  closeBpoints = dist < 10 & dist > 0;

  for i = 1:numel(curBpoints)
    adjCurBpoint = squeeze(bpointInfo(:, 1, curBpoints(i)));
    adjCurBpoint = adjCurBpoint(adjCurBpoint > 0);
    adjSegments = squeeze(bpointInfo(:, 1, closeBpoints(:,i)));
    adjSegments = adjSegments(adjSegments > 0);
    connectedSegments = adjCurBpoint(ismember(adjCurBpoint, adjSegments));

    if numel(connectedSegments) == 2 && ~visitedBpoints(curBpoints(i))
      % create trunk
      spine = ismember(segmentLabels, connectedSegments);
      spine(fb(curBpoints(i)), tb(curBpoints(i))) = 1;
      % update segment labels
      numNewSpines = numNewSpines + 1;
      newLabels(connectedSegments) = numNewSpines;
      unconnectedSegments = adjCurBpoint(~ismember(adjCurBpoint, connectedSegments));
      newLabels(unconnectedSegments) = NaN;
      % mark adjacent segments as visited
      visitedSegments(adjCurBpoint) = true;
      % mark bpoint as visited
      visitedBpoints(curBpoints(i)) = true;

      % get connected branch points
      connectedBpoints = find((closeBpoints(:, i) & ~visitedBpoints) == 1);

      % as long as there are more connected branch points, add segments to
      % the trunk. 
      while ~isempty(connectedBpoints)
        % get the next point and remove it from the list
        newBpoint = connectedBpoints(1);
        % remove from the list
        connectedBpoints(1) = [];
        
        % find number of spurs (segments ending with end point)
        numSpurs = nnz(bpointInfo(:, 2, newBpoint));
        
        % if the branch point is a fork, do nothing
        if numSpurs ~= 0
          % add branchpoint to the spine
          spine(fb(newBpoint), tb(newBpoint)) = 1;
          % mark branch point as visited
          visitedBpoints(newBpoint) = true;
          
          % find unvisited segments
          adjSegments = squeeze(bpointInfo(:, 1, newBpoint));
          adjSegments = adjSegments(adjSegments > 0);
          newSegments = adjSegments(~visitedSegments(adjSegments));
          if ~isempty(newSegments)
            % try each combination of segments with the exisiting spine
            gof = zeros(numel(newSegments), 1);
            for j = 1:numel(newSegments)
              curSegment = segmentLabels == newSegments(j);
              testSpine = curSegment + spine;
              gof(j) = calcAdjRsquared(testSpine);
            end

            [~, maxGof] = max(gof);
            newSegment = newSegments(maxGof);
            % add selected segment to the spine
            spine(segmentLabels == newSegment) = 1;
            % update segment label
            newLabels(newSegment) = numNewSpines;
            unusedSegments = newSegments(~ismember(newSegments, newSegment));
            newLabels(unusedSegments) = -1;
            % if selected segment does not contain an endpoint, find the
            % branch point on the other end
            isSpur = bpointInfo(adjSegments == newSegment, 2, newBpoint);
            if ~isSpur
              connectedNewSegment =  squeeze(sum(ismember(bpointInfo(:, 1, :), newSegment)));
              nextBpoint = find(connectedNewSegment & ~visitedBpoints == 1);
              connectedBpoints = [connectedBpoints; nextBpoint];
            end

            visitedSegments(adjSegments) = true;
          end
        end
      end
      % increment number of new spines and save to new spines
      newSpines(spine) = numNewSpines;
    end
  end

  %------------------------------------------------------------------------
  
  % find the remaining unvisited branch points that are not a fork. For
  % each branch point, select two best fitting spines. When creating test
  % spine for fitting, check for visited branches. If the branch has been
  % visited, get the updated label and corresponding spine from new spines.
  % If the rejected branch ends in a branch point, do not mark it as visted
  % because it could be picked up by another branch point.
  curBpoints = find((squeeze(sum(bpointInfo(:, 2, :))) ~= 0) == true);
  curBpoints = curBpoints(~visitedBpoints(curBpoints));
  
  for i = curBpoints'
    % get info about current branch point
    curBpointInfo = bpointInfo(:, :, i);
    adjSegments = curBpointInfo(:, 1);
    adjSegments = adjSegments(adjSegments > 0);
    
    % mark branch point as visited
    visitedBpoints(i) = true;

    % find each combination of branches
    combos = combnk(adjSegments, 2);
    
    % preallocate for each combination
    segments = zeros(size(segmentLabels,1), ...
      size(segmentLabels,2), numel(adjSegments));

    % find goodness of fit for each combination
    gof = zeros(size(combos, 1), 1);
    for j = 1:numel(gof)
      % check if either segment has been included in a previous spine
      curLabels = combos(j, :);
      preVisited = visitedSegments(curLabels);

      if nnz(preVisited) > 0
        % get new label for previous visited segments and create spine from
        % both matricies
        visited = newLabels(curLabels(preVisited));
        notVisited = curLabels(~preVisited);
        segments(:, :, j) = ismember(segmentLabels, notVisited) + ...
          ismember(newSpines, visited);
        segments(fb(i), tb(i), j) = true;
      else
        % create spine for segment combination
        segments(:, :, j) = ismember(segmentLabels, curLabels);
        segments(fb(i), tb(i), j) = true;
      end
      gof(j) = calcAdjRsquared( segments(:, :, j) );
    end

    % pick combo with highest goodness of fit
    [~, maxGof] = max(gof);

    % increment number of new spines if no segment in the pair has been
    % used before
    if nnz(visitedSegments(combos(maxGof, :))) == 0
      numNewSpines = numNewSpines + 1;
      newSpines(segments(:, :, maxGof) == 1) = numNewSpines;
      newLabels(combos(maxGof, :)) = numNewSpines;
    else
      label = max(max(newSpines .* segments(:, :, maxGof)));
      newSpines(segments(:, :, maxGof) == 1) = label;
      newLabels(combos(maxGof, :)) = label;
    end

    unusedSegment = curBpointInfo(~ismember(adjSegments, combos(maxGof, :)), 1);
    isSpur = curBpointInfo(~ismember(adjSegments, combos(maxGof, :)), 2);
    visitedSegments(adjSegments) = true;

    % if unused segment is not a spur, mark it as unvisited otherwise
    % change its label
    if ~isSpur
      visitedSegments(unusedSegment) = false;
    else
      newLabels(unusedSegment) = NaN;
    end
  end

  %------------------------------------------------------------------------
  % Final step is to decide if bridge segments will be used. ?????????????
  curBpoints = find(visitedBpoints == 0);
    
  for i = curBpoints'
    curBpointInfo = bpointInfo(:, :, i);
    adjSegments = curBpointInfo(:, 1);
    adjSegments = adjSegments(adjSegments > 0);
    % mark branch point as visited
    visitedBpoints(i) = true;
      
    % find each combination of branches
    if ~isempty(adjSegments)
      combos = combnk(adjSegments, 2);
    end
      
    % preallocate for each combination
    segments = zeros(size(segmentLabels,1), ...
      size(segmentLabels,2), numel(adjSegments));

    % find goodness of fit for each combination
    gof = zeros(size(combos, 1), 1);
    for j = 1:numel(gof)
      % check if either segment has been included in a previous spine
      curLabels = combos(j, :);
      preVisited = visitedSegments(curLabels);
      if nnz(preVisited) > 0
        % get new label for previous visited segments and create spine from
        % both matricies
        visited = newLabels(curLabels(preVisited));
        notVisited = curLabels(~preVisited);
        segments(:, :, j) = ismember(segmentLabels, notVisited) + ...
          ismember(newSpines, visited);
        segments(fb(i), tb(i), j) = true;
      else
        % create spine for segment combination
        segments(:, :, j) = ismember(segmentLabels, curLabels);
        segments(fb(i), tb(i), j) = true;
      end
      gof(j) = calcAdjRsquared( segments(:, :, j) );
    end
    
    % pick combo with highest goodness of fit
    [~, maxGof] = max(gof);
 
    % increment number of new spines if no segment in the pair has been
    % used before
    if nnz(visitedSegments(combos(maxGof, :))) == 0
      numNewSpines = numNewSpines + 1;
      newSpines(segments(:, :, maxGof) == 1) = numNewSpines;
      newLabels(combos(maxGof, :)) = numNewSpines;
    else
      label = max(max(newSpines .* segments(:, :, maxGof)));
      newSpines(segments(:, :, maxGof) == 1) = label;
      newLabels(combos(maxGof, :)) = label;
    end

    unusedSegment = curBpointInfo(~ismember(adjSegments, combos(maxGof, :)), 1);
    visitedSegments(adjSegments) = true;
    newLabels(unusedSegment) = NaN;
  
  end

    
%--------------------------------------------------------------------------
% calcAdjRsquared
% Input: spine - binary matrix
% Output: gof - adjusted r squared value
%       p - polynomial describing line of best fit
%--------------------------------------------------------------------------
  function [rbarSquared, p] = calcAdjRsquared( spine )
    [fs, ts] = find(spine == 1);
    p = polyfit(ts, fs, 1);
    fbar = mean(fs);
    fp = polyval(p, ts);
    ssTot = sum((fs - fbar) .^ 2);
    ssRes = sum((fs-fp) .^ 2);
    rsquared = 1 - (ssRes / ssTot);
    rbarSquared = 1 - (1 - rsquared) * ( (numel(fs) - 1) / (numel(fs) - 2));
  end
end