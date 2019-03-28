function [ skel, dist, skelLabels, spines, sweeprates, chorusAngles ] = findSpines( ridges, mu, tspec, fspec )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
    
  % find the mask of thresholded distancce transform applied to ridge features
  [skel, dist] = createSpineMask(ridges);

  % find peaks in each column of ridges  after applying bwDist mask
%   findSpinePeaks(skel, dist);
 
  % find the spine through each chorus such that there are no branch points
  [skelLabels, numSpineLabels, sweeprates, chorusAngles] = identifySpines( skel, dist, mu, tspec, fspec);

  spines = zeros(size(skelLabels));
  spines(skelLabels > 0) = 1;
end

%--------------------------------------------------------------------------
% createSpineMask
% Input: ridges - ridge features from SNR map
% Output: skel - binary mask of thresholded distance transform with
% thinning and cleaning operations applied
%         dist - distance transform of ridges features
%         dist2 - thresholded distance transform
% Extracts the domint ridges along the gradient using the distance
% transform and applying a threshold
%--------------------------------------------------------------------------
function [skel, dist] = createSpineMask( ridges )
  % create binary version of ridge features
  ridges = ridges - min(ridges(:));
  bwRidges = ridges;
  bwRidges(bwRidges > min(ridges(:))) = 1;
  bwRidges(bwRidges ~= 1) = 0;
  bwRidges = bwmorph(bwRidges, 'fill');
  
  % calculate distance transform
  dist = bwdist(~bwRidges);
  dist(dist == 0) = NaN;
  
  % create binary image from distance transform 
  skel = dist;
  skel(~isnan(skel)) = 1;
  skel(isnan(skel)) = 0;
  
  % thin and clean thresholded distance transform
  skel = bwmorph(skel, 'close');
  skel = bwmorph(skel, 'open');
  skel = bwmorph(skel, 'thin', Inf);  
  skel = bwmorph(skel, 'clean');
  
  skel = skel .* dist;
  skel(isnan(skel)) = 0;
  skel(skel ~= 0) = 1;
end


%--------------------------------------------------------------------------
% findSpinePeaks
% Input:  bwDist - mask of thresholded distance transform
%         ridges - ridge features from SNR map
% Output: bwPeaks - binary mask of the columnwise max values
%         peaks - columnwise max values with their associated psd          
% Multiplies ridges the bwDist and finds columnwise peaks with the result
%--------------------------------------------------------------------------
function [ peaks, bwPeaks ] = findSpinePeaks(skel, dist)
  spines = dist .* skel;
  bwPeaks = zeros(size(dist));
  
  for i = 1:size(dist, 2)
    [~, locs] = findpeaks(spines(:, i));
    if ~isempty(locs)
      bwPeaks(locs, i) = 1;
    end
  end
  
  peaks = dist .* bwPeaks;
  figure;i1=subplot(1,1,1);imagesc(bwPeaks);colormap gray;set(i1,'ydir','normal');pause;
end


%--------------------------------------------------------------------------
% identifySpines
% Input:  bwPeaks - mask of columnwise max points
%         skel - mask of thresholded distance transform after performing
%         thinning and cleaning
% Output:
% Groups the peaks found into their associated chrous spines and rejects
% those that do not meet specified criteria
%--------------------------------------------------------------------------
function [spineLabels, numSpineLabels, sweeprates, chorusAngles] = identifySpines( skel, dist, mu, tspec, fspec )
  % initalize spine labels to a 0 valued array. the selected paths through
  % each spine will be saved to spine labels as they are found
  spineLabels = zeros(size(skel));
  numSpineLabels = 0;
  chorusAngles = [];
  sweeprates = [];
  % created connected component labels for the peaks
  [skelLabels, numLabels] = bwlabel(skel);
  
  % remove spines that are too small 
  [labelIds, skelLabels] = removeSpines(numLabels, skelLabels);
  
  % find branch points based on Matlab's branch points and an approximation
  % of those that were removed from peaks calculation  
  % find branch points from thinned image
  bpoints = bwmorph(skel, 'branchpoints');
  
