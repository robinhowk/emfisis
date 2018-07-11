function [ spinesClean ] = removeNoise( spines )
%Removes pixels that are isolated in a 3x3 region
    mask = ones(size(spines));
    [numrows, numcols] = size(spines);

    % for 3x3 area of interest with 2 pixel border
    r = 3;
    borderMask = [1 1 1 1 1 1 1; 1 1 1 1 1 1 1; 1 1 0 0 0 1 1; 1 1 0 0 0 1 1; 1 1 0 0 0 1 1; 1 1 1 1 1 1 1; 1 1 1 1 1 1 1];

    for row = 2:numrows - 1
        for col = 2:numcols - 1
            left = col - r;
            right = col + r;
            bottom = row - r;
            top = row + r;
            border = borderMask;
            % correct for overhanging left or right edge
            if left == -1
                border = border(:, 3:end);
                left = 1;
            elseif left == 0
                border = border(:, 2:end);
                left = 1;
            elseif right == numcols + 2
                border = border(:, 1:end - 2);
                right = numcols;
            elseif right == numcols + 1
                border = border(:, 1:end - 1);
                right = numcols;
            end

            % correct for overhanging bottom or top edge
            if bottom == -1
                border = border(3:end, :);
                bottom = 1;
            elseif bottom == 0
                border = border(2:end, :);
                bottom = 1;
            elseif top == numrows + 2
                border = border(1:end - 2, :);
                top = numrows;
            elseif top == numrows + 1
                border = border(1:end - 1, :);
                top = numrows;
            end

            subimage = spines(bottom:top, left:right);
            border = subimage .* border;
            middle = subimage .* double(~border);

            if sum(border(:)) == 0 && sum(middle(:)) > 0
                mask(bottom:top, left:right) = 0;
            end
        end
    end
    spinesClean = spines .* mask;
end

