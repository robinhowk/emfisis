function [spines] = groupBranchpoints(spines)
% figure;i1 = subplot(2,1,1);imagesc(spines);colormap autumn;set(i1, 'ydir', 'normal');
    bpoints = bwmorph(spines, 'branchpoints');
    [bf, bt] = find(bpoints == 1);
    [labels, ~] = bwlabel(spines);
    d = 5;
    removed = [];
    for i = 1:numel(bf)
        % calculate distance between current branchpoint and all other
        % branch points
        dist = sqrt((bf(i) - bf).^2 + (bt(i) - bt).^2 );
        % select only those points within a minimum distance and not
        % current point
        n = find(dist < d)';
        numNeighbors = 0;
        tbar = 0;
        fbar = 0;
        for j = n
            if (labels(bf(i), bt(i)) == labels(bf(j), bt(j))) && ~ismember(j, removed)
                numNeighbors = numNeighbors + 1;
                tbar = tbar + bt(j);
                fbar = fbar + bf(j);
                spines(bf(j), bt(j)) = 0;
                removed = [removed, j];
            end
        end
        
        if numNeighbors > 0
            tbar = round(tbar / numNeighbors);
            fbar = round(fbar / numNeighbors);
            spines(fbar, tbar) = 1;
        end
    end
%     i2 = subplot(2,1,2);imagesc(spines);colormap autumn;set(i2, 'ydir', 'normal');
%     hold on;plot(bt, bf, 'k*');
end