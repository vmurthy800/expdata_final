function [ds, bs, time] = exp_imgtest(im, model, thresh, removal, time)
% used to test whether removal of parts affects detections / speed
% Wrapper around gdetect.m that computes detections in an image.
%   [ds, bs, trees] = imgdetect(im, model, thresh)
%
% Return values (see gdetect.m)
%
% Arguments
%   im        Input image
%   model     Model to use for detection
%   thresh    Detection threshold (scores must be > thresh)
if nargin == 4
    time = zeros(34,1);
end

im = color(im);
pyra = featpyramid(im, model);
[model, time] = exp_gdetectdp(pyra, model, removal, time);
[ds, bs, trees] = gdetect_parse(model, pyra, thresh, inf);