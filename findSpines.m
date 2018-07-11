function [ spines ] = findSpines( ridges )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

dist = bwdist(~(ridges-min(ridges(:))));
dist(dist == 0) = NaN;
grad = imgradient(dist);
maxgrad = max(grad(:));
grad = grad ./ maxgrad;
grad(grad < .75) = 2;
grad(grad < 1) = 1;
grad = grad -1;
grad(isnan(grad)) = 0;
grad = bwmorph(grad, 'thin', Inf);
grad = bwmorph(grad, 'spur', 2);
grad = bwmorph(grad, 'clean');
spines = grad;
end

