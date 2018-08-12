function [spine, bw_spine] = center_of_mass(image, rx, ry)
    
    image = image - min(image(:));
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

    end    
end