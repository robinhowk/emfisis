function [ spec, fspec ] = trimSpect( spec, fspec, low, high)
%Trims spectrogram and frequency vector to given limits. If low and high
%are undefined, return original spectrogram and frequency vector
%   Detailed explanation goes here
    low = find(fspec > low, 1, 'first');
    low = low - 1;
    high = find(fspec > high, 1, 'first');
    
    low = min(max(1, low), numel(fspec));
    high = max(min(numel(fspec), high), 1);
    
    if low ~= high
        fspec = fspec(low:high);
        spec = spec(low:high, :);
    end
end