%   bpointsNew = findBranchPoints(peakLabels, labels, labelIds, bpoints);

  for i = labelIds
    skelLabelMask = (skelLabels == i);
    localBpoints = skelLabelMask .* bpoints;
    numBpoints = sum(localBpoints(:));  
    [fb, tb] = find(localBpoints == 1);
    
    % if the spine contains one or more branch points, find all valid paths
    % to be saved through the spine. if there is no branch point, save the
    % spine
    if numBpoints > 0 
      % find the segments making up the spine
      [skelLabelIds, numSegments, removedPoints] = findSegments(skelLabelMask, localBpoints, numBpoints, fb, tb);
      
      % create the adjacency matrix of the segments
      [adjMatrix, bpointLabels, numBpointLabels, edges] = createAdjMatrix(skelLabelIds, numSegments, removedPoints, localBpoints, fb, tb);
      
      % find all paths through the spine
      [paths, numPaths] = findPaths(adjMatrix, numBpointLabels);
      
      % get average distance transform values and quality of fit measure for each path
      [paths, pathInfo, numPaths, pathMasks] = getPathInfo(paths, numPaths, skelLabelIds, numBpointLabels, bpointLabels, adjMatrix, dist, mu, tspec, fspec);
      
      % remove invalid paths. an invalid path must meet one of the
      % following criteria: (1) not enough data points, (2) poor measure of
      % fit
      [paths, pathInfo, numPaths, pathMasks] = removeInvalidPaths(paths, pathInfo, numPaths, pathMasks, adjMatrix, edges);

%       selectedPathIndex = 1; % initialize to 1 to enter while loop
      while numPaths > 0 %&& selectedPathIndex > 0
        % select best path through the spine
        selectedPathIndex = selectPath(paths, numPaths, pathInfo, numBpointLabels);

        % after finding a path, do the following
        % (1) save the path to spine labels
        % (2) save the chorus angle and sweeprate for this path
        % (3) if this path contains a branch point, remove all paths that
        % also pass through this point, including this path
        % (4) update the path list, path info, path masks to only contain
        % the remaining potential paths
        % (5) update the number of remaining paths
        numSpineLabels = numSpineLabels + 1;
        spineLabels(squeeze(pathMasks(selectedPathIndex, :, :)) == 1) = numSpineLabels;
        chorusAngles = [chorusAngles, pathInfo(selectedPathIndex, 3)];
        sweeprates = [sweeprates, pathInfo(selectedPathIndex, 4)];
        
        isBpoint = paths(selectedPathIndex, :) <= numBpointLabels& paths(selectedPathIndex, : ) > 0;
        pathBpoints = paths(selectedPathIndex, isBpoint);
        containsPathBpoints = sum(ismember(paths, pathBpoints), 2) > 0;
        paths(containsPathBpoints, :) = [];
        pathInfo(containsPathBpoints, :) = [];
        pathMasks(containsPathBpoints, :) = [];
        numPaths = numPaths - sum(containsPathBpoints);
%         figure;pcolor(spineLabels);colormap colorcube;shading flat;
%         pause;close
      end 
