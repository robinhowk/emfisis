function [spine, bw_spine] = center_of_mass(image, rx, ry)
    
    spine = zeros(size(image));
    bw_spine = zeros(size(image));
    
    max_x = size(image,2);
    max_y = size(image,1);
    
    [row, col] = find(image > 0);

    for index = 1:length(col)
        left = max(col(index) - rx, 1);
        right = min(col(index) + rx, max_x);
        top = min(row(index) + ry, max_y);
        bottom = max(row(index) - ry, 1);
        subimage = image(bottom:top, left:right);
        [ysub, xsub] = find(subimage > 0);
        ind = find(subimage > 0);
        total = sum(sum(subimage));
        xtotal = sum(xsub .* subimage(ind));
        ytotal = sum(ysub .* subimage(ind));
        xcenter = (1/total)*xtotal;
        ycenter = (1/total)*ytotal;
        xcenter = round(xcenter) + left - 1;
        ycenter = round(ycenter) + bottom - 1;

        spine(ycenter, xcenter) = image(ycenter, xcenter);
        if image(ycenter, xcenter) ~= min(min(image))
            bw_spine(ycenter, xcenter) = 1;
        end
        
%         figure;
%         i1 = subplot(2,1,1);
%         imagesc(spines);
%         colormap(i1, jet);
%         set(i1, 'YDir', 'normal');
%         i2 = subplot(2,1,2);
%         imagesc(bw_spines);
%         colormap(i2, gray);
%         set(i2, 'YDir', 'normal');
%         
%         pause;
%         close
    end    
%     figure;
%     i1 = subplot(3,1,1);
%     imagesc(image);
%     colormap(i1, jet);
%     set(i1, 'YDir', 'normal');
%     i2 = subplot(3,1,2);
%     imagesc(spine);
%     colormap(i2, jet);
%     set(i2, 'YDir', 'normal');
%     i3 = subplot(3,1,3);
%     imagesc(bw_spine);
%     colormap(i3, gray);
%     set(i3, 'YDir', 'normal');
end