%       close
    else
      [f, t] = find(skelLabelMask == 1);
      [sweeprate, chorusAngle, ~, ~, ~, ~, ~, ~, ~, ~] = piecewise_regression(tspec(t)', fspec(f), mu);
      if max(t) - min(t) < 100 && abs(chorusAngle) > 15 && abs(chorusAngle) < 85
        numSpineLabels = numSpineLabels + 1;
        spineLabels(skelLabelMask == 1) = numSpineLabels;
        chorusAngles = [chorusAngles, chorusAngle];
        sweeprates = [sweeprates, sweeprate];
      end
    end
  end
  chorusAngles
  sweeprates
  
end
    
%--------------------------------------------------------------------------
% removeSpines
% Inputs: numLabels - the number of connected components found after
%         cleaning
%         peakLabels - matrix of peak locations where values are connected
%         component labels
%         bwPeaks - mask of max peaks
% Outputs:
% Removes spines found that are only one pixel wide or do
% not meet a frequency span criteria. This is done before spines are
% processed
%--------------------------------------------------------------------------
function [labelIds, peakLabels] = removeSpines(numLabels, peakLabels)
  removedLabels = false(numLabels, 1);
  for i = 1:numLabels
    peakLabelMask = (peakLabels == i);
    [fPeaks, tPeaks] = find( peakLabelMask == 1);
    if isempty(tPeaks) || numel(unique(tPeaks)) == 1 || max(fPeaks) - min(fPeaks) < 5 || max(tPeaks) - min(tPeaks) > 99
      peakLabels(peakLabels == i) = 0;
      removedLabels(i) = true;
    end
  end
  labelIds = 1:numLabels;
  labelIds = labelIds(~removedLabels);
end

%--------------------------------------------------------------------------
% findBranchPoints
% Inputs:
% Outputs:
%
%--------------------------------------------------------------------------
% function [bpointsNew] = findBranchPoints(peakLabels, labels, labelIds, bpoints)    
%   for i = labelIds
%     peakLabelMask = (peakLabels == i);
%     skelLabelMask = (labels == i);
%     bpointsNew = bpoints;
%     % find local branch points in the skeleton and peaks. If the number of
%     % branch points are equal, all local branch points were reatained. If
%     % not find an approximation of the brnach point.
%     localBpoints = bpoints .* skelLabelMask;
%     existingBpoints = bpoints .* peakLabelMask;
%     numLocalBpoints = sum(localBpoints(:));
%     numExistingBpoints = sum(existingBpoints(:));
%     
%     % if a branch point has been removed, find an approximation as a
%     % replacement
%     if numLocalBpoints ~= numExistingBpoints
%       [fb, tb] = find(localBpoints == 1);
%       [f, t] = find(peakLabelMask == 1);
%       dist = zeros(numel(f), numel(fb));
%       for j = 1:numel(f)
%         for k = 1:numel(fb)
%           dist(j, k) = sqrt((f(j)-fb(k))^2 + (t(j)-tb(k))^2);
%         end
%       end
%       [m, ind] = min(dist);
%       
%       % if minimum distance is zero, the branch point still remains, if not
%       % replace with an adjacent point
%       for j = 1:numel(m)
%         if m(j) == 1
%           bpointsNew(fb(j), tb(j)) = 0;
%           bpointsNew(f(ind(j)), t(ind(j))) = 1;
%         end
%       end
%     end
%   end
% end
  
 
%--------------------------------------------------------------------------
% findSegments
%
%
%--------------------------------------------------------------------------
function [skelLabelIds, numSegments, removedPoints] = findSegments(skelLabelMask, localBpoints, numBpoints, fb, tb)
  skelLabelMask = skelLabelMask - localBpoints;
  [segmentIds, numSegments] = bwlabel(skelLabelMask);

  % check to see if connectivity was preserved even after removing
  % branch points. in cases where this happens an additional point will
  % need to be removed.
  removedPoints = nan(numBpoints, 2);
  
  % to check if connectivity is preserved, look at 3x3 window around
  % each branch point. if each point in the window does not have a
  % unique label, connectivity is preserverd and another point must be
  % removed.
  for j = 1:numBpoints
    % create window around branch point
    subimageMask = skelLabelMask(fb(j)-1:fb(j)+1, tb(j)-1:tb(j)+1);
    subimageIds = segmentIds(fb(j)-1:fb(j)+1, tb(j)-1:tb(j)+1) .* subimageMask;

    if sum(subimageMask(:)) ~= numel(unique(subimageIds)) - 1
      % if the sum each column is 1, removing the middle pixel
      % always changes the connnectivity
      if sum(subimageMask) == [1 1 1]
        % find coordinate in subimage of the point in the middle
        % column, this point will be removed
        [ind, ~] = find(subimageMask(:, 2) == 1);
        if ind == 3
          removedPoints(j,:) = [fb(j)+1, tb(j)];
          skelLabelMask(fb(j)+1, tb(j)) = 0;
        elseif ind == 1
          removedPoints(j,:) = [fb(j)-1, tb(j)];
          skelLabelMask(fb(j)-1, tb(j)) = 0;
        end
         [segmentIds, numSegments] = bwlabel(skelLabelMask);
      end
    end
  end
  
  % create labeled matricies
  % add one to the number of segments, this acts as a placeholder for the
  % branch points
  numSegments = numSegments + 1;
  % add the removed points back in, assigning the id of the closest
  % connected point
  for j = 1:size(removedPoints,1)
    if ~isnan(removedPoints(j,1))
      % create subimage around the point
      subimage = segmentIds(removedPoints(j,1)-1:removedPoints(j,1)+1, removedPoints(j,2)-1:removedPoints(j,2)+1);
      % find the closest non-zero point from the middle (2,2)
      [y,x] = find(subimage ~= 0);
      dist = sqrt( (2-y).^2 + (2-x).^2);
      [~, ind] = min(dist);
      % get the label of the closest point
      label = subimage(y(ind), x(ind));
      % assign the removed point this label
      segmentIds(removedPoints(j,1), removedPoints(j,2)) = label;
    end
  end
  
  % add the branch points back into the labels, assigning them a new label
  % equal to one higher than the number of segments founds
  skelLabelIds = segmentIds + (localBpoints * numSegments);
end

%--------------------------------------------------------------------------
% createAdjMatrix
%
%
%
%--------------------------------------------------------------------------
function [adjMatrix, bpointLabels, numBpointLabels, edges] = createAdjMatrix(skelLabelIds, numSegments, removedPoints, localBpoints, fb, tb)  
  % initalize the adjacency matrix with size n one less than the number of
  % segments passed as the last segment is a place holder for branch points
  
  % create a matrix that stores the segments adjacent to each branch point
  adjSegmentsMatrix = zeros(numel(fb), numSegments - 1);
  
  for i = 1:numel(fb)
    adjSegments = unique(skelLabelIds(fb(i)-1:fb(i)+1, tb(i)-1:tb(i)+1));
    adjSegments(adjSegments == numSegments | adjSegments == 0) = [];
    adjSegmentsMatrix(i, adjSegments) = 1;
  end
  
  % iterate through the points that were removed when breaking connectivity
  % to find if any adjacent segments were missed. this completes the
  % adjacency information for each bpoint
  for i = 1:size(removedPoints,1)
    if ~isnan(removedPoints(i,1))
      adjSegments = unique(skelLabelIds(removedPoints(i,1)-1:removedPoints(i,1)+1, removedPoints(i,2)-1:removedPoints(i,2)+1));
      adjSegments(adjSegments == numSegments | adjSegments == 0) = [];
      adjSegmentsMatrix(i, adjSegments) = 1;
    end
  end
  
  % find clusters of bpoints. when two or more branch points are connected,
  % the shared segment must be traversed when it is not necessary
  [bpointLabels, numBpointLabels] = bwlabel(localBpoints);
  
  % create the adjacency matrix from the connectivity information. this
  % will be done by creating an edge list with the following structure
  % [node 1, node 2, segment id, angle]
  % to create the edge list, begin by iterating through the branch points
  % labels and the associated branch points, defining an edge for each 
  % adjacent segment. node 1 up to the number of branch points will always 
  % be in refecernce to the branch point. if an edge is found to be previously
  % defined, this indicates it is connected to a segment with two branch
  % points. in this case a new edge is not defined but node 2 of the
  % previous edge will be updated to the current branch point being
  % iterated over
  edges = zeros(numSegments - 1, 4);
  numNodes = numBpointLabels + 1;
  visitedSegment = false(numSegments - 1, 1);  %keeps track of defined edges
  
  for i = 1:numBpointLabels
    % find the index in fb and tb of the corresponding branch points
    [fbl, tbl] = find(bpointLabels == i);
    bpointInd = ismember(fb, fbl) == 1 & ismember(tb, tbl) == 1;
    % get the segments adjacent to this cluster
    [~, curSegments] = find(adjSegmentsMatrix(bpointInd, :) > 0);
    curSegments = unique(curSegments);
    
    % iterate over each segment to create an edge
    for j = 1:numel(curSegments)
      if ~visitedSegment(curSegments(j))
        edges(curSegments(j), 1:3) = [i, numNodes, curSegments(j)];
        % calculate the angle of inclination of the edge
        edgeMask = skelLabelIds == curSegments(j);
        [~, edgeFit1] = calcAdjRsquared(edgeMask, 1);
        edges(curSegments(j), 4) = atand(edgeFit1(1));
        numNodes = numNodes + 1;
        visitedSegment(curSegments(j)) = true;
      else
        numNodes = numNodes - 1; %remove increment since there is no new node
        prevNodeId = edges(curSegments(j),2);
        edges(curSegments(j), 2) = i;
        % decrement nodes that were at a higher index than the one removed
        nodesToUpdate = find(edges(:, 2) > prevNodeId);
        edges(nodesToUpdate, 2) = edges(nodesToUpdate, 2) - 1;
      end
    end
  end
  % create adjacency matrix from the edge list, entries in the matrix are
  % either 0 for non-connected nodes or the valued of the segment id for
  % connected nodes
  adjMatrix = zeros(numSegments - 1);
  for i = 1:numSegments - 1
    adjMatrix(edges(i,1), edges(i,2)) = edges(i,3);
    adjMatrix(edges(i,2), edges(i,1)) = edges(i,3);
  end
end

%--------------------------------------------------------------------------
% modeled after this code: 
% https://www.geeksforgeeks.org/find-paths-given-source-destination/
%--------------------------------------------------------------------------
function [allPaths, totalPaths] = findPaths(adjMatrix, numBpoints)
  totalPaths = 0;
  allPaths = [];
  completed = false(size(adjMatrix,1), 1);
  for m = 1:size(adjMatrix,1)
    visited = false(size(adjMatrix,1),1);
    path = [];
    pathIndex = 1;
    nodePaths = zeros([1, size(adjMatrix,1)]);
    nodePathCount = 0;
    [nodePaths, nodePathCount] = findPathsHelper(adjMatrix, m, visited, path, pathIndex, nodePaths, nodePathCount, completed, numBpoints);
    if nodePathCount > 0
      allPaths = [allPaths; zeros(nodePathCount, size(adjMatrix,1))];
      allPaths(totalPaths + 1:totalPaths + nodePathCount, :) = nodePaths;
      totalPaths = totalPaths + nodePathCount;
    end
    if m > numBpoints
      completed(m) = true;
    end
  end
end
  
%--------------------------------------------------------------------------
%
%
%
%--------------------------------------------------------------------------
function [nodePaths, nodePathCount] = findPathsHelper(adjMatrix, startNode, visited, path, pathIndex, nodePaths, nodePathCount, completed, numBpoints)
  visited(startNode) = true;
  path(pathIndex) = startNode;
  pathIndex = pathIndex + 1;

  % find adj nodes
  adjNodes = find(adjMatrix(startNode, :) > 0);

  % if all adjacent nodes have been visited, all paths from starting node
  % have been found
  if sum(visited(adjNodes) == false) == 0      
%     if sum(path <= numBpoints) >= 2 || numBpoints == 1
      nodePathCount = nodePathCount + 1;
      pathIndex = pathIndex - 1;
      nodePaths(nodePathCount, 1:pathIndex) = path;
%     end
  end

  % call recursive function for each of startNodes neighbors.
  for k = adjNodes
    if ~visited(k) && ~completed(k)
      [nodePaths, nodePathCount] = findPathsHelper(adjMatrix, k, visited, path, pathIndex, nodePaths, nodePathCount, completed, numBpoints);
    end
  end

  % remove current vertex from path and mark it unvisited
  pathIndex = pathIndex - 1;
  visited(startNode) = false;
end
   
%--------------------------------------------------------------------------
% getPathInfo
%
%
%
%--------------------------------------------------------------------------
% path info: [average distance transform values, measure of fit, angle, sweeprate]
function [paths, pathInfo, numPaths, pathMasks] = getPathInfo(paths, numPaths, skelLabelIds, numBpointLabels, bpointLabels, adjMatrix, dist, mu, tspec, fspec)
  pathInfo = zeros(numPaths, 3);
  pathMasks = zeros(numPaths, size(skelLabelIds, 1), size(skelLabelIds,2));

  for j = 1:numPaths
    nodes = paths(j, :);
    nodes = nodes(nodes > 0);
    pathMask = zeros(size(skelLabelIds));
    % find the bpoints in the path and add to mask
    pathBpointLabels = nodes(ismember(nodes, 1:numBpointLabels) == 1);
    
    for k = 1:numel(pathBpointLabels)
      pathMask(bpointLabels == pathBpointLabels(k)) = 1;
    end
    
    for k = 1:numel(nodes) - 1
      % get the segment id from the adjacency matrix
      segment = adjMatrix(nodes(k), nodes(k + 1));
      pathMask(skelLabelIds == segment) = 1;
    end

    pathMasks(j, :, :) = pathMask;
    % average distance transform values
    pathDist = pathMask .* dist;
    pathDist = pathDist(:);
    pathDist(isnan(pathDist)) = [];
    pathDist(pathDist == 0) = [];
    pathInfo(j, 1) = mean(pathDist);
    % measure of fit
    rbar = calcAdjRsquared(pathMask, 3);
    if rbar < -100
      rbar = -inf;
    end
    pathInfo(j, 2) = rbar;
%     [~, pathFit1] = calcAdjRsquared(pathMask, 1);
%     pathAngle = atand(pathFit1(1));
%     pathInfo(j, 3) = pathAngle;
    [f, t] = find(pathMask == 1);
    [sweeprate, chorusAngle, ~, ~, ~, ~, ~, ~, ~, ~] = piecewise_regression(tspec(t)', fspec(f), mu);
    pathInfo(j, 3:4) = [chorusAngle, sweeprate];
  end
end

%--------------------------------------------------------------------------
% calcAdjRsquared
% Input: spine - binary matrix
% Output: gof - adjusted r squared value
%       p - polynomial describing line of best fit
%--------------------------------------------------------------------------
function [rbarSquared, p] = calcAdjRsquared( spine, degree )
  [fs, ts] = find(spine == 1);
  p = polyfit(ts, fs, degree);
  fbar = mean(fs);
  fp = polyval(p, ts);
  ssTot = sum((fs - fbar) .^ 2);
  ssRes = sum((fs-fp) .^ 2);
  rsquared = 1 - (ssRes / ssTot);
  rbarSquared = 1 - (1 - rsquared) * ( (numel(fs) - 1) / (numel(fs) - 2));
end

%--------------------------------------------------------------------------
% removeInvalidPaths
%
% A path is invalid if it meets one of the following critera (1) not enough
% data points, (2) poor measure of fit, (3) the points do not span a large
% enough distance in time or frequency, (4) the angle of the path, 
% approximated by a 1st degree fit, is less than 10 degrees. a shallower
% angle is used since the 1st degree fit can depress the value. (5) the 
% path includes large differences in angles between segments (6) The path
% spans 100 or more points in time. this limitation is imposed by the
% structure of the cdf file
%--------------------------------------------------------------------------
function [paths, pathInfo, numPaths, pathMasks] = removeInvalidPaths(paths, pathInfo, numPaths, pathMasks, adjMatrix, edges)
  % remove paths that have a negative measure of fit. this indicates that
  % overfitting has occured. for a polynomial fit of degree 3, this
  % indicates less than 4 points
  % remove paths that have a measure of fit less than .80
  invalidPaths = false(numPaths, 1); %#ok<PREALL>
  invalidPaths = pathInfo(:, 2) < .80;
  % paths that have a frequency differance less than 5 or are only 1 pixel
  % wide are removed or have an approximate angle less than 15 degrees or
  % greater than 85
  for i = 1:numPaths
    if ~invalidPaths(i)
      if abs(pathInfo(i, 3)) < 15 || abs(pathInfo(i, 3)) > 85
        invalidPaths(i) = true;
      else
        pathMask = squeeze(pathMasks(i, :, :));
        [f, t] = find(pathMask == 1);
        if numel(unique(t)) == 1 || max(f) - min(f) < 5 || max(t) - min(t) > 99
          invalidPaths(i) = true;
        end
      end
    end
  end
  
  % paths with large angle difference are removed
  for i = 1:numPaths
    if ~invalidPaths(i)
      nodes = paths(i, :);
      nodes = nodes(nodes > 0);
      segments = zeros(numel(nodes) - 1, 1);
      % get a list of the segments traversed in the path
      for j = 1:numel(nodes) - 1
        segments(j) = adjMatrix(nodes(j), nodes(j+1));
      end
      % compare the angle from one segment to the next. if the difference
      % is too large, mark the path is invalid
      segmentIndex = 1;
      while ~invalidPaths(i) && segmentIndex < numel(segments)
        % 90 degrees can be recorded as positive or negative. in this event
        % set both angles to their absolute value so that a case such as
        % -85 and 90 degrees is not rejected
        angle1 = edges(segments(segmentIndex), 4);
        angle2 = edges(segments(segmentIndex + 1), 4);
        if abs(angle1) == 90 || abs(angle2) == 90
          angle1 = abs(angle1);
          angle2 = abs(angle2);
        end
        
        if abs(angle1 - angle2) > 45
          invalidPaths(i) = true;
        end
        segmentIndex = segmentIndex + 1;
      end
    end
  end
  
  paths = paths(~invalidPaths, :);
  pathInfo = pathInfo(~invalidPaths, :);
  pathMasks = pathMasks(~invalidPaths, :);
  numPaths = numPaths - sum(invalidPaths);
end

%--------------------------------------------------------------------------
% selectPath
%
%
%--------------------------------------------------------------------------
function selectedPathIndex = selectPath(paths, numPaths, pathInfo, numBpointLabels)
  % when finding the path with the highest average, one that begins with an 
  % endpoint and ends with an endpoint will always be higher than a path 
  % that continues on through the endpoint. because of this we see if there
  % are any valid paths that begin and end with endpoints first
  has2endpoints = false(numPaths, 1);
  for j = 1:numPaths
    curPath = paths(j, :);
    curPath = curPath(curPath > 0);
    endpoints = curPath > numBpointLabels;
    if endpoints(1) == 1 && endpoints(end) == 1
      has2endpoints(j) = true;
    end
  end
  % if there is at least one path beginning and ending with endpoints, pick
  % the one with the highest average dist values otherwise pick any path
  % with the highest average
  if sum(has2endpoints) > 0
    [maxDist, ~] = max(pathInfo(has2endpoints, 1));
    selectedPathIndex = find(pathInfo(:, 1) == maxDist);
  else
    [maxDist, selectedPathIndex] = max(pathInfo(:, 1));
  end
  
  % if more than one path is selceted, pick the one with a better fit
  if numel(selectedPathIndex) > 1
    [bestFit, ~] = max(pathInfo(selectedPathIndex, 2));
    selectedPathIndex = find(pathInfo(:, 2) == bestFit & pathInfo(:, 1) == maxDist);
  end
